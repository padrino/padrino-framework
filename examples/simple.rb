require 'bundler/setup'
require 'padrino-core'

Padrino.new do
  set :welcome, 'Hello World'

  get '/' do
    settings.welcome
  end

  get :foo, '/foo' do
    'hello foo'
  end

  desc 'My route description is optional'
  path '/bar'
  get :bar do
    'welcome to the bar'
  end

  run!
end

#
# or with new (anonymous class)
#
# Padrino::Application.run! do
#   set :foo, :bar
#   get '/' do
#     'hello world'
#   end
# end
#
# or classic/classy
#
# class App < Padrino::Application
#   set :foo, :bar
#   get '/' do
#     'hello world'
#   end
#
#   run!
# end
#
