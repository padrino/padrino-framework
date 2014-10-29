require File.expand_path("../padrino-core/lib/padrino-core/version.rb", __FILE__)

source 'https://rubygems.org'

if ENV["AS_VERSION"]
  gem 'activesupport', "~> #{ENV['AS_VERSION']}"
end

group :db do
  gem "dm-core",           ">=1.2"
  gem "dm-migrations",     ">=1.2"
  gem "dm-validations",    ">=1.2"
  gem "dm-aggregates",     ">=1.2"
  gem "dm-sqlite-adapter", ">=1.2"
end

group :development do
  if ENV['SINATRA_EDGE']
    puts "=> Using sinatra edge"
    gem "sinatra", :git => "git://github.com/sinatra/sinatra.git"
  end
  gem "nokogiri",  "~> 1.5.10"
  gem "rack",      ">= 1.3.0"
  gem "rake",      ">= 0.8.7"
  gem "yard",      ">= 0.7.2"
  gem "rack-test", ">= 0.5.0"
  gem "fakeweb",   ">= 1.2.8"
  gem "webrat",    ">= 0.5.1"
  gem "haml",      ">= 4.0.5"
  if ENV['STDLIB_ERB']
    puts "=> Using stdlib ERB engine"
  else
    gem "erubis",    ">= 2.7.0"
  end
  gem "slim",      ">= 1.3.0"
  gem "builder",    ">= 2.1.2"
  if RUBY_VERSION < '2.0.0'
    gem "mustermann19"
  else
    gem "mustermann"
  end
  platforms :jruby do
    gem "jruby-openssl"
  end
  gem "mocha",    ">= 0.10.0"
  gem "minitest", ">= 4.0"
end

load File.expand_path('../padrino/subgems.rb', __FILE__)
PADRINO_GEMS.each_key do |name|
  gem name, :path => File.expand_path('../' + name, __FILE__)
end
