require File.dirname(__FILE__) + '/helper'

class TestPadrinoLogger < Test::Unit::TestCase

  def setup_logger(options={})
    @log    = StringIO.new
    @logger = Padrino::Logger.new(options.merge(:stream => @log))
  end

  context 'for logger functionality' do

    should 'log something' do
      setup_logger(:log_level => :error)
      @logger.error "You log this error?"
      assert_match(/You log this error?/, @log.string)
      @logger.debug "You don't log this error!"
      assert_no_match(/You don't log this error!/, @log.string)
      @logger << "Yep this can be logged"
      assert_match(/Yep this can be logged/, @log.string)
    end

    # This can work when in future we can configure Padrino Logging
    # so we can tell that for :test env we can log something.
    # 
    # should 'log an application' do
    #   setup_logger
    #   logger = @logger # We need to replace our padrino logger
    #   mock_app { get("/"){ "Foo" } }
    #   get "/"
    #   assert_equal "Foo", body
    #   assert_match /GET \/ " 200 - /, @log.string
    #   logger = nil # We need to reset padrino logger
    # end

  end
end