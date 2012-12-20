require 'bundler/setup'
require 'padrino-core'
require 'slim'

Padrino.new do

  get '/' do
    render :page # or /page
  end

  get '/a' do
    render slim: '/page' # or :page
  end

  get '/b' do
    slim :page
  end

  get '/c' do
    render text: '<b>hello<b>', as: :erb
  end

  run!
end
