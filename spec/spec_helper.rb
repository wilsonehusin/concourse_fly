require "bundler/setup"
require "concourse_fly"
require "webmock/rspec"

RSpec.configure do |config|
  config.example_status_persistence_file_path = "/tmp/concourse_fly.rspec"

  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.filter_run_when_matching :focus unless ENV["RSPEC_FOCUS"] == "0"
end
