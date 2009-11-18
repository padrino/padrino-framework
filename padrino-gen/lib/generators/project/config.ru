RACK_ENV = ENV["RACK_ENV"] ||= "development" unless defined? RACK_ENV
require File.dirname(__FILE__) + '/config/boot.rb'

# Mount and run padrino applications
Padrino.mount("core").to("/")
run Padrino.application