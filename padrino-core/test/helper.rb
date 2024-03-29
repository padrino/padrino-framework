ENV['RACK_ENV'] = 'test'
PADRINO_ROOT = File.dirname(__FILE__) unless defined?(PADRINO_ROOT)

require 'minitest/autorun'
require 'minitest/pride'
require 'i18n'
require 'json'
require 'builder'
require 'rack/test'
require 'yaml'
require 'padrino-core'

require 'ext/minitest-spec'
require 'ext/rack-test-methods'

class Minitest::Spec
  include Rack::Test::Methods

  # Sets up a Sinatra::Base subclass defined with the block
  # given. Used in setup or individual spec methods to establish
  # the application.
  def mock_app(base=Padrino::Application, &block)
    @app = Sinatra.new(base, &block)
  end

  def app
    Rack::Lint.new(@app)
  end
end
