PADRINO_ROOT = File.dirname(__FILE__) unless defined? PADRINO_ROOT
# Remove this comment if you want do some like this: ruby PADRINO_ENV=test app.rb
# 
# require 'rubygems'
# require 'lib/padrino-core'
#
require 'haml'

class LayoutDemo < Padrino::Application

  # We don have a layout
  get "/no_layout" do
    "no layout"
  end

  # We use the sinatra way
  layout :index do
    'sinatra layout'
  end

  get '/sinatra' do
    haml :index
  end
end

Padrino.mount_core("layout_demo")
Padrino.load!