require File.expand_path("../padrino-core/lib/padrino-core/version.rb", __FILE__)

base_path = File.expand_path(File.dirname(__FILE__), __FILE__)

source :rubygems

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
  gem "fakeweb",  ">=1.2.8"
  gem "webrat", "= 0.5.1"
  gem "haml", ">= 2.2.22"
  gem "erubis", ">= 2.7.0"
  gem "slim", ">= 0.9.2"
  gem "shoulda", ">= 2.10.3"
  gem "redis", ">= 2.0.0"
  gem "uuid", ">= 2.3.1"
  gem "bcrypt-ruby", :require => "bcrypt"
  gem "phocus"
  platforms :mri_18 do
    gem "rcov", "~> 0.9.8"
    gem "ruby-prof", ">= 0.9.1"
    gem "system_timer", ">= 1.0"
  end
  platforms :mri_19 do
    gem "ruby-debug19"
  end
  platforms :mri do
    gem "memcached", ">= 0.20.1"
    gem 'dalli',     ">=1.0.2"
  end
end

gem "padrino",         :path => "/#{base_path}/padrino"
gem "padrino-admin",   :path => "/#{base_path}/padrino-admin"
gem "padrino-cache",   :path => "/#{base_path}/padrino-cache"
gem "padrino-core",    :path => "/#{base_path}/padrino-core"
gem "padrino-gen",     :path => "/#{base_path}/padrino-gen"
gem "padrino-helpers", :path => "/#{base_path}/padrino-helpers"
gem "padrino-mailer",  :path => "/#{base_path}/padrino-mailer"