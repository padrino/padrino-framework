PADRINO_ROOT = File.dirname(__FILE__) unless defined? PADRINO_ROOT
require 'sinatra/base'
require 'haml'
require 'padrino-core'

class Core1Demo < Padrino::Application
  set :app_file, __FILE__
  disable :reload
  disable :padrino_routing
  disable :padrino_mailer
  disable :padrino_helpers
  
  get "/" do
    "Im Core1Demo"
  end
end

class Core2Demo < Padrino::Application
  set :app_file, __FILE__
  disable :reload
  disable :padrino_routing
  disable :padrino_mailer
  disable :padrino_helpers
  
  get "/" do
    "Im Core2Demo"
  end
end

orig_stdout = $stdout
$stdout = log_buffer = StringIO.new
Padrino.load!
$stdout = orig_stdout
log_buffer.rewind && log_buffer.read