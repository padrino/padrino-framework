ENV['RACK_ENV'] = 'test'
PADRINO_ROOT = __dir__ unless defined?(PADRINO_ROOT)

require 'minitest/autorun'
begin
  require 'minitest/mock'
rescue LoadError
  # minitest/mock is built-in for older minitest versions
end
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
  def mock_app(base = Padrino::Application, &block)
    @app = Sinatra.new(base, &block)
  end

  def app
    Rack::Lint.new(@app)
  end

  # Hides String#constantize and String#underscore (from padrino-gen or
  # ActiveSupport) so the block runs against plain Ruby strings.
  def without_string_inflections
    hidden = %i[constantize underscore].select { |name| String.method_defined?(name) }
    hidden.each do |name|
      String.send(:alias_method, :"__hidden_#{name}", name)
      String.send(:remove_method, name)
    end
    yield
  ensure
    Array(hidden).each do |name|
      String.send(:alias_method, name, :"__hidden_#{name}")
      String.send(:remove_method, :"__hidden_#{name}")
    end
  end
end
