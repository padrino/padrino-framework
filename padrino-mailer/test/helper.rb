ENV['RACK_ENV'] = 'test'
PADRINO_ROOT = File.dirname(__FILE__) unless defined? PADRINO_ROOT

require 'minitest/autorun'
require 'minitest/pride'
require 'rack/test'
require 'padrino-core'
require 'padrino-helpers'
require 'padrino/rendering'
require 'padrino-mailer/ext'
require 'padrino-mailer'

require 'ext/rack-test-methods'

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

  def pop_last_delivery
    Mail::TestMailer.deliveries.pop
  end

  # Asserts that the specified email object was delivered
  def assert_email_sent(mail_attributes, options={})
    mail_message = Mail::TestMailer.deliveries.last
    raise "No mail message has been sent!" unless mail_message
    delivery_attributes = mail_attributes
    delivery_attributes.update(:to => Array(mail_attributes[:to]), :from => Array(mail_attributes[:from]))
    delivery_attributes.each_pair do |key, expected|
      next unless mail_message.respond_to?(key)
      actual = mail_message.send(key)
      actual = actual.to_s.chomp if key == :body
      actual = mail_message.content_type_without_symbol.split(';').first if key == :content_type
      assert_equal expected, actual, "Mail failure at field '#{key}'"
    end
    Mail::TestMailer.deliveries.clear
  end
end
