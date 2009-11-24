PADRINO_ROOT = File.dirname(__FILE__) unless defined? PADRINO_ROOT
# Remove this comment if you want do some like this: ruby PADRINO_ENV=test app.rb
# 
# require 'rubygems'
# require 'lib/padrino-core'
# 
# Use this for prevent (when reload is in use) to re run the server.
# 
# if Padrino.load!
#   SingleDemo.run!
# end

class SingleDemo < Padrino::Application
  set :reload, true
end

SingleDemo.controllers do
  get "/" do
    'The magick number is: 79!' # Change only the number!!!
  end
end

Padrino.load! # Remove this if you will run the app standalone