require File.expand_path(File.dirname(__FILE__) + '/helper')

module Rack::Handler
  class Mock
    extend Test::Unit::Assertions

    def self.run(app, options={})
      assert_equal 9001, options[:Port]
      assert_equal 'foo.local', options[:Host]
      yield new
    end

    def stop
    end
  end

  register 'mock', 'Rack::Handler::Mock'
  Padrino::Server::Handlers << 'mock'
end

class ServerApp < Padrino::Application; end

class ServerTest < Test::Unit::TestCase
  def setup
    Padrino.mount("server_app").to("/")
  end

  context 'for server functionality' do
    should "locates the appropriate Rack handler and calls ::run" do
      silence_logger { Padrino.run!(:host => 'foo.local', :port => 9001, :adapter => 'mock') }
    end

    should "falls back on the next server handler when not found" do
      assert_raise(Padrino::Server::LoadError) { silence_logger {Padrino.run!(:host => 'foo.local', :port => 9001, :adapter => 'foo') } }
    end
  end
end