module ConcourseFly
  class Client
    attr_accessor :target

    def initialize(target)
      @target = target
    end

    def validate_target!
      http_response = http_client.get("/api/v1/info")
      content = JSON.parse(http_response.body)
      unless content["external_url"] == @target
        raise TargetError.new("Target does not match external URL of Concourse instance!")
      end

      true
    rescue Faraday::Error
      raise FlyError.new("Unable to reach target")
    rescue JSON::ParserError
      raise ResponseError.new("Unable to understand response")
    end

    private

    def http_client
      @client ||= Faraday.new @target
    end
  end
end
