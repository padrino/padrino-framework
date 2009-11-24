ENV['PADRINO_ENV'] = 'test'
PADRINO_ROOT = File.dirname(__FILE__) unless defined? PADRINO_ROOT

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rubygems'
require 'padrino-core'
require 'test/unit'
require 'rack/test'
require 'rack'
require 'shoulda'

class Test::Unit::TestCase
  include Rack::Test::Methods

  # Test App
  class PadrinoTestApp < Padrino::Application; end

  # Sets up a Sinatra::Base subclass defined with the block
  # given. Used in setup or individual spec methods to establish
  # the application.
  def mock_app(base=PadrinoTestApp, &block)
    @app = Sinatra.new(base, &block)
  end
  
  def app
    Rack::Lint.new(@app)
  end

  def stop_time_for_test
    time = Time.now
    Time.stubs(:now).returns(time)
    return time
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
      super
    end
  end

  alias :response :last_response
end

class Object
  # Silences the output by redirecting to stringIO
  # silence_logger { ...commands... } => "...output..."
  def silence_logger(&block)
    orig_stdout = $stdout
    $stdout = log_buffer = StringIO.new
    block.call
    $stdout = orig_stdout
    log_buffer.rewind && log_buffer.read
  end
end