require 'rubygems'
require 'yaml'
require 'erb'
require 'json/pure' unless defined?(JSON) || defined?(JSON::Pure)

module Padrino
  module Admin
    module Config

      ##
      # This class it's used for JSON variables.
      # Normally if we convert this { :function => "alert('Test')" } will be:
      # 
      #   { "function": "alert('Test')" }
      # 
      # But if in our javascript need to "eval" this function is not possible because
      # it's a string.
      # 
      # Using Padrino::Config::Variable the result will be:
      # 
      #   { "function" : alert('Test') }
      # 
      # Normally an ExtJs Variable can be handled with ExtJs Config like:
      # 
      #   function: !js alert('Test')
      # 
      class Variable < String
        yaml_as "tag:yaml.org,2002:js"

        def to_json(*a) #:nodoc:
          self
        end
      end # Variable
    end # Config
  end # Admin
end # Padrino