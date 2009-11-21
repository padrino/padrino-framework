PADRINO_ROOT = File.dirname(__FILE__) unless defined? PADRINO_ROOT
require 'rubygems'
require 'sinatra/base'
require 'lib/padrino-core'

Padrino.load!
Padrino.mount_core("loop")

class Loop < Padrino::Application; end

Loop.controllers do
  get "/test" do
    'This should work'
  end
end

Loop.run!