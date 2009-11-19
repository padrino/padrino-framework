PADRINO_ROOT = File.dirname(__FILE__) unless defined? PADRINO_ROOT
require 'sinatra/base'
require 'haml'
require 'padrino-core'

class Core1Demo < Sinatra::Base

  configure do
    set :root, File.dirname(__FILE__)
    set :log_to_file, true
  end
end

class Core2Demo < Sinatra::Base

  configure do
    set :root, File.dirname(__FILE__)
    set :log_to_file, true
  end
  
end