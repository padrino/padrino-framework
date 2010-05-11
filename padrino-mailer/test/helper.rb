ENV['PADRINO_ENV'] = 'test'
PADRINO_ROOT = File.dirname(__FILE__) unless defined? PADRINO_ROOT

require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'mocha'
require 'rack/test'
require 'sinatra/base'

# We try to load the vendored padrino-core if exist
%w(core).each do |lib|
  if File.exist?(File.dirname(__FILE__) + "/../../padrino-#{lib}/lib")
    $:.unshift File.dirname(__FILE__) + "/../../padrino-#{lib}/lib"
  end
end

require 'padrino-core'
require 'padrino-mailer'

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

  # Silences the output by redirecting to stringIO
  # silence_logger { ...commands... } => "...output..."
  def silence_logger(&block)
    orig_stdout = $stdout
    $stdout = log_buffer = StringIO.new
    block.call
    $stdout = orig_stdout
    log_buffer.rewind && log_buffer.read
  end

  def pop_last_delivery
    Mail::TestMailer.deliveries.pop
  end

  # Asserts that the specified email object was delivered
  def assert_email_sent(mail_attributes, options={})
    mail_message = Mail::TestMailer.deliveries.last
    raise "No mail message has been sent!" unless mail_message.present?
    smtp_settings = options.delete(:smtp) || mail_attributes.delete(:smtp)
    delivery_attributes = mail_attributes
    delivery_attributes = { :to => Array(mail_attributes[:to]), :from => Array(mail_attributes[:from]) }
    delivery_attributes.each_pair do |k, v|
      unless mail_message.method(k).call == v
        raise "Mail failure (#{k}): #{mail_message.attributes.inspect} does not match #{delivery_attributes.inspect}"
      end
    end
    Mail::TestMailer.deliveries.clear
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
  end
  alias :response :last_response
end