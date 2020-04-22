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

    def validate_target!
      http_response = http_client.get("/api/v1/info")
      content = JSON.parse(http_response.body)
      unless content["external_url"] == @target_url
        raise TargetError.new("Target does not match external URL of Concourse instance!")
      end

      true
    rescue Faraday::Error
      raise FlyError.new("Unable to reach target!")
    rescue JSON::ParserError
      raise ResponseError.new("Unable to understand response!")
    end

    def users
      http_response = http_client.get("/api/v1/users") { |request|
        request.headers["Content-Type"] = "application/json"
        request.headers["Authorization"] = auth_header
      }
      raise AuthError.new("Authentication failure!") unless http_response.status < 300

      JSON.parse(http_response.body)
    rescue Faraday::Error
      raise FlyError.new("Unable to reach target!")
    rescue JSON::ParserError
      raise ResponseError.new("Unable to understand response!")
    end

    private

    def auth_header
      @auth_header ||= case @auth_type
                       when :flyrc
                         flyrc_content = YAML.safe_load(File.read("~/.flyrc"))
                         token = flyrc_content["targets"][@flyrc_target]["token"]
                         "#{token["type"]} #{token["value"]}"
                       else
                         ""
      end
    rescue
      ""
    end

    def http_client
      @client ||= Faraday.new @target_url
    end
  end
end
