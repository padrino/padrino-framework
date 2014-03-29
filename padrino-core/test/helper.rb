ENV['RACK_ENV'] = 'test'
PADRINO_ROOT = File.dirname(__FILE__) unless defined?(PADRINO_ROOT)

require File.expand_path('../../../load_paths', __FILE__)
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

# Rubies < 1.9 don't handle hashes in the properly order so to prevent
# this issue for now we remove extra values from mimetypes.
Rack::Mime::MIME_TYPES.delete(".xsl") # In this way application/xml respond only to .xml

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

  # Delegate other missing methods to response.
  def method_missing(name, *args, &block)
    if response && response.respond_to?(name)
      response.send(name, *args, &block)
    else
      super(name, *args, &block)
    end
  rescue Rack::Test::Error # no response yet
    super(name, *args, &block)
  end

  alias :response :last_response
end
