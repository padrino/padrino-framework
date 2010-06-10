begin
  require File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  if defined?(Gem)
    Gem.cache
    gem 'bundler'
  else
    require 'rubygems'
  end
  require 'bundler'
  Bundler.setup
end

%w(
  padrino
  padrino-admin
  padrino-cache
  padrino-core
  padrino-gen
  padrino-helpers
  padrino-mailer
).each do |framework|
  $:.unshift File.expand_path("../#{framework}/lib", __FILE__)
end