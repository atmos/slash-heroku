ruby "2.3.1"

source "https://rubygems.org"

gem "actionpack", ">= 5.0.0.1", "< 5.1"
gem "actionview", ">= 5.0.0.1", "< 5.1"
gem "activejob", ">= 5.0.0.1", "< 5.1"
gem "activemodel", ">= 5.0.0.1", "< 5.1"
gem "activerecord", ">= 5.0.0.1", "< 5.1"
gem "activesupport", ">= 5.0.0.1", "< 5.1"
gem "addressable"
gem "bundler", ">= 1.3.0", "< 2.0"
gem "coal_car", "~> 0.2"
gem "coffee-rails", "~> 4.1.0"
gem "compass-rails"
gem "escobar", "0.3.8"
gem "jbuilder", "~> 2.0"
gem "jquery-rails"
gem "librato-rails"
gem "lograge"
gem "omniauth-github"
gem "omniauth-heroku", "0.2.0"
gem "omniauth-slack", "2.3.0"
gem "pg"
gem "puma"
gem "railties", ">= 5.0.0.1", "< 5.1"
gem "rails_stdout_logging", "0.0.4"
gem "rbnacl-libsodium", require: "rbnacl/libsodium"
gem "redis", "~> 3.0"
gem "sentry-raven"
gem "sidekiq"
gem "sinatra", "2.0.0.pre.alpha"
gem "sass-rails", "~> 5.0"
gem "sprockets-rails"
gem "turbolinks"
gem "uglifier", ">= 1.3.0"

group :development, :test do
  gem "brakeman"
  gem "byebug"
  gem "dotenv-rails"
  gem "pry"
  gem "rspec-rails", "3.5.0"
  gem "rubocop"
end

group :test do
  gem "capybara"
  gem "codeclimate-test-reporter", require: nil
  gem "timecop"
  gem "webmock", require: false
end

group :development do
  gem "foreman"
  gem "spring"
end

group :staging, :production do
  gem "rails_12factor"
end
