PADRINO_ROOT = File.dirname(__FILE__) unless defined? PADRINO_ROOT
require 'rubygems'
require 'sinatra/base'
require 'lib/padrino-core'

Padrino.load!
Padrino.mount_core(:app_class => "Demo", :app_file => 'app.rb')

class Demo < Padrino::Application; end

Demo.controllers do
  get "/test" do
    'This should work'
  end
end

Demo.run!