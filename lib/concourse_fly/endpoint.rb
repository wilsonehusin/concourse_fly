require "faraday"
require "yaml"

module ConcourseFly
  Endpoint = Struct.new(:name, :method, :path)

  class EndpointImporter
    def initialize(version)
      @version = version
    end

    def fetch(check_cache = true)
      path_to_cached = File.expand_path("endpoints/#{@version}.yml", __dir__)
      raw_endpoints = if check_cache && File.exist?(path_to_cached)
        YAML.safe_load(File.read(path_to_cached))
      else
        fetch_from_source
      end
      raw_endpoints.map { |data| Endpoint.new data["name"], data["method"], data["path"] }
    end

    private

    def fetch_from_source
      response = Faraday.get "https://raw.githubusercontent.com/concourse/concourse/#{@version}/atc/routes.go"
      response.body.scan(/\{Path\: .*, Method\: .*, Name\: .*\}/).map do |endpoint|
        YAML.safe_load(endpoint).transform_keys(&:downcase)
      end
    end
  end
end
