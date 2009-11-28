PADRINO_ROOT = File.dirname(__FILE__) unless defined? PADRINO_ROOT
# Remove this comment if you want do some like this: ruby PADRINO_ENV=test app.rb
# 
# require 'rubygems'
# require 'lib/padrino-core'
#

class SimpleDemo < Padrino::Application
  set :reload, true
end

SimpleDemo.controllers do
  get "/" do
    'The magick number is: 60!' # Change only the number!!!
  end
end

Padrino.load! # Replace this with Parino.run! unless Padrino.loaded? if you want to run the app standalone