PADRINO_ENV = 'test'

require 'rspec'
require 'rspec-html-matchers'
require 'rack/test'
require 'padrino-flash'

module TestHelpers
  def app
    @app ||= Sinatra.new(Padrino::Application) do
      register Padrino::Flash
      set :logging, false

      get :flash do
        flash.now.inspect
      end

      post :flash do
        params.each { |type, message| flash[type.to_sym] = message }
        flash.now.inspect
      end
    end
  end

  def session
    @session ||= { :_flash => { :notice =>  'Flash Notice', :success => 'Flash Success' }}
  end
end

RSpec.configure do |configuration|
  configuration.include TestHelpers
  configuration.include Rack::Test::Methods
end

I18n.load_path += Dir[(File.dirname(__FILE__) + '/fixtures/locale/*.yml')]