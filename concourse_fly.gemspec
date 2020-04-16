require_relative "lib/concourse_fly/version"

Gem::Specification.new do |spec|
  spec.name = "concourse_fly"
  spec.version = ConcourseFly::VERSION
  spec.authors = ["Wilson E. Husin"]
  spec.email = ["wilsonehusin@gmail.com"]

  spec.summary = "Ruby client to interact with Concourse instance through HTTP"
  spec.description = "Avoid invoking Fly binaries in your Ruby application"
  spec.homepage = "https://github.com/wilsonehusin/concourse_fly"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage + "/tree/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "faraday", "~> 1.0"
end
