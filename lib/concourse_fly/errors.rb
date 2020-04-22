module ConcourseFly
  class FlyError < StandardError; end
  class ResponseError < FlyError; end
  class TargetError < FlyError; end
  class AuthError < FlyError; end
end
