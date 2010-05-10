PADRINO_ROOT = File.dirname(__FILE__) unless defined? PADRINO_ROOT
# Remove this comment if you want do some like this: ruby PADRINO_ENV=test app.rb
#
# require 'rubygems'
# require 'lib/padrino-core'
#

class SimpleDemo < Padrino::Application
  set :reload, true
  before { true }
  after  { true }
  error(404) { "404" }
end

SimpleDemo.controllers do
  get "/" do
    'The magick number is: 28!' # Change only the number!!!
  end

  get "/rand" do
    rand(99).to_s
  end
end

## If you want use this as a standalone app uncomment:
#
# Padrino.mount_core("SimpleDemo")
# Padrino.run! unless Padrino.loaded? # If you enable reloader prevent to re-run the app
#

Padrino.load!