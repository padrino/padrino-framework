require File.expand_path("../padrino-core/lib/padrino-core/version.rb", __FILE__)

source 'https://rubygems.org'

if ENV["AS_VERSION"]
  gem 'activesupport', "~> #{ENV['AS_VERSION']}"
end

if ENV["SINATRA_VERSION"]
  puts "=> Using Sinatra version #{ENV['SINATRA_VERSION']}"
  gem "sinatra", "~> #{ENV['SINATRA_VERSION']}"
end

group :db do
  gem "sequel"
  gem "sqlite3", :platforms => [:mri, :rbx]
  gem "jdbc-sqlite3", "~> 3.7.2", :platform => :jruby
end

group :development do
  if ENV['SINATRA_EDGE']
    puts "=> Using sinatra edge"
    gem "sinatra", :git => "git://github.com/sinatra/sinatra.git"
  end
  gem "rack",      ">= 1.3.0"
  gem "rake",      "< 11.0"
  gem "yard",      ">= 0.7.2"
  gem "rack-test", "~> 0.6.3"
  gem "fakeweb",   ">= 1.2.8"
  gem "oga",       "~> 2.5"
  gem "liquid",    ">= 2.1.2", "< 4"
  if ENV['HAML_ENGINE'] == 'haml' || RUBY_VERSION < "2.0.0"
    puts "=> Using legacy Haml engine"
    gem "haml", ">= 4.0.5"
  else
    gem "hamlit"
  end
  case ENV['ERB_ENGINE']
  when "stdlib"
    puts "=> Using stdlib ERB engine"
  when "erubis"
    puts "=> Using Erubis ERB engine"
    gem "erubis",    ">= 2.7.0"
  else
    gem "erubi",     ">= 1.6.0"
  end
  gem "slim",      ">= 1.3.0"
  gem "builder",    ">= 2.1.2"
  gem "mustermann19"
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
