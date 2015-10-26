class ApiBlueprint::Compile::Compile
  attr_reader :source, :target, :partials

  def initialize(options)
    @source = options[:source]
    @target = options[:target]
    @logger = options[:logger]

    @partials = []
  end

  def compile
    layout = load_layout
    insert_content(layout)
    insert_stylesheets(layout)

    layout_html = layout.to_html
    insert_javascripts(layout_html)

    layout_doc = load_document(layout_html)
    insert_title(layout_doc)
    insert_host(layout_doc)
    insert_copyright(layout_doc)

    write_html(layout_doc.to_html)
  end

  private

  def load_layout
    log "Rendering '#{@source}' within the blueprint layout..."

    Nokogiri::HTML(File.read(ApiBlueprint::Compile::Storage.index_html))
  end

  def load_document(html)
    Nokogiri::HTML(html)
  end

  def write_html(layout_html)
    return unless @target

    File.write(@target, layout_html)

    log "Wrote #{@title_text || "document"} into '#{@target}'"
  end

  def insert_content(layout)
    container = layout.at_css("#blueprint-document")

    if container
      content = render_markdown(@source)
      content = prepend_toc(content)

      container.add_child(content)
    end

    log " - compiled #{(container/'h1').length} chapter(s)"
  end

  def insert_stylesheets(layout)
    style = layout.at_css("#blueprint-style")

    if style
      text = ApiBlueprint::Compile::Storage.stylesheets.collect do |file|
        Sass::Engine.new(File.read(file), :syntax => :scss, :style => :compressed).render
      end.join("\n\n")

      style.add_child(text)

      log " - compiled #{ApiBlueprint::Compile::Storage.stylesheets.count} stylesheet(s)"
    end
  end

  def insert_javascripts(layout_html)
    return unless layout_html.include?('<script id="blueprint-script"></script>');

    text = ApiBlueprint::Compile::Storage.javascripts.collect do |file|
      Uglifier.compile(File.read(file))
    end.join("\n\n")

    layout_html.sub!('<script id="blueprint-script"></script>',
      '<script id="blueprint-script">' + text + '</script>')

    log " - compiled #{ApiBlueprint::Compile::Storage.stylesheets.count} javascript(s)"
  end

  def insert_title(doc)
    title_node = doc.at('p:contains("Title: ")')

    if title_node
      @title_text = title_node.text.strip.sub("Title: ", '')
      title_tag   = doc.at('title')

      title_node['id'] = 'title'
      title_node.content = @title_text

      if title_tag
        title_tag.content = @title_text
      end
    end
  end

  def insert_host(doc)
    host_node = doc.at('p:contains("Host: ")')

    if host_node
      @host_text = host_node.text.strip.sub("Host: ", '')

      host_node['id'] = 'host'
      host_node.content = @host_text
    end
  end

  def insert_copyright(doc)
    copyright_node = doc.at('p:contains("Copyright: ")')

    if copyright_node
      copyright_text = copyright_node.text.strip.sub("Copyright: ", '')
      copyright_text = "© #{Date.today.year} #{copyright_text}"
      copyright_tag  = doc.at('.copyright')

      copyright_node['id'] = 'copyright'
      copyright_node.content = copyright_text

      if copyright_tag
        copyright_tag.content = copyright_text
      end
    end
  end

  def render_markdown(input_file)
    markdown  = Redcarpet::Markdown.new(Redcarpet::Render::HTML, :tables => true, :no_intra_emphasis => true)
    content   = markdown.render(File.read(input_file))
    doc       = Nokogiri::HTML(content)
    requires  = (doc/'a:contains("require:")')

    requires.each do |require_link|
      file = require_link['href'].split(':').last
      file = input_file.split('/')[0..-2].join('/') + '/' + file + '.md'
      file = render_markdown(file)

      require_link.after(file)
      require_link.remove
    end

    partials << input_file unless partials.include?(input_file)

    doc.to_html
  end

  def prepend_toc(doc)
    doc = Nokogiri::HTML(doc)
    headers = []

    (doc/"h1").each_with_index do |header, header_index|
      subheaders = []
      header['id'] = header.text.sub('Resource: ', '').parameterize
      headers << { :title => header.text.sub('Resource: ', ''), :id => header['id'], :subheaders => subheaders }

      next_all(header, :where => "h2", :until => 'h1').each_with_index do |action_header, action_index|
        action_header['id'] = header['id'] + "-" + action_header.text.sub('Action: ', '').parameterize
        subheaders << { :title => action_header.text.sub('Action: ', ''), :id => action_header['id'] }
      end
    end

    toc = "<h1>Table Of Contents</h1>"
    toc += "<ul>"

    headers.collect do |header|
      toc += "<li>"
      toc += "<a href='##{header[:id]}'>#{header[:title]}</a>"

      if header[:subheaders].any?
        toc += "<ul>"
        header[:subheaders].each do |subheader|
          toc += "<li><a href='##{subheader[:id]}'>#{subheader[:title]}</a></li>"
        end
        toc += "</ul>"
      end

      toc += '</li>'
    end

    toc += "</ul>"

    doc.at('h1').before(toc)

    doc.to_html
  end

  def next_all(element, options = {})
    doc = element.document

    selector = options[:where]
    rejector = options[:until]
    results  = Nokogiri::XML::NodeSet.new(doc)
    element  = element.next_element

    while element
      set = Nokogiri::XML::NodeSet.new(doc, [element])

      if rejector && (set/rejector).any?
        break
      elsif ! selector || (set/selector).any?
        results << element
      end

      element = element.next_element
    end

    return results
  end

  def log(message)
    if @logger.to_s == 'stdout'
      puts message
    end
  end
end
