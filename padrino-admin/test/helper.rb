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
require 'dm-core'
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

DataMapper.setup(:default, 'sqlite3::memory:')

# Fake Category Model
class Category
  include DataMapper::Resource
  property :id,   Serial
  property :name, String
  belongs_to :account
end

# Fake Account Model
class Account
  include DataMapper::Resource
  property :id,   Serial
  property :name, String
  property :role, String
  has n, :categories
  def self.admin;  first(:role => "Admin");  end
  def self.editor; first(:role => "Editor"); end
end

DataMapper.auto_migrate!

# We build some fake accounts
admin  = Account.create(:name => "DAddYE", :role => "Admin")
editor = Account.create(:name => "Dexter", :role => "Editor")
%w(News Press HowTo).each do |c| 
  admin.categories.create(:name => c)
  editor.categories.create(:name => c)
end

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
    base.use Rack::Session::Cookie # Need this because Sinatra 0.9.4 have use Rack::Session::Cookie if sessions? && !test?
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