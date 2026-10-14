require_relative 'helper'
require 'padrino-core/cli/launcher'

describe 'Padrino::Cli::Launcher' do
  describe 'server_options' do
    def fake_handler
      handler = Object.new
      def handler.name
        'FakeHandler'
      end

      def handler.valid_options
        { 'Host=HOST' => 'Hostname to listen on', 'Threads=MIN:MAX' => 'min:max threads to use' }
      end
      handler
    end

    def server_options(options)
      Padrino::Cli::Launcher.new.send(:server_options, options)
    end

    it 'should list the options of the named rackup handler' do
      handler = fake_handler
      get = ->(name) { handler if name == 'fake' }
      out = Rackup::Handler.stub(:get, get) { server_options(server: 'fake') }
      assert_match(/Server-specific options for FakeHandler/, out)
      assert_match(/-O Threads=MIN:MAX\s+min:max threads to use/, out)
      refute_match(/Host=HOST/, out)
    end

    it 'should fall back to the default rackup handler' do
      handler = fake_handler
      out = Rackup::Handler.stub(:get, nil) do
        Rackup::Handler.stub(:default, handler) { server_options({}) }
      end
      assert_match(/Server-specific options for FakeHandler/, out)
    end

    it 'should warn when no rackup handler can be loaded' do
      out = Rackup::Handler.stub(:get, nil) do
        Rackup::Handler.stub(:default, -> { raise LoadError, "Couldn't find handler" }) { server_options({}) }
      end
      assert_equal 'Warning: Could not find handler specified (default) to determine handler-specific options', out
    end
  end

  it 'should point the --options help at start --server_options' do
    description = Padrino::Cli::Launcher.commands['start'].options[:options].description
    assert_includes description, "start --server_options'"
  end
end
