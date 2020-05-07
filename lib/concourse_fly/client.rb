require "base64"
require "date"
require "faraday"
require "ostruct"
require "json"

module ConcourseFly
  class Client
    attr_accessor :auth_type, :auth_data
    attr_accessor :target_url

    def initialize(target_url)
      @target_url = target_url
      yield self if block_given?
    end

    def version
      @version ||= "v#{self[:get_info]["version"]}"
    end

    def [](endpoint_sym)
      options = OpenStruct.new
      yield options if block_given?

      endpoint = endpoint_lookup(endpoint_sym)
      raise EndpointError.new("Unable to automagically resolve #{endpoint_sym} to a valid endpoint") if endpoint.nil?

      response = connection.run_request(
        endpoint.http_method.downcase.to_sym,
        endpoint.interpolate(options.path_vars),
        options.body,
        {"Authorization" => generate_auth}.merge(options.headers || {})
      )
      raise FlyError.new("Concourse was unable to respond properly -- #{response.status}: #{response.body}") if (500..599).cover?(response.status)

      case response.status
      when 204
        true
      when 401, 403
        @auth_header = nil
        raise AuthError.new("Authentication failure!")
      when 404
        false
      else
        JSON.parse(response.body)
      end
    rescue Faraday::Error
      raise FlyError.new("Unable to reach target!")
    rescue JSON::ParserError
      raise ResponseError.new("Unable to understand response!", response)
    end

    # private

    def generate_auth
      case @auth_type
      when :raw
        @auth_data[:raw]
      when :flyrc
        @auth_header ||= token_from_flyrc
      when :local
        if @token_expiry && DateTime.now < @token_expiry
          @auth_header
        else
          @auth_header = token_from_basic_auth
        end
      end
    end

    def token_from_flyrc
      flyrc_content = YAML.safe_load(File.read(File.join(Dir.home + "/.flyrc")))
      token = flyrc_content["targets"][@auth_data[:flyrc_target]]["token"]
      "#{token["type"]} #{token["value"]}"
    end

    def token_from_basic_auth
      content = {
        username: @auth_data[:username],
        password: @auth_data[:password],
        grant_type: "password",
        scope: "openid profile email federated:id groups",
      }

      response = connection.post("sky/token") { |req|
        req.headers["Authorization"] = "Basic #{Base64.encode64("fly:Zmx5").chomp}"
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        req.body = URI.encode_www_form(content)
      }

      token_attributes = JSON.parse(response.body)
      @token_expiry = DateTime.parse(token_attributes["expiry"])
      "#{token_attributes["token_type"]} #{token_attributes["access_token"]}"
    end

    def connection
      @faraday_connection ||= Faraday.new(@target_url) { |c|
        c.headers["Content-Type"] = "application/json"
      }
    end

    def endpoint_lookup(endpoint_sym)
      @endpoints ||= EndpointImporter.new(@version).fetch.map { |endpoint|
        [endpoint["name"].gsub(/(.)([A-Z])/, '\1_\2').downcase.to_sym, endpoint]
      }.to_h
      @endpoints[endpoint_sym]
    end
  end
end
