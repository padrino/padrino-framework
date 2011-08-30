require File.expand_path("../padrino-core/lib/padrino-core/version.rb", __FILE__)

source :rubygems

group :db do
  gem "dm-core", ">= 1.0"
  gem "dm-migrations", ">= 1.0"
  gem "dm-validations", ">= 1.0"
  gem "dm-aggregates", ">= 1.0"
  gem "dm-sqlite-adapter", ">= 1.0"
end

group :development do
  if ENV['SINATRA_EDGE']
    puts "=> Using sinatra edge"
    gem "sinatra", :git => "git://github.com/sinatra/sinatra.git"
  end
  gem "json", "1.5.3"
  gem "nokogiri", "1.4.4"
  gem "rack", "~> 1.3.0"
  gem "rake", ">= 0.8.7"
  gem "yard", ">= 0.7.2"
  gem "mocha", ">= 0.9.8"
  gem "rack-test", ">= 0.5.0"
  gem "fakeweb",  ">=1.2.8"
  gem "webrat", "= 0.5.1"
  gem "haml", ">= 2.2.22"
  gem "erubis", ">= 2.7.0"
  gem "slim", ">= 0.9.2"
  gem "shoulda", ">= 2.10.3"
  gem "uuid", ">= 2.3.1"
  gem "bcrypt-ruby", :require => "bcrypt"
  gem "builder", ">= 2.1.2"
  platforms :mri_18 do
    gem "rcov", "~> 0.9.8"
    gem "ruby-prof", ">= 0.9.1"
    gem "system_timer", ">= 1.0"
  end
  # platforms :mri_19 do
  #   gem "ruby-debug19"
  # end
  platforms :jruby do
    gem "jruby-openssl"
  end
end

group :cache do
  gem "redis",     ">= 2.0.0"
  gem "mongo",     ">= 1.3.1"
  platforms :mri do
    gem "bson_ext",  ">= 1.3.1"
    gem 'dalli',     ">= 1.0.2"
    # TODO enable and fix in travis-ci
    # gem "memcached", ">= 0.20.1"
  end
  platform :rbx do
    gem 'dalli',  ">= 1.0.2"
  end
  platform :jruby do
    gem "jruby-memcache-client"
  end
end

%w[
   padrino
   padrino-admin
   padrino-cache
   padrino-core
   padrino-gen
   padrino-helpers
   padrino-mailer
].each do |dep|
  gem dep, :path => File.join(File.expand_path(File.dirname(__FILE__)), dep)
end
