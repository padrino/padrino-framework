require_relative 'helper'
require 'open3'
require 'timeout'

describe 'Padrino::Server' do
  describe 'detect_rack_handler' do
    def with_available_handlers(*available, &block)
      get = lambda do |name|
        raise LoadError, name unless available.include?(name)

        Object
      end
      Rackup::Handler.stub(:get, get, &block)
    end

    it 'should detect falcon when it is the only server available' do
      with_available_handlers('falcon') do
        assert_equal :falcon, Padrino::Server.detect_rack_handler
      end
    end

    it 'should prefer puma over falcon' do
      with_available_handlers('falcon', 'puma') do
        assert_equal :puma, Padrino::Server.detect_rack_handler
      end
    end

    it 'should raise when no server is available' do
      with_available_handlers do
        assert_raises(RuntimeError) { Padrino::Server.detect_rack_handler }
      end
    end

    it 'should not pick a removed server' do
      with_available_handlers('mongrel', 'spider-gazelle', 'trinidad', 'webrick') do
        assert_equal :webrick, Padrino::Server.detect_rack_handler
      end
    end
  end

  describe 'start' do
    ['mongrel', 'spider-gazelle', 'trinidad', :mongrel, 'Mongrel', 'spider_gazelle', 'SpiderGazelle'].each do |server|
      it "should stop naming the supported servers when asked for #{server.inspect}" do
        Rackup::Handler.stub(:get, ->(name) { raise "looked up the #{name} handler" }) do
          error = assert_raises(RuntimeError) { Padrino::Server.start(->(_env) { [200, {}, []] }, server: server) }
          assert_match(/\AThe #{server} server was removed from Padrino; use one of .*\bwebrick\b/, error.message)
        end
      end
    end

    it 'should stop for a removed server given as a server option' do
      Rackup::Handler.stub(:get, ->(name) { raise "looked up the #{name} handler" }) do
        error = assert_raises(RuntimeError) { Padrino::Server.start(->(_env) { [200, {}, []] }, options: ['server=mongrel']) }
        assert_match(/\AThe mongrel server was removed from Padrino/, error.message)
      end
    end
  end

  describe 'signals' do
    # Starts Padrino::Server in a child process on a fake handler that, like WEBrick, yields its
    # server and then loops until the server is shut down, sends the child TERM and returns its output.
    def start_and_term(server_methods)
      script = <<~RUBY
        require 'padrino-core'
        class FakeServer
          #{server_methods}
          def start
            puts 'READY'
            $stdout.flush
            sleep 0.05 until @stopped
            puts 'STOPPED'
          end
        end
        module FakeHandler
          def self.run(_app, **_options)
            server = FakeServer.new
            yield server
            server.start
          end
        end
        Rackup::Handler.register('fake', FakeHandler)
        Padrino::Server.start(->(_env) { [200, {}, []] }, server: 'fake', Port: 0)
      RUBY
      lib = File.expand_path('../lib', __dir__)
      Open3.popen2e({ 'RACK_ENV' => 'test' }, RbConfig.ruby, '-I', lib, '-e', script) do |_stdin, out, wait|
        output = +''
        Timeout.timeout(60) do
          output << out.gets.to_s until output.include?('READY') || out.eof?
          Process.kill('TERM', wait.pid)
          output << out.read
          [output, wait.value]
        end
      rescue Timeout::Error
        Process.kill('KILL', wait.pid)
        raise
      end
    end

    it 'should shut the server down on TERM when it supports shutdown' do
      output, status = start_and_term("def shutdown\n  puts 'SHUTDOWN'\n  @stopped = true\nend")
      assert status.success?, output
      assert_includes output, 'SHUTDOWN'
      assert_includes output, 'STOPPED'
      refute_includes output, 'SystemExit'
    end

    it 'should exit on TERM when the server does not support shutdown' do
      output, status = start_and_term('')
      assert status.success?, output
      refute_includes output, 'STOPPED'
      assert_includes output, 'leaves the gun'
    end
  end
end
