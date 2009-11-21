PADRINO_ROOT = File.dirname(__FILE__) unless defined? PADRINO_ROOT
require 'sinatra/base'
require 'padrino-core'

class Multi1Demo < Padrino::Application
  disable :padrino_routing
  disable :padrino_mailer
  disable :padrino_helpers
  
  get "" do
    "Im Core1Demo"
  end
end

class Mutli2Demo < Padrino::Application
  disable :padrino_routing
  disable :padrino_mailer
  disable :padrino_helpers
  
  get "" do
    "Im Core2Demo"
  end
end

Padrino.mount("multi_1_demo").to("/multi_1_demo")
Padrino.mount("multi_2_demo").to("/multi_2_demo")
Padrino.load!
