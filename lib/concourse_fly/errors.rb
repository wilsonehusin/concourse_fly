module ConcourseFly
  class FlyError < StandardError; end

  # Unable to understand response from Concourse
  class ResponseError < FlyError
    def initialize(message, faraday_response)
      super("#{message} -- #{faraday_response.status}: #{faraday_response.body}")
    end
  end

  # HTTP 4xx
  class ClientError < FlyError; end
  class AuthError < ClientError; end

  # HTTP 5xx
  class ConcourseError < FlyError; end
end
