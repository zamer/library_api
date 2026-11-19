# spec/spec_helper.rb
require "simplecov"
require "simplecov-lcov"

ENV["RAILS_ENV"] = "test"

SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true
SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::LcovFormatter
])

SimpleCov.start "rails" do
  skip "/spec/"
  skip "/config/"
  skip "/db/"
  skip "/vendor/"
  skip "/bin/"
  skip "/app/mailers/application_mailer.rb"

  minimum_coverage 90

  SimpleCov.cover "{app,lib}/**/*.rb"
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.order = :random
  Kernel.srand config.seed
end
