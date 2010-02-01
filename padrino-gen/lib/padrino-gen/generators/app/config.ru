PADRINO_ENV = ENV["PADRINO_ENV"] ||= ENV["RACK_ENV"] ||= "development" unless defined?(PADRINO_ENV)
require File.dirname(__FILE__) + '/config/boot.rb'
run Padrino.application