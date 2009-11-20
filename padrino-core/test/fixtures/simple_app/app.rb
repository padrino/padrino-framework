PADRINO_ROOT = File.dirname(__FILE__) unless defined? PADRINO_ROOT
require 'sinatra/base'
require 'padrino-core'

class Core1Demo < Padrino::Application
  disable :padrino_routing
  disable :padrino_mailer
  disable :padrino_helpers
  
  get "" do
    "Im Core1Demo"
  end
end

class Core2Demo < Padrino::Application
  disable :padrino_routing
  disable :padrino_mailer
  disable :padrino_helpers
  
  get "" do
    "Im Core2Demo"
  end
end

silence_logger { Padrino.load! }
