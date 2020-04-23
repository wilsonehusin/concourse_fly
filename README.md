# ConcourseFly

Interact with Concourse instance from your Ruby code without `fly` binary!

## Installation

Add this line to your application's Gemfile:

```ruby
gem "concourse_fly"
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install concourse_fly

## Usage

```ruby
require "concourse_fly"

fly = ConcourseFly::Client.new("https://ci-dev.net") do |client|
  client.auth_type = :raw
  client.auth_data = {raw: "Bearer adeAOEITNogiim..."}
end

fly[:get_info]  #=> { "version" => "5.8.0", "worker_version" => "2.2", "external_url" => "https://ci-dev.net"
```

### Authorization

#### Currently Supported

```ruby
# Provide your own HTTP Authorization header
ConcourseFly::Client.new("https://ci-dev.net") do |client|
  client.auth_type = :raw
  client.auth_data = {raw: "Bearer adeAOEITNogiim..."}
end

# Let the client parse it from ~/.flyrc
ConcourseFly::Client.new("https://ci-dev.net") do |client|
  client.auth_type = :flyrc
  client.auth_data = {flyrc_target: "some-target"}
end
```

#### Coming soon

```ruby
# Providing local user
ConcourseFly::Client.new("https://ci-dev.net") do |client|
  client.auth_type = :local
  client.auth_data = {username: "service-account-user", password: "service-account-password"}
end

# Browser login
ConcourseFly::Client.new("https://ci-dev.net") do |client|
  client.auth_type = :browser
end
```

### API endpoints
Concourse [doesn't have official REST API support yet](https://github.com/concourse/concourse/issues/1122).
However, the available endpoints can be viewed [in their source code](https://github.com/concourse/concourse/blob/master/atc/routes.go).

This gem has made it _somewhat_ more Ruby-like and Ruby-friendly by translating the `CamelCase` endpoint names to `:snake_case`.
At the time of this writing, the client only support [`v5.8.0` endpoints](https://github.com/concourse/concourse/blob/v5.8.0/atc/routes.go),
though the routes rarely change between releases.

```ruby
fly = ConcourseFly::Client.new("https://ci-dev.net") do |client|
  client.auth_type = :raw
  client.auth_data = {raw: "Bearer adeAOEITNogiim..."}
end

fly[:rename_pipeline] do |options|   # :rename_pipeline => /api/v1/:team_name/pipelines/:old_pipeline/rename
  options.path_vars = {team_name: "all-star", pipeline_name: "old-pipeline"}   # substitutes the above 🔼
  options.body = '{"name": "new-pipeline"}'   # no official documentation yet for this 😬
end   #=> true  (HTTP 204: No Content)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

This project follows [Semantic Versioning](https://semver.org/), thus `v1.0.0` will not be released until [the official REST API support / documentation is out](https://github.com/concourse/concourse/issues/1122).

Bug reports and pull requests are welcome on [GitHub](https://github.com/wilsonehusin/concourse_fly). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/wilsonehusin/concourse_fly/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ConcourseFly project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/concourse_fly/blob/master/CODE_OF_CONDUCT.md).
