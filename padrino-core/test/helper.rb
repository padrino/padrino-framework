ENV['RACK_ENV'] = 'test'
PADRINO_ROOT = File.dirname(__FILE__) unless defined?(PADRINO_ROOT)

require 'minitest/autorun'
require 'minitest/pride'
require 'i18n'
require 'padrino-support'
require 'padrino-core'
require 'json'
require 'builder'
require 'rack/test'
require 'rack'
require 'yaml'

class MiniTest::Spec
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

  # Asserts that a file matches the pattern
  def assert_match_in_file(pattern, file)
    assert File.exist?(file), "File '#{file}' does not exist!"
    assert_match pattern, File.read(file)
  end

  # Delegate some methods to the last response
  alias_method :response, :last_response

  [:status, :headers, :body, :content_type, :ok?, :forbidden?].each do |method_name|
    define_method method_name do
      last_response.send(method_name)
    end
  end
end
