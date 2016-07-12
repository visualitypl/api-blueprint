class ApiBlueprint::Collect::Preprocessor
  attr_reader :naming

  def initialize(options = {})
    @naming = options[:naming]
  end

  def resource_name(request)
    request['route']['controller'].singularize.split('_').map do |word|
      word.camelize
    end.join(' ').pluralize
  end

  def action_name(request)
    model = resource_name(request)
    prefix = %w{a e i o u}.include?(model[0].downcase) ? 'an' : 'a'

    if (n = naming) && (n = n[model.underscore]) && (n = n[request['route']['action']])
      return n
    end

    case request['route']['action']
    when 'index'
      "List all #{model.pluralize}"
    when 'show'
      "Retrieve single #{model.singularize}"
    when 'update'
      "Update an existing #{model.singularize}"
    when 'destroy'
      "Remove an existing #{model.singularize}"
    else
      request['route']['action'].humanize + " #{prefix} #{model.singularize}"
    end

    # request['route']['action'].humanize
  end

  def preprocess(info)
    any_request = info[:requests].first

    info[:path]   = any_request['request']['path'].sub(/\d+$/, '{id}')
    info[:method] = any_request['request']['method']
    info[:params] = collect_request_params(info[:requests])

    info[:requests].each do |request|
      preprocess_request(request)
    end

    unique_requests = []
    info[:requests].each do |request|
      unique_requests.reject! do |existing_request|
        existing_request[:title] == request[:title]
      end

      unique_requests.push(request)
    end
    info[:requests] = unique_requests
  end

  private

  def collect_request_params(requests)
    merged_params = {}
    requests.sort_by do |request|
      -request['response']['status']
    end.each do |request|
      merged_params.deep_merge!(request['request']['params'])
    end

    merged_params = Hash[merged_params.select { |k,v| ! v.is_a?(Hash) || v.any? }]

    collect_merged_params(merged_params)
  end

  def collect_merged_params(merged_params)
    params = {}
    merged_params.each do |param, value|
      if value.is_a?(Hash)
        if value['original_filename'].present?
          params[param] = {
            :type     => 'file',
            :example  => value['original_filename']
          }
        else
          params[param] = {
            :type   => 'nested',
            :params => collect_merged_params(value)
          }
        end
      elsif value.is_a?(Array)
        if value.first.is_a?(Hash)
          items = value.collect { |i| collect_merged_params(i) }
          params[param] = {
            :type   => 'array',
            :params => items.inject(&:merge)
          }

        else
          params[param] = {
            :type   => 'string',
            :params => value
          }
        end
      else
        if value == true || value == false
          type = 'boolean'
          value = value ? 'true' : 'false'
        elsif value.is_a?(ActionDispatch::Http::UploadedFile)
          type = 'file'
          value = value.original_filename
        elsif value.to_i.to_s == value
          type = 'integer'
        elsif value.to_f.to_s == value
          type = 'decimal'
          value = value.to_f.round(6).to_s
        else
          type = 'string'
        end

        params[param] = {
          :type    => type,
          :example => value
        }
      end
    end

    params
  end

  def clear_files(params)
    p = {}

    params.each do |key, value|
      if value.is_a?(Hash)
        if value['original_filename'].present?
          p[key] = "file <#{value['original_filename']}>"
        else
          p[key] = clear_files(value)
        end
      else
        p[key] = value
      end
    end

    p
  end

  def preprocess_request(request)
    if request['request']['params'].present?
      params = Hash[request['request']['params'].select { |k, v| ! v.is_a?(Hash) || v.any?}]
      params = clear_files(params)
      request[:params] = JSON.pretty_generate(params) if params.any?
    end

    if request['response']['body'].is_a?(Hash)
      request[:body] = JSON.pretty_generate(request['response']['body'])
    else
      request[:body] = request['response']['body']
    end

    request[:request_headers] = preprocess_headers({
      # 'Accept' => request['request']['accept'],
      'Content-Type' => request['request']['content_type']
    }.merge(request['request']['headers']).select { |_, v| v.present? })

    request[:response_headers] = preprocess_headers({
      'Status' => request['response']['status'],
      'Content-Type' => request['response']['content_type']
    }.merge(request['response']['headers'].slice(
      'access-token', 'client', 'expiry', 'uid'
    )))

    request[:title] = request['spec']['title_parts'][1..-1].join(' ')
    request[:title] = request[:title][0].upcase + request[:title][1..-1]
  end

  def preprocess_headers(headers)
    header_key_length = headers.collect do |key, _|
      key.length
    end.max

    headers.collect do |key, value|
      "#{key.split("_").map(&:camelize).join("-")}:#{' ' * (header_key_length - key.length)} #{value}"
    end.join("\n")
  end
end
