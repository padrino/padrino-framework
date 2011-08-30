PADRINO_ROOT = File.dirname(__FILE__) unless defined? PADRINO_ROOT
# Remove this comment if you want do some like this: ruby PADRINO_ENV=test app.rb
#
# require 'rubygems'
# require 'padrino-core'
#

class SimpleDemo < Padrino::Application
  set :reload, true
  before { true }
  after  { true }
  error(404) { "404" }
end

SimpleDemo.controllers do
  get "/" do
    'The magick number is: 53296193744170944745261719220602335872612613085272021442778373180713604277957!' # Change only the number!!!
  end

  get "/rand" do
    rand(2 ** 256).to_s
  end
end

## If you want use this as a standalone app uncomment:
#
# Padrino.mount("SimpleDemo").to("/")
# Padrino.run! unless Padrino.loaded? # If you enable reloader prevent to re-run the app
#
# Then run it from your console: ruby -I"lib" test/fixtures/apps/simple.rb
#

Padrino.load!
