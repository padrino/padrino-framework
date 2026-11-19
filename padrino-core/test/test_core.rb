require_relative 'helper'
require 'open3'
require 'tmpdir'

describe 'Core' do
  def setup
    Padrino.clear!
  end

  describe 'for core functionality' do
    it 'should check some global methods' do
      assert_respond_to Padrino, :root
      assert_respond_to Padrino, :env
      assert_respond_to Padrino, :application
      assert_respond_to Padrino, :set_encoding
      assert_respond_to Padrino, :load!
      assert_respond_to Padrino, :reload!
      assert_respond_to Padrino, :version
      assert_respond_to Padrino, :configure_apps
    end

    it 'should validate global helpers' do
      assert_equal :test, Padrino.env
      assert_match(%r{/test}, Padrino.root)
      assert Padrino.version
    end

    it 'should raise application error if I instantiate a new padrino application without mounted apps' do
      text = capture_io { Padrino.application }
      assert_match(/No apps are mounted/, text.to_s)
    end

    it 'should check before/after padrino load hooks' do
      Padrino.before_load { @_foo  = 1 }
      Padrino.after_load  { @_foo += 1 }
      Padrino.load!
      assert_equal 1, Padrino.before_load.size
      assert_equal 1, Padrino.after_load.size
      assert_equal 2, @_foo
    end

    it 'should add middlewares in front if specified' do
      test = Class.new do
        def initialize(app)
          @app = app
        end

        def call(env)
          status, headers, body = @app.call(env)
          headers['Middleware-Called'] = 'yes'
          [status, headers, body]
        end
      end

      class Foo < Padrino::Application; end

      Padrino.use(test)
      Padrino.mount(Foo).to('/')

      res = Rack::MockRequest.new(Padrino.application).get('/')
      assert_equal 'yes', res['Middleware-Called']
    end

    it 'should properly set default options' do
      mock_app do
        default :foo, :bar
        default :zoo, :baz
        set :foo, :bam
        set :moo, :bam
        default :moo, :ban
      end
      assert_equal @app.settings.foo, :bam
      assert_equal @app.settings.zoo, :baz
      assert_equal @app.settings.moo, :bam
    end

    it 'should return a friendly 500' do
      mock_app do
        enable :show_exceptions
        get(:index) { raise StandardError }
      end

      get '/'
      assert_equal 500, status
      assert_includes body, 'StandardError'
      assert_includes body, '<code>show_exceptions</code> setting'
    end
  end

  describe 'for deprecated shims' do
    def setup
      super
      @warned = Padrino::Utils.instance_variable_get(:@warned_deprecations)
      Padrino::Utils.instance_variable_set(:@warned_deprecations, nil)
    end

    def teardown
      Padrino::Utils.instance_variable_set(:@warned_deprecations, @warned)
    end

    # Runs script in a new process, as PADRINO_ENV is read when padrino-core loads, and returns
    # the last line it prints (the Gemfile may print first) and its stderr.
    def run_script(script)
      Dir.mktmpdir do |dir|
        env = { 'BUNDLE_GEMFILE' => File.expand_path('../../Gemfile', __dir__) }
        lib = File.expand_path('../lib', __dir__)
        out, err, status = Open3.capture3(env, RbConfig.ruby, '-rbundler/setup', '-I', lib, '-e', script, chdir: dir)
        assert status.success?, err
        [out.lines.last, err]
      end
    end

    it 'should warn once that Padrino.set_encoding is removed in Padrino 1.0, naming the first call, and return nil' do
      _out, err = capture_io do
        assert_nil Padrino.set_encoding
        assert_nil Padrino.set_encoding
      end
      assert_equal 1, err.scan('Padrino.set_encoding is deprecated').size, err
      assert_includes err, "will be removed in Padrino 1.0. It does nothing, as Padrino no longer manages Ruby default encodings: remove the call (first used at #{__FILE__}:#{__LINE__ - 4})."
    end

    it 'should warn about Padrino.set_encoding while warnings are off and without a caller' do
      verbose = $VERBOSE
      $VERBOSE = nil
      _out, err = capture_io { assert_nil Fiber.new(&Padrino.method(:set_encoding)).resume }
      assert_includes err, 'Padrino.set_encoding is deprecated'
    ensure
      $VERBOSE = verbose
    end

    it 'should warn once that the default images_path is removed in Padrino 1.0, naming the first use' do
      mock_app
      _out, err = capture_io do
        assert_equal File.join(@app.public_folder, 'images'), @app.images_path
        assert @app.images_path?
      end
      assert_equal 1, err.scan('The images_path setting is deprecated').size, err
      assert_includes err, "will be removed in Padrino 1.0. Use File.join(settings.public_folder, 'images') instead, or set :images_path yourself (first used at #{__FILE__}:#{__LINE__ - 4})."
    end

    it 'should name the caller of images_path? as the first use of images_path' do
      mock_app
      _out, err = capture_io { @app.images_path? }
      assert_includes err, "(first used at #{__FILE__}:#{__LINE__ - 1})"
    end

    it 'should not warn about an images_path the app sets itself' do
      mock_app { set :images_path, 'pictures' }
      _out, err = capture_io { assert_equal 'pictures', @app.images_path }
      refute_includes err, 'images_path'
    end

    it 'should copy PADRINO_ENV into RACK_ENV and warn once that it is removed in Padrino 1.0' do
      {
        "ENV['PADRINO_ENV'] = 'staging'" => 'The PADRINO_ENV environment variable is deprecated and will be removed in Padrino 1.0. Set RACK_ENV instead.',
        "PADRINO_ENV = 'staging'" => 'The PADRINO_ENV constant is deprecated and will be removed in Padrino 1.0. Remove it and set RACK_ENV instead.'
      }.each do |padrino_env, warning|
        out, err = run_script(<<~RUBY)
          ENV.delete('RACK_ENV')
          ENV.delete('PADRINO_ENV')
          #{padrino_env}
          require 'padrino-core'
          print [RACK_ENV, ENV['RACK_ENV'], ENV['PADRINO_ENV']].inspect
        RUBY
        assert_equal %w[staging staging staging].inspect, out
        assert_equal 1, err.scan('PADRINO_ENV').size, err
        assert_includes err, warning
      end
    end
  end
end
