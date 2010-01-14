require 'usher'
require 'sinatra/base'

# Defines our PADRINO_ENV
PADRINO_ENV = ENV["PADRINO_ENV"] ||= ENV["RACK_ENV"] ||= "development" unless defined?(PADRINO_ENV)

module Padrino
  class ApplicationLoadError < RuntimeError; end
  # Helper method for file references.
  #
  # Example:
  #   # Referencing a file in config called settings.yml
  #   Padrino.root("config", "settings.yml")
  #   # returns PADRINO_ROOT + "/config/setting.yml"
  def self.root(*args)
    File.expand_path(File.join(PADRINO_ROOT, *args))
  end

  # Helper method that return PADRINO_ENV
  def self.env
    PADRINO_ENV.to_s.downcase.to_sym
  end

  # Returns the resulting rack builder mapping each 'mounted' application
  def self.application
    raise ApplicationLoadError.new("At least one app must be mounted!") unless self.mounted_apps && self.mounted_apps.any?
    builder = Rack::Builder.new
    self.mounted_apps.each { |app| app.map_onto(builder) }
    builder
  end

  # Method used for require dependencies and correct support_lite
  def self.require_dependencies!
    require root('vendor', 'gems', 'environment')
    Bundler.require_env(Padrino.env)
    Dir[File.dirname(__FILE__) + '/padrino-core/*.rb'].each {|file| require file }
    puts "=> Loaded bundled gems for #{Padrino.env} with #{Padrino.support.to_s.humanize}"
  rescue LoadError
    require 'bundler'
    if File.exist?(root("Gemfile"))
      Bundler::Bundle.load(root("Gemfile")).environment.require_env(Padrino.env)
      Dir[File.dirname(__FILE__) + '/padrino-core/*.rb'].each {|file| require file }
      puts "=> Located Gemfile for #{Padrino.env} with #{Padrino.support.to_s.humanize}"
    else
      Dir[File.dirname(__FILE__) + '/padrino-core/*.rb'].each {|file| require file }
    end
  end
end

# When we require this file is necessary check if we have a gemfile o bundled gems, 
# this because we load ExtLib or ActiveSupport if some of our dependencies
# just require them. This prevent for example to load ActiveSupport
# when we require only 'dm-core'.
Padrino.require_dependencies!