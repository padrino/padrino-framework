require 'bundler/setup'
require 'padrino-core'

module Route1
  include Padrino::Routes

  get '/route1' do
    'route1'
  end
end

module Route2
  include Padrino::Routes

  get '/route2' do
    'route2'
  end
end

module Route3
  include Route1
  include Route2

  get '/route3' do
    'route3'
  end
end

Padrino.new do
  include Route3

  get '/' do
    'Hello world!'
  end

  run!
end
