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
    gem "sinatra", :git => "git://github.com/sinatra/sinatra.git" # :path => "/Developer/src/Extras/sinatra"
  end
  gem "nokogiri",  "~> 1.5.10"
  gem "json",      ">= 1.5.3"
  gem "rack",      ">= 1.3.0"
  gem "rake",      ">= 0.8.7"
  gem "yard",      ">= 0.7.2"
  gem "rack-test", ">= 0.5.0"
  gem "fakeweb",   ">= 1.2.8"
  gem "webrat",    ">= 0.5.1"
  gem "haml",      ">= 2.2.22"
  gem "erubis",    ">= 2.7.0"
  gem "slim",      ">= 1.3.0"
  gem "uuid",      ">= 2.3.1"
  gem "builder",   ">= 2.1.2"
  gem "bcrypt-ruby", :require => "bcrypt"
  platforms :jruby do
    gem "jruby-openssl"
  end
  platforms :rbx do
    gem 'rubysl'
    gem 'racc'
  end
  gem "mocha",    ">= 0.10.0"
  gem "minitest", "~> 4.0"
  gem "lumberjack"
end

%w[
   padrino
   padrino-admin
   padrino-cache
   padrino-core
   padrino-gen
   padrino-helpers
   padrino-mailer
   padrino-auth
].each do |dep|
  gem dep, :path => File.expand_path('../' + dep, __FILE__)
end
