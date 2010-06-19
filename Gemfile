require File.expand_path("../padrino-core/lib/padrino-core/version.rb", __FILE__)

source :rubygems

group :core do
  gem "sinatra", ">= 1.0.0"
  gem "http_router", ">= 0.2.5"
  gem "thor", ">= 0.13.0"
  # If you want try our test on AS edge.
  # $ AS=edge bundle install
  # $ AS=edge rake test
  if ENV['AS'] == "edge"
    puts "Using ActiveSupport 3.0.0.beta4"
    gem "activesupport", ">= 3.0.0.beta4", :require => nil
    gem "tzinfo"
  else
    gem "activesupport", ">= 2.3.8", :require => nil
  end
end

group :cache do
  gem "sinatra", ">= 0.9.2"
end

group :gen do
  gem "bundler", ">= 0.9.7"
end

group :helpers do
  gem "i18n", ">=0.4.1"
end

group :mailer do
  gem "mail", ">= 2.2.0"
  gem "tlsmail" if RUBY_VERSION == "1.8.6"
end

group :other do
  gem "builder", ">= 2.1.2"
end

group :db do
  gem "dm-core", ">= 1.0"
  gem "dm-migrations", ">= 1.0"
  gem "dm-validations", ">= 1.0"
  gem "dm-aggregates", ">= 1.0"
  gem "dm-sqlite-adapter", ">= 1.0"
end

group :development do
  gem "rake",  ">= 0.8.7"
  gem "mocha", ">= 0.9.8"
  gem "rack-test", ">= 0.5.0"
  gem "webrat", ">= 0.5.1"
  gem "haml", ">= 2.2.22"
  gem "shoulda", ">= 2.10.3"
end