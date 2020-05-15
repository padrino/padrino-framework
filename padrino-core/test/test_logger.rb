#coding:utf-8
require File.expand_path(File.dirname(__FILE__) + '/helper')
require 'logger'
require 'tempfile'

describe "PadrinoLogger" do
  before do
    @save_config = Padrino::Logger::Config[:test].dup
    Padrino::Logger::Config[:test][:stream] = :null
    Padrino::Logger.setup!
  end

  after do
    Padrino::Logger::Config[:test] = @save_config
    Padrino::Logger.setup!
  end

  def setup_logger(options={})
    @log    = StringIO.new
    @logger = Padrino::Logger.new(options.merge(:stream => @log))
  end

  describe 'for logger functionality' do
    describe 'check stream config' do
      it 'should use stdout if stream is nil' do
        Padrino::Logger::Config[:test][:stream] = nil
        Padrino::Logger.setup!
        assert_equal $stdout, Padrino.logger.log
      end

      it 'should use StringIO as default for test' do
        assert_instance_of StringIO, Padrino.logger.log
      end

      it 'should use a custom stream' do
        my_stream = StringIO.new
        Padrino::Logger::Config[:test][:stream] = my_stream
        Padrino::Logger.setup!
        assert_equal my_stream, Padrino.logger.log
      end

      it 'should use a custom file path' do
        tempfile = Tempfile.new('app.txt')
        path = tempfile.path
        tempfile.unlink
        Padrino::Logger::Config[:test][:stream] = :to_file
        Padrino::Logger::Config[:test][:log_path] = path
        Padrino::Logger.setup!
        assert_file_exists path
        File.unlink(path)
      end

      it 'should use a custom log directory' do
        tmpdir = Dir.mktmpdir
        Padrino::Logger::Config[:test][:stream] = :to_file
        Padrino::Logger::Config[:test][:log_path] = tmpdir
        Padrino::Logger.setup!
        log_path = File.join(tmpdir, 'test.log')
        assert_file_exists log_path
        File.unlink(log_path)
        Dir.rmdir(tmpdir)
      end
    end

    it 'should log something' do
      setup_logger(:log_level => :error)
      @logger.error "You log this error?"
      assert_match(/You log this error?/, @log.string)
      @logger.debug "You don't log this error!"
      refute_match(/You don't log this error!/, @log.string)
      @logger << "Yep this can be logged"
      assert_match(/Yep this can be logged/, @log.string)
    end

    it 'should respond to #write for Rack::CommonLogger' do
      setup_logger(:log_level => :error)
      @logger.error "Error message"
      assert_match /Error message/, @log.string
      @logger << "logged anyways"
      assert_match /logged anyways/, @log.string
      @logger.write "log via alias"
      assert_match /log via alias/, @log.string
    end

    it 'should not blow up on mixed or broken encodings' do
      setup_logger(:log_level => :error, :auto_flush => false)
      binary_data = "\xD0".force_encoding('BINARY')
      utf8_data = 'фыв'
      @logger.error binary_data
      @logger.error utf8_data
      @logger.flush
      assert @log.string.include?(utf8_data)
      assert @log.string.force_encoding('BINARY').include?(binary_data)
    end

    it 'should sanitize mixed or broken encodings if said so' do
      encoding = 'windows-1251'
      setup_logger(:log_level => :error, :auto_flush => false, :sanitize_encoding => encoding)
      @log.string.encode! encoding
      binary_data = "\xD0".force_encoding('BINARY')
      utf8_data = 'фыв'
      @logger.error binary_data
      @logger.error utf8_data
      @logger.flush
      assert @log.string.force_encoding(encoding).include?("?\n".encode(encoding))
      assert @log.string.force_encoding(encoding).include?(utf8_data.encode(encoding))
    end

    it 'should log an application' do
      mock_app do
        enable :logging
        get("/"){ "Foo" }
      end
      get "/"
      assert_equal "Foo", body
      assert_match /GET/, Padrino.logger.log.string
    end

    it 'should log an application\'s status code' do
      mock_app do
        enable :logging
        get("/"){ "Foo" }
      end
      get "/"
      assert_match /\e\[1;9m200\e\[0m OK/, Padrino.logger.log.string
    end

    describe "static asset logging" do
      it 'should not log static assets by default' do
        mock_app do
          enable :logging
          get("/images/something.png"){ env["sinatra.static_file"] = '/public/images/something.png'; "Foo" }
        end
        get "/images/something.png"
        assert_equal "Foo", body
        assert_match "", Padrino.logger.log.string
      end

      it 'should allow turning on static assets logging' do
        Padrino.logger.instance_eval{ @log_static = true }
        mock_app do
          enable :logging
          get("/images/something.png"){ env["sinatra.static_file"] = '/public/images/something.png'; "Foo" }
        end
        get "/images/something.png"
        assert_equal "Foo", body
        assert_match /GET/, Padrino.logger.log.string
        Padrino.logger.instance_eval{ @log_static = false }
      end
    end

    describe "health-check requests logging" do
      def access_to_mock_app
        mock_app do
          enable :logging
          get("/"){ "Foo" }
        end
        get "/"
      end

      it 'should output under debug level' do
        Padrino.logger.instance_eval{ @level = Padrino::Logger::Levels[:debug] }
        access_to_mock_app
        assert_match /\e\[0;36m  DEBUG\e\[0m/, Padrino.logger.log.string

        Padrino.logger.instance_eval{ @level = Padrino::Logger::Levels[:devel] }
        access_to_mock_app
        assert_match /\e\[0;36m  DEBUG\e\[0m/, Padrino.logger.log.string
      end

      it 'should not output over debug level' do
        Padrino.logger.instance_eval{ @level = Padrino::Logger::Levels[:info] }
        access_to_mock_app
        assert_equal '', Padrino.logger.log.string

        Padrino.logger.instance_eval{ @level = Padrino::Logger::Levels[:error] }
        access_to_mock_app
        assert_equal '', Padrino.logger.log.string
      end
    end
  end
end

describe "alternate logger" do
  class FancyLogger
    attr_accessor :level, :log
    def initialize(buf)
      self.log = buf
      self.level = 0
    end
    def add(level, text)
      self.log << text
    end
  end

  before do
    @save_logger = Padrino.logger
    @log = StringIO.new
    new_logger = FancyLogger.new(@log)
    new_logger.extend(Padrino::Logger::Extensions)
    capture_io { Padrino.logger = new_logger }
  end

  after do
    Padrino.logger = @save_logger
  end

  it 'should annotate the logger to support additional Padrino fancyness' do
    Padrino.logger.debug("Debug message")
    assert_match(/Debug message/, @log.string)
    Padrino.logger.exception(Exception.new 'scary message')
    assert_match(/Exception - scary message/, @log.string)
  end

  it 'should colorize log output after colorize! is called' do
    Padrino.logger.colorize!

    mock_app do
      enable :logging
      get("/"){ "Foo" }
    end
    get "/"

    assert_match /\e\[1;9m200\e\[0m OK/, @log.string
  end
end

describe "binary logger" do
  before do
    @save_logger = Padrino.logger
    @log = StringIO.new
    new_logger = Logger.new(@log)
    new_logger.formatter = proc do |_, _, _, message|
      "#{message.size}"
    end
    capture_io { Padrino.logger = new_logger }
  end

  after do
    Padrino.logger = @save_logger
  end

  it 'should not convert parameters to strings before formatting' do
    logger.info({:a => 2})
    assert_equal "1", @log.string
  end
end

describe "alternate logger: stdlib logger" do
  before do
    @log = StringIO.new
    @save_logger = Padrino.logger
    new_logger = Logger.new(@log)
    new_logger.extend(Padrino::Logger::Extensions)
    capture_io { Padrino.logger = new_logger }
  end

  after do
    Padrino.logger = @save_logger
  end

  it 'should annotate the logger to support additional Padrino fancyness' do
    Padrino.logger.debug("Debug message")
    assert_match(/Debug message/, @log.string)
  end

  it 'should colorize log output after colorize! is called' do
    Padrino.logger.colorize!

    mock_app do
      enable :logging
      get("/"){ "Foo" }
    end
    get "/"

    assert_match /\e\[1;9m200\e\[0m OK/, @log.string
  end
end

describe "options :colorize_logging" do
  def access_to_mock_app
    mock_app do
      enable :logging
      get("/"){ "Foo" }
    end
    get "/"
  end

  before do
    @save_config = Padrino::Logger::Config[:test].dup
  end

  after do
    Padrino::Logger::Config[:test] = @save_config
    Padrino::Logger.setup!
  end

  describe 'default' do
    before do
      Padrino::Logger::Config[:test][:colorize_logging] = true
      Padrino::Logger.setup!
    end

    it 'should use colorize logging' do
      Padrino::Logger.setup!

      access_to_mock_app
      assert_match /\e\[1;9m200\e\[0m OK/, Padrino.logger.log.string
    end
  end

  describe 'set value is false' do
    before do
      Padrino::Logger::Config[:test][:colorize_logging] = false
      Padrino::Logger.setup!
    end

    it 'should not use colorize logging' do
      access_to_mock_app
      assert_match /200 OK/, Padrino.logger.log.string
    end
  end
end

describe "options :source_location" do
  before do
    Padrino::Logger::Config[:test][:source_location] = true
    Padrino::Logger.setup!
  end

  def stub_root(base_path = File.expand_path("."), &block)
    callable = proc{ |*args| File.join(base_path, *args) }
    Padrino.stub(:root, callable, &block)
  end

  it 'should output source_location if :source_location is set to true' do
    stub_root { Padrino.logger.debug("hello world") }
    assert_match /\[test\/test_logger\.rb:#{__LINE__-1}\] hello world/, Padrino.logger.log.string
  end

  it 'should output source_location if file path is relative' do
    stub_message = "test/test_logger.rb:269:in `test'"
    Padrino::Logger.logger.stub(:caller, [stub_message]){ stub_root { Padrino.logger.debug("hello relative path") }}
    assert_match /\[test\/test_logger\.rb:269\] hello relative path/, Padrino.logger.log.string
  end

  it 'should not output source_location if :source_location is set to false' do
    Padrino::Logger::Config[:test][:source_location] = false
    Padrino::Logger.setup!
    stub_root { Padrino.logger.debug("hello world") }
    assert_match /hello world/, Padrino.logger.log.string
    refute_match /\[.+?\] hello world/, Padrino.logger.log.string
  end

  it 'should not output source_location unless file path is not started with Padrino.root' do
    stub_root("/unknown/path/") { Padrino.logger.debug("hello boy") }
    assert_match /hello boy/, Padrino.logger.log.string
    refute_match /\[.+?\] hello boy/, Padrino.logger.log.string
  end

  it 'should not output source_location if source file path is started with Padrino.root + vendor' do
    base_path = File.expand_path(File.dirname(__FILE__) + '/fixtures/')
    stub_message = File.expand_path(File.dirname(__FILE__) + '/fixtures/vendor/logger.rb') + ":291:in `test'"
    Padrino::Logger.logger.stub(:caller, [stub_message]) { stub_root(base_path) { Padrino.logger.debug("hello vendor") } }
    assert_match /hello vendor/, Padrino.logger.log.string
    refute_match /\[.+?\] hello vendor/, Padrino.logger.log.string
  end
end
