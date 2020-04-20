require "faraday"
require "yaml"

module ConcourseFly
  class EndpointResolver
    def initialize(version)
      @version = version
    end

    def fetch(check_cache = true)
      path_to_cached = File.expand_path("../endpoints/#{@version}.yml", __FILE__)
      if check_cache && File.exist?(path_to_cached)
        YAML.safe_load(File.read(path_to_cached))
      else
        fetch_from_source
      end
    end

    private

    def fetch_from_source
      endpoints = {}
      response = Faraday.get "https://raw.githubusercontent.com/concourse/concourse/#{@version}/atc/routes.go"
      response.body.scan(/\{Path\: .*, Method\: .*, Name\: .*\}/).each do |endpoint|
        data = YAML.safe_load(endpoint).transform_keys(&:downcase)
        endpoints[data["name"]] = data.reject { |k, v| k == "name" }
      end

      endpoints
    end
  end
end
