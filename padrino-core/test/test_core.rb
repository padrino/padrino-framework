require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "Core" do
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
      assert_match /\/test/, Padrino.root
      assert Padrino.version
    end

    it 'should raise application error if I instantiate a new padrino application without mounted apps' do
      text = capture_io { Padrino.application }
      assert_match /No apps are mounted/, text.to_s
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

      class Foo < Padrino::Application; end

      Padrino.use(test)
      Padrino.mount(Foo).to("/")

      res = Rack::MockRequest.new(Padrino.application).get("/")
      assert_equal "yes", res["Middleware-Called"]
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
        get(:index){ raise StandardError }
      end

      get "/"
      assert_equal 500, status
      assert body.include?("StandardError")
      assert body.include?("<code>show_exceptions</code> setting")
    end
  end
end
