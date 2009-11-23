PADRINO_ROOT = File.dirname(__FILE__) unless defined? PADRINO_ROOT
require 'rubygems'
require 'lib/padrino-core'

class SingleDemo < Padrino::Application
  set :reload, true
end

SingleDemo.controllers do
  get "/test" do
    'This should work'
  end
end

Padrino.mount_core("single_demo")
Padrino.load!
