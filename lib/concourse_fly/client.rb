require "faraday"
require "json"

module ConcourseFly
  class Client
    attr_accessor :auth_type
    attr_accessor :flyrc_target
    attr_accessor :target_url

    def initialize(target_url)
      @target_url = target_url
      yield self if block_given?
    end

    def version
      @version ||= "v#{self[:get_info]["version"]}"
    end

    def users
      self[:list_active_users_since]
    end

    def [](endpoint_sym)
      endpoint = endpoint_lookup(endpoint_sym)
      response = connection.run_request(endpoint.http_method.downcase.to_sym, endpoint.path, nil, nil)
      raise AuthError.new("Authentication failure!") if [401, 403].include?(response.status)
      raise FlyError.new("Concourse was unable to respond properly -- #{response.status}: #{response.body}") if (500..599).cover?(response.status)

      JSON.parse(response.body)
    rescue Faraday::Error
      raise FlyError.new("Unable to reach target!")
    rescue JSON::ParserError
      raise ResponseError.new("Unable to understand response!")
    end

    # private

    def auth_header
      @auth_header ||= case @auth_type
                       when :flyrc
                         flyrc_content = YAML.safe_load(File.read(File.join(Dir.home + "/.flyrc")))
                         token = flyrc_content["targets"][@flyrc_target]["token"]
                         "#{token["type"]} #{token["value"]}"
                       else
                         ""
      end
    rescue
      ""
    end

    def connection
      @faraday_connection ||= Faraday.new(@target_url) { |c|
        c.headers["Authorization"] = auth_header
        c.headers["Content-Type"] = "application/json"
      }
    end

    def endpoint_lookup(endpoint_sym)
      @endpoints ||= EndpointImporter.new(@version).fetch.map { |endpoint|
        [endpoint["name"].gsub(/(.)([A-Z])/, '\1_\2').downcase.to_sym, endpoint]
      }.to_h
      @endpoints.fetch(endpoint_sym)
    end
  end
end
