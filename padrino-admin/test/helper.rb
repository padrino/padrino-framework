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
require 'padrino-core'
require 'padrino-gen'
require 'padrino-admin'

module Kernel
  # Silences the output by redirecting to stringIO
  # silence_logger { ...commands... } => "...output..."
  def silence_logger(&block)
    $stdout = log_buffer = StringIO.new
    block.call
    $stdout = STDOUT
    log_buffer.string
  end
  alias :silence_stdout :silence_logger
end

# Fake Category Model
class Category
  attr_reader :id, :name
  def initialize(name)
    @id, @name = rand(99), name
  end
end

# Fake Account Model
class Account
  attr_reader :id, :name, :role, :categories
  def initialize(name, role)
    @id, @name, @role = rand(99), name, role
    # Fake has_many association
    @categories  = %w{Post News Press}.map { |name| Category.new(name) }
  end
end

# We build some fake accounts
AdminAccount  = Account.new("DAddYE", "admin")
EditorAccount = Account.new("Luke",   "editor")

class Class
  # Allow assertions in request context
  include Test::Unit::Assertions
end

class Test::Unit::TestCase
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
      super
    end
  end

  alias :response :last_response
end