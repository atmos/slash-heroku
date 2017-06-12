require "webmock/rspec"
require "coal_car/spec_helpers"

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.include(WebMock::API)
  config.include(CoalCar::SpecHelpers)

  config.before(:all) do
    stub_zipkin!
  end

  config.before(:each) do
    WebMock.reset!
    WebMock.disable_net_connect!
    stub_request(:post, "https://zipkin-staging.heroku.tools/api/v1/spans")
  end
end
