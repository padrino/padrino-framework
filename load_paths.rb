begin
  require File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  if defined?(Gem)
    gem 'bundler'
  else
    require 'rubygems'
  end
  require 'bundler'
  Bundler.setup
end