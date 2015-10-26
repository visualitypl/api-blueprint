module ApiBlueprint::Collect::ControllerHook
  def self.included(base)
    return unless Rails.env.test?

    base.around_filter :dump_blueprint_around
  end

  class Parser
    attr_reader :input

    def initialize(input)
      @input = input
    end

    def method
      input.method.to_s.upcase
    end

    def params
      JSON.parse(input.params.reject do |k,_|
        ['action', 'controller'].include?(k)
      end.to_json)
    end

    def headers
      Hash[input.headers.env.select do |k, v|
        (k.start_with?("HTTP_X_") || k == 'ACCEPT') && v
      end.map do |k, v|
        [human_header_key(k), v]
      end]
    end

    def body
      if input.content_type == 'application/json'
        if input.body != 'null'
          JSON.parse(input.body)
        else
          ""
        end
      else
        input.body
      end
    end

    private

    def human_header_key(key)
      key.sub("HTTP_", '').split("_").map do |x|
        x.downcase
      end.join("_")
    end
  end

  def dump_blueprint_around
    yield
  ensure
    dump_blueprint
  end

  def dump_blueprint
    file       = ApiBlueprint::Collect::Storage.request_dump
    in_parser  = Parser.new(request)
    out_parser = Parser.new(response)

    data = {
      'request' => {
        'path'         => request.path,
        'method'       => in_parser.method,
        'params'       => in_parser.params,
        'headers'      => in_parser.headers,
        'content_type' => request.content_type,
        'accept'       => request.accept
      },
      'response' => {
        'status'       => response.status,
        'content_type' => response.content_type,
        'body'         => out_parser.body
      },
      'route' => {
        'controller'   => controller_name,
        'action'       => action_name
      }
    }

    spec = ApiBlueprint::Collect::Storage.spec_dump
    if File.exists?(spec)
      data['spec'] = YAML::load_file(spec)
    end

    File.write(file, data.to_yaml)
  end
end
