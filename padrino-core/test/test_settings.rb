require File.expand_path('../helper', __FILE__)

describe 'Settings' do

  before do
    @application = Padrino.new
    @application.set :environment => :foo, :app_file => nil
  end

  it 'sets settings to literal values' do
    @application.set(:foo, 'bar')
    assert @application.respond_to?(:foo)
    assert_equal 'bar', @application.foo
  end

  it 'sets settings to Procs' do
    @application.set(:foo, Proc.new { 'baz' })
    assert @application.respond_to?(:foo)
    assert_equal 'baz', @application.foo
  end

  it 'sets settings using a block' do
    @application.set(:foo){ 'baz' }
    assert @application.respond_to?(:foo)
    assert_equal 'baz', @application.foo
  end

  it 'raises an error with a value and a block' do
    assert_raises ArgumentError do
      @application.set(:fiz, 'boom!'){ 'baz' }
    end
    assert !@application.respond_to?(:fiz)
  end

  it 'raises an error without value and block' do
    assert_raises(ArgumentError) { @application.set(:fiz) }
    assert !@application.respond_to?(:fiz)
  end

  it 'allows setting a value to the app class' do
    @application.set :base, @application
    assert @application.respond_to?(:base)
    assert_equal @application, @application.base
  end

  it 'raises an error with the app class as value and a block' do
    assert_raises ArgumentError do
      @application.set(:fiz, @application) { 'baz' }
    end
    assert !@application.respond_to?(:fiz)
  end

  it "sets multiple settings with a Hash" do
    @application.set :foo => 1234,
        :bar => 'Hello World',
        :baz => Proc.new { 'bizzle' }
    assert_equal 1234, @application.foo
    assert_equal 'Hello World', @application.bar
    assert_equal 'bizzle', @application.baz
  end

  it 'sets multiple settings using #each' do
    @application.set [["foo", "bar"]]
    assert_equal "bar", @application.foo
  end

  it 'inherits settings methods when subclassed' do
    @application.set :foo, 'bar'
    @application.set :biz, Proc.new { 'baz' }

    sub = Class.new(@application)
    assert sub.respond_to?(:foo)
    assert_equal 'bar', sub.foo
    assert sub.respond_to?(:biz)
    assert_equal 'baz', sub.biz
  end

  it 'overrides settings in subclass' do
    @application.set :foo, 'bar'
    @application.set :biz, Proc.new { 'baz' }
    sub = Class.new(@application)
    sub.set :foo, 'bling'
    assert_equal 'bling', sub.foo
    assert_equal 'bar', @application.foo
  end

  it 'creates setter methods when first defined' do
    @application.set :foo, 'bar'
    assert @application.respond_to?('foo=')
    @application.foo = 'biz'
    assert_equal 'biz', @application.foo
  end

  it 'creates predicate methods when first defined' do
    @application.set :foo, 'hello world'
    assert @application.respond_to?(:foo?)
    assert @application.foo?
    @application.set :foo, nil
    assert !@application.foo?
  end

  it 'uses existing setter methods if detected' do
    class << @application
      def foo
        @foo
      end
      def foo=(value)
        @foo = 'oops'
      end
    end

    @application.set :foo, 'bam'
    assert_equal 'oops', @application.foo
  end

  it 'merges values of multiple set calls if those are hashes' do
    @application.set :foo, :a => 1
    sub = Class.new(@application)
    sub.set :foo, :b => 2
    assert_equal({:a => 1, :b => 2}, sub.foo)
  end

  it 'merging does not affect the superclass' do
    @application.set :foo, :a => 1
    sub = Class.new(@application)
    sub.set :foo, :b => 2
    assert_equal({:a => 1}, @application.foo)
  end

  it 'is possible to change a value from a hash to something else' do
    @application.set :foo, :a => 1
    @application.set :foo, :bar
    assert_equal(:bar, @application.foo)
  end

  it 'merges values with values of the superclass if those are hashes' do
    @application.set :foo, :a => 1
    @application.set :foo, :b => 2
    assert_equal({:a => 1, :b => 2}, @application.foo)
  end

  it "sets multiple settings to true with #enable" do
    @application.enable :sessions, :foo, :bar
    assert @application.sessions
    assert @application.foo
    assert @application.bar
  end

  it "sets multiple settings to false with #disable" do
    @application.disable :sessions, :foo, :bar
    assert !@application.sessions
    assert !@application.foo
    assert !@application.bar
  end

  it 'is accessible from instances via #settings' do
    assert_equal :foo, @application.new!.settings.environment
  end

  it 'is accessible from class via #settings' do
    assert_equal :foo, @application.settings.environment
  end

  describe 'methodoverride' do
    it 'is enabled on Application' do
      assert @application.method_override?
    end

    it 'enables MethodOverride middleware' do
      @application.set :method_override, true
      @application.put('/') { 'okay' }
      @app = @application
      post '/', {'_method'=>'PUT'}, {}
      assert_equal 200, status
      assert_equal 'okay', body
    end
  end

  describe 'raise_errors' do
    it 'is enabled on Base only in test' do
      assert ! @application.raise_errors?

      @application.set(:environment, :test)
      assert @application.raise_errors?
    end

    it 'is enabled on Application only in test' do
      assert ! @application.raise_errors?

      @application.set(:environment, :test)
      assert @application.raise_errors?
    end
  end

  describe 'show_exceptions' do
    it 'is disabled on Base except under development' do
      assert ! @application.show_exceptions?
      @application.environment = :development
      assert @application.show_exceptions?
    end

    it 'is disabled on Application except in development' do
      assert ! @application.show_exceptions?

      @application.set(:environment, :development)
      assert @application.show_exceptions?
    end

    it 'returns a friendly 500' do
      mock_app {
        enable :show_exceptions

        get '/' do
          raise StandardError
        end
      }

      get '/'
      assert_equal 500, status
      assert body.include?("StandardError")
      assert body.include?("<code>show_exceptions</code> setting")
    end

    it 'does not override app-specified error handling when set to :after_handler' do
      ran = false
      mock_app do
        set :show_exceptions, :after_handler
        error(RuntimeError) { ran = true }
        get('/') { raise RuntimeError }
      end

      get '/'
      assert_equal 500, status
      assert ran
    end

    it 'does catch any other exceptions when set to :after_handler' do
      ran = false
      mock_app do
        set :show_exceptions, :after_handler
        error(RuntimeError) { ran = true }
        get('/') { raise ArgumentError }
      end

      get '/'
      assert_equal 500, status
      assert !ran
    end
  end

  describe 'sessions' do
    it 'is disabled on Base' do
      assert ! @application.sessions?
    end

    it 'is disabled on Application' do
      assert ! @application.sessions?
    end
  end

  describe 'logging' do
    it 'is enabled on Application except in test environment' do
      assert ! @application.logging?

      @application.set :environment, :development
      assert @application.logging
    end
  end

  describe 'static' do
    it 'is disabled on Base by default' do
      assert ! @application.static?
    end

    it 'is enabled on Base when public_folder is set and exists' do
      @application.set :environment, :development
      @application.set :public_folder, File.dirname(__FILE__)
      assert @application.static?
    end

    it 'is enabled on Base when root is set and root/public_folder exists' do
      @application.set :environment, :development
      @application.set :root, File.dirname(__FILE__)
      assert @application.static?
    end

    it 'is disabled on Application by default' do
      assert ! @application.static?
    end

    it 'is enabled on Application when public_folder is set and exists' do
      @application.set :environment, :development
      @application.set :public_folder, File.dirname(__FILE__)
      assert @application.static?
    end

    it 'is enabled on Application when root is set and root/public_folder exists' do
      @application.set :environment, :development
      @application.set :root, File.dirname(__FILE__)
      assert @application.static?
    end

    it 'is possible to use Module#public' do
      @application.send(:define_method, :foo) { }
      @application.send(:private, :foo)
      assert !@application.public_method_defined?(:foo)
      @application.send(:public, :foo)
      assert @application.public_method_defined?(:foo)
    end

    it 'is possible to use the keyword public in a padrino app' do
      app = Padrino.new do
        private
        def priv; end
        public
        def pub; end
      end
      assert !app.public_method_defined?(:priv)
      assert app.public_method_defined?(:pub)
    end
  end

  describe 'app_file' do
    it 'defaults to the file' do
      assert_equal __FILE__, Padrino.new.app_file
    end

    it 'defaults to the file subclassing' do
      assert_equal __FILE__, Class.new(Padrino::Application).app_file
    end
  end

  describe 'root' do
    it 'is nil if app_file is not set' do
      assert @application.root.nil?
      assert @application.root.nil?
    end

    it 'is equal to the expanded basename of app_file' do
      @application.app_file = __FILE__
      assert_equal File.expand_path(File.dirname(__FILE__)), @application.root

      @application.app_file = __FILE__
      assert_equal File.expand_path(File.dirname(__FILE__)), @application.root
    end
  end

  describe 'views' do
    it 'is nil if root is not set' do
      assert @application.views.nil?
      assert @application.views.nil?
    end

    it 'is set to root joined with views/' do
      @application.root = File.dirname(__FILE__)
      assert_equal File.dirname(__FILE__) + "/views", @application.views

      @application.root = File.dirname(__FILE__)
      assert_equal File.dirname(__FILE__) + "/views", @application.views
    end
  end

  describe 'public_folder' do
    it 'is nil if root is not set' do
      assert @application.public_folder.nil?
      assert @application.public_folder.nil?
    end

    it 'is set to root joined with public/' do
      @application.root = File.dirname(__FILE__)
      assert_equal File.dirname(__FILE__) + "/public", @application.public_folder

      @application.root = File.dirname(__FILE__)
      assert_equal File.dirname(__FILE__) + "/public", @application.public_folder
    end
  end

  describe 'lock' do
    it 'is disabled by default' do
      assert ! @application.lock?
      assert ! @application.lock?
    end
  end
end
