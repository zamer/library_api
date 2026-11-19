source "https://rubygems.org"

ruby "3.3.6"

gem "rails", "~> 8.1.4", ">= 8.1.4.1"
gem "pg", "~> 1.5"
gem "puma", "~> 6.4"
gem "jbuilder"
gem "tzinfo-data", platforms: %i[windows jruby]
gem "bootsnap", require: false
gem "redis", "~> 6.0"
gem "sidekiq", "~> 7.2"
gem "sidekiq-cron", "~> 1.12"
gem "kaminari", ">= 1.3.3"

group :development, :test do
  gem "debug", platforms: %i[mri windows]
  gem "rspec-rails", "~> 6.1"
  gem "factory_bot_rails"
  gem "rubocop-rails-omakase", require: false
  gem "faker"
  gem "shoulda-matchers", "~> 6.0"
  gem "database_cleaner-active_record"
end

group :development do
  gem "letter_opener"
  gem "letter_opener_web", "~> 2.0"
  gem "web-console"
end

group :test do
  gem "simplecov", require: false
  gem "simplecov-lcov", require: false
  gem "rspec"
  gem "rspec_junit_formatter", require: false
end
