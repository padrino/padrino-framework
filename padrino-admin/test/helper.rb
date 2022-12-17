ENV['RACK_ENV'] = 'test'
PADRINO_ROOT = File.dirname(__FILE__) unless defined? PADRINO_ROOT

require 'minitest/autorun'
require 'minitest/pride'
require 'rack/test'
require 'thor/group'
require 'sequel/model'
require 'padrino-admin'

require 'ext/minitest-spec'
require 'ext/rack-test-methods'
require 'mocha/minitest'

Padrino::Generators.load_components!

module Kernel
  def load_fixture(file)
    Object.send(:remove_const, :Account)  if defined?(Account)
    Object.send(:remove_const, :Category) if defined?(Category)
    file += ".rb" if file !~ /.rb$/
    capture_io { load File.join(File.dirname(__FILE__), "fixtures", file) }
  end
end

class MiniTest::Spec
  include Rack::Test::Methods

  # Sets up a Sinatra::Base subclass defined with the block
  # given. Used in setup or individual spec methods to establish
  # the application.
  def mock_app(base=Padrino::Application, &block)
    @app = Sinatra.new base do
      register Padrino::Helpers
      instance_eval &block
    end
  end

  def app
    Rack::Lint.new(@app)
  end

  # generate(:admin_app, "-r=#{@apptmp}/sample_project")
  def generate(name, *params)
    "Padrino::Generators::#{name.to_s.camelize}".constantize.start(params)
  end
end
