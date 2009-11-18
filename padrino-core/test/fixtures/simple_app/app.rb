require 'sinatra/base'
require 'haml'

# PADRINO_ROOT = File.dirname(__FILE__)

class SimpleCoreDemo < Padrino::Application
  configure do
    set :root, File.dirname(__FILE__)
  end
end