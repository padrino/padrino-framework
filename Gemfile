require File.expand_path('padrino-core/lib/padrino-core/version.rb', __dir__)

source 'https://rubygems.org'

if ENV['AS_VERSION']
  gem 'activesupport', "~> #{ENV['AS_VERSION']}"
end

group :db do
  gem 'jdbc-sqlite3', '~> 3.7.2', platform: :jruby
  gem 'sequel'
  gem 'sqlite3', platforms: [:mri]
end

group :development do
  if ENV['SINATRA_VERSION']
    puts "=> Using Sinatra version ~> #{ENV['SINATRA_VERSION']}"
    gem 'sinatra', "~> #{ENV['SINATRA_VERSION']}"
  elsif ENV['SINATRA_EDGE']
    puts '=> Using sinatra edge'
    gem 'sinatra', git: 'git://github.com/sinatra/sinatra.git'
  end

  gem 'liquid',    '>= 2.1.1'
  gem 'slim',      '>= 1.3.0'

  if ENV['HAML_ENGINE'] == 'hamlit'
    puts '=> Using Hamlit Haml engine'
    gem 'hamlit'
  else
    gem 'haml', '~> 5'
  end

  case ENV['ERB_ENGINE']
  when 'stdlib'
    puts '=> Using stdlib ERB engine'
  when 'erubis'
    puts '=> Using Erubis ERB engine'
    gem 'erubis',    '>= 2.7.0'
  else
    gem 'erubi',     '>= 1.6.1'
  end

  gem 'builder',          '>= 2.1.2'
  gem 'minitest',         '>= 4.0'
  gem 'mocha',            '>= 2.0'
  gem 'oga',              '>= 2.5', '< 3'
  gem 'rack',             '~> 3'
  gem 'rackup',           '~> 2.1'
  gem 'rack-test',        '~> 2.1'
  gem 'rake',             '>= 10.5.0'
  gem 'rb-readline',      '~> 0.4.2'
  gem 'rubocop',          '~> 1.6', platforms: [:mri]
  gem 'rubocop-minitest', '~>0.34.4', platforms: [:mri]
  gem 'webmock',          '~> 3.19'
  gem 'yard',             '>= 0.7.2'

  platforms :jruby do
    gem 'jruby-openssl'
  end
end

load File.expand_path('padrino/subgems.rb', __dir__)
PADRINO_GEMS.each_key do |name|
  gem name, path: File.expand_path("../#{name}", __FILE__)
end
