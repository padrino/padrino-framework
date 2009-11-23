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

SingleDemo.controllers do
  get "/" do
    'This should work too'
  end
end

Padrino.mount_core("single_demo")

if Padrino.load!
  SingleDemo.run!
end