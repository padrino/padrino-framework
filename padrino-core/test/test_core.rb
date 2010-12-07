require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestCore < Test::Unit::TestCase
  def teardown
    Padrino.clear_middlewares!
  end
  
  context 'for core functionality' do
    
    should 'check some global methods' do
      assert_respond_to Padrino, :root
      assert_respond_to Padrino, :env
      assert_respond_to Padrino, :application
      assert_respond_to Padrino, :set_encoding
      assert_respond_to Padrino, :load!
      assert_respond_to Padrino, :reload!
      assert_respond_to Padrino, :version
      assert_respond_to Padrino, :bundle
    end

    should 'validate global helpers' do
      assert_equal :test, Padrino.env
      assert_match /\/test/, Padrino.root
      assert_equal nil, Padrino.bundle
      assert_not_nil Padrino.version
    end

    should 'set correct utf-8 encoding' do
      Padrino.set_encoding
      if RUBY_VERSION <'1.9'
        assert_equal 'UTF8', $KCODE
      end
    end

    should 'have load paths' do
      assert_equal [Padrino.root('lib'), Padrino.root('models'), Padrino.root('shared')], Padrino.load_paths
    end

    should 'raise application error if I instantiate a new padrino application without mounted apps' do
      Padrino.mounted_apps.clear
      assert_raise(Padrino::ApplicationLoadError) { Padrino.application.new }
    end
    
    should "add middlewares in front if specified" do
      test = Class.new {
        def initialize(app)
          @app = app
        end

        def call(env)
          status, headers, body = @app.call(env)
          headers["Middleware-Called"] = "yes"
          return status, headers, body 
        end
      }

      Padrino.middlewares.use(test)
      
      res = Rack::MockRequest.new(Padrino.application).get("/")
      assert_equal "yes", res["Middleware-Called"]
    end
  end
end