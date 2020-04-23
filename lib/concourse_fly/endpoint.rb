require "faraday"
require "yaml"

module ConcourseFly
  class Endpoint < Struct.new(:name, :http_method, :path)
    def interpolate(vars)
      path.gsub(/:([\w_]+)/) { |match| vars[match.delete(":").to_sym] }
    end
  end

  class EndpointImporter
    def initialize(version)
      @version = version || "v5.8.0"
    end

    def fetch(check_cache = true)
      path_to_cached = File.expand_path("endpoints/#{@version}.yml", __dir__)
      raw_endpoints = if check_cache && File.exist?(path_to_cached)
        YAML.safe_load(File.read(path_to_cached))
      else
        fetch_from_source
      end

      # YAML archive has it as "http_method" and parsed Go code has it as "method"
      # I am hesitant to use "method" as it's an actual Ruby method, dangerous when loaded to Endpoint class
      raw_endpoints.map { |data| Endpoint.new data["name"], data["http_method"] || data["method"], data["path"] }
    end

    private

    def fetch_from_source
      response = Faraday.get "https://raw.githubusercontent.com/concourse/concourse/#{@version}/atc/routes.go"
      response.body.scan(/\{Path\: .*, Method\: .*, Name\: .*\}/).map do |endpoint|
        # Treating JSON as YAML
        YAML.safe_load(endpoint).transform_keys(&:downcase)
      end
    end
  end
end
