require File.dirname(__FILE__) + '/helper'

class TestPadrinoLogger < Test::Unit::TestCase

  def setup
    Padrino::Logger::Config[:test][:stream] = :null # The default
    Padrino::Logger.setup!
  end

  def setup_logger(options={})
    @log    = StringIO.new
    @logger = Padrino::Logger.new(options.merge(:stream => @log))
  end

  context 'for logger functionality' do

    context 'check stream config' do

      should 'use stdout if stream is nil' do
        Padrino::Logger::Config[:test][:stream] = nil
        Padrino::Logger.setup!
        assert_equal $stdout, Padrino.logger.log
      end

      should 'use StringIO as default for test' do
        assert_instance_of StringIO, Padrino.logger.log
      end

      should 'use a custom stream' do
        my_stream = StringIO.new
        Padrino::Logger::Config[:test][:stream] = my_stream
        Padrino::Logger.setup!
        assert_equal my_stream, Padrino.logger.log
      end
    end

    should 'log something' do
      setup_logger(:log_level => :error)
      @logger.error "You log this error?"
      assert_match(/You log this error?/, @log.string)
      @logger.debug "You don't log this error!"
      assert_no_match(/You don't log this error!/, @log.string)
      @logger << "Yep this can be logged"
      assert_match(/Yep this can be logged/, @log.string)
    end

    should 'log an application' do
      mock_app { get("/"){ "Foo" } }
      get "/"
      assert_equal "Foo", body
      assert_match /GET \/  - 200/, Padrino.logger.log.string
    end

  end
end