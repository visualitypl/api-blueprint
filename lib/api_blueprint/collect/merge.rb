class ApiBlueprint::Collect::Merge
  attr_reader :target, :renderer, :preprocessor

  def initialize(options)
    @target       = options[:target]
    @logger       = options[:logger]

    @renderer     = ApiBlueprint::Collect::Renderer.new
    @preprocessor = ApiBlueprint::Collect::Preprocessor.new(
      :naming => options[:naming])
  end

  def merge
    log "Merging into '#{@target}'..."

    File.write(target, body_content)
  end

  def update_examples
    log "Updating examples in '#{@target}'..."
    log ''

    library.each do |resource, actions|
      actions.each do |action, info|
        log "#{resource}: #{action}\n\n"

        info[:requests].each do |request|
          insert = find_insertion_point(resource, action, request[:title])

          if insert && insert[1] == nil
            insert_example_block(insert, request)
          elsif insert
            replace_example_block(insert, request)
          else
            log "no insertion point: #{request_title request}", :error
          end
        end

        log ''
      end
    end
  end

  def clear_examples
    log "Clearing examples in '#{@target}'...\n\n"

    library.each do |resource, actions|
      actions.each do |action, info|
        clear = find_clear_point(resource, action)

        log "#{resource}: #{action}\n\n"

        if clear
          clear_example_block(clear)
        else
          log "no clear point", :error
        end

        log ''
      end
    end
  end

  private

  # library loading

  def library
    @library ||= begin
      resources = {}

      requests.each do |request|
        resource = (resources[preprocessor.resource_name(request)] ||= {})
        action = (resource[preprocessor.action_name(request)] ||= {
          :requests => []
        })

        action[:requests] << request
      end

      resources.each do |resource, actions|
        actions.each do |action, info|
          preprocessor.preprocess(info)
        end
      end

      resources = resources.sort

      resources
    end
  end

  def requests
    ApiBlueprint::Collect::Storage.request_dumps.collect do |file|
      YAML::load_file(file)
    end.uniq
  end

  # content assembly

  def body_content
    library.collect do |resource, actions|
      text = renderer.resource_header(resource)

      text += actions.collect do |action, info|
        text = renderer.action_header(action)

        text += renderer.description_header
        text += renderer.signature(info[:path], info[:method])
        text += renderer.parameter_table(info[:params])
        text += examples(info)
      end.join
    end.join
  end

  def examples(info)
    text = renderer.examples_header

    text += info[:requests].collect do |request|
      example(request)
    end.join
  end

  def example(request)
    text = renderer.example_header(request[:title])

    if request[:request_headers].present?
      text += renderer.example_subheader(:request_headers) +
      renderer.code_block(request[:request_headers])
    end

    if request[:params]
      text += renderer.example_subheader(:request_params) +
      renderer.code_block(request[:params])
    end

    text += renderer.example_subheader(:response_headers) +
      renderer.code_block(request[:response_headers]) +
      renderer.example_subheader(:response_body) +
      renderer.code_block(request[:body])
  end

  # example updating

  def find_insertion_point(resource, action, example)
    @partial_map = build_partial_map(@target)

    resource = find_chapter(1, "Resource: #{resource}")
    return nil unless resource

    action   = find_chapter(2, "Action: #{action}", resource)
    return nil unless action

    examples = find_chapter(3, "Examples:", action)
    return nil unless examples

    example  = find_chapter(4, "Example: #{example}", examples)

    if example
      example
    else
      [examples[1], nil]
    end
  end

  def find_clear_point(resource, action)
    @partial_map = build_partial_map(@target)

    resource = find_chapter(1, "Resource: #{resource}")
    return nil unless resource

    action   = find_chapter(2, "Action: #{action}", resource)
    return nil unless action

    examples = find_chapter(3, "Examples:", action)
    return nil unless examples

    [examples[0] + 2, examples[1]]
  end

  def find_chapter(level, title, constraints = nil)
    from = constraints ? constraints[0] : 0
    to   = constraints ? constraints[1] : @partial_map.length - 1

    point = []

    @partial_map[from..to].each_with_index do |line, index|
      map_index = from + index

      if line[0].strip == (('#' * level) + ' ' + title)
        point[0] = map_index
      elsif point[0].present? && line[0].match(/^\#{1,#{level}}\s/)
        point[1] = map_index - 1

        break
      end
    end

    if point[0]
      point[1] ||= to

      point
    else
      nil
    end
  end

  def insert_example_block(insert, request)
    insert_map = @partial_map[insert[0]]

    file = insert_map[1]
    at   = insert_map[2]

    log "#{file} @ #{at}: #{request_title request}", :add

    e = example(request).split("\n").map { |l| l + "\n" }

    lines = File.readlines(file)
    if lines[at].present?
      lines.insert(at + 1, "\n")
      at += 1
    end
    if lines[at + 1].present?
      lines.insert(at + 1, "\n")
    end
    lines = lines[0..at] + e + lines[at + 1..-1]

    File.write(file, lines.join(''))
  end

  def replace_example_block(insert, request)
    from_map = @partial_map[insert[0]]
    to_map   = @partial_map[insert[1]]

    unless from_map[1] == to_map[1]
      return log("[!] multi-file range: #{request_title request}")
    end

    file = from_map[1]
    from = from_map[2] - 1
    to   = to_map[2] + 1

    log "#{file} @ #{from}-#{to}: #{request_title request}", :modify

    e = example(request).split("\n").map { |l| l + "\n" }

    lines = File.readlines(file)
    if lines[to].present?
      lines.insert(to, "\n")
    end
    lines = lines[0..from] + e + lines[to..-1]

    File.write(file, lines.join(''))
  end

  def clear_example_block(clear)
    from_map = @partial_map[clear[0]]
    to_map   = @partial_map[clear[1]]

    unless from_map and to_map
      return log('wrong mapping', :error)
    end

    unless from_map[1] == to_map[1]
      return log("multi-file range", :error)
    end

    file = from_map[1]
    from = from_map[2] - 1
    to   = to_map[2] + 1

    lines = File.readlines(file)
    if lines[from].blank? && lines[to].blank?
      to += 1
    end

    log "#{file} @ #{from}-#{to}", :remove

    final_lines = lines[0..from]
    final_lines += lines[to..-1] if lines[to..-1]

    File.write(file, final_lines.join(''))
  end

  def build_partial_map(file)
    lines = File.readlines(file)
    map = []

    lines.each_with_index do |line, index|
      if line.start_with?("<require:")
        filename = line.split('<require:')[1].split('>')[0] + '.md'
        path = file.split('/')[0..-2].join('/')

        map += build_partial_map(path + '/' + filename)
      else
        map << [line, file, index]
      end
    end

    map
  end

  def request_title(request)
    limit = 60
    title = request[:title].strip

    if title.length < limit + 2
      title
    else
      title[0..limit] + '(...)'
    end
  end

  # other

  def log(message, kind = nil)
    if @logger.to_s == 'stdout'
      message = case kind.to_s
      when 'error'
        (' ! ' + message).colorize(:red)
      when 'add'
        (' + ' + message).colorize(:green)
      when 'modify'
        (' * ' + message).colorize(:magenta)
      when 'remove'
        (' - ' + message).colorize(:cyan)
      else
        message
      end

      puts message
    end
  end
end
