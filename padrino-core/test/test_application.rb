require File.expand_path(File.dirname(__FILE__) + '/helper')

class PadrinoPristine < Padrino::Application; end
class PadrinoTestApp  < Padrino::Application; end
class PadrinoTestApp2 < Padrino::Application; end

describe "Application" do
  before { Padrino.clear! }

  describe 'for application functionality' do

    it 'should check default options' do
      assert File.identical?(__FILE__, PadrinoPristine.app_file)
      assert_equal :padrino_pristine, PadrinoPristine.app_name
      assert_equal :test, PadrinoPristine.environment
      assert_equal Padrino.root('views'), PadrinoPristine.views
      assert  PadrinoPristine.raise_errors
      assert !PadrinoPristine.logging
      assert !PadrinoPristine.sessions
      assert !PadrinoPristine.dump_errors
      assert !PadrinoPristine.show_exceptions
      assert  PadrinoPristine.raise_errors
      assert !Padrino.configure_apps
    end

    it 'should check padrino specific options' do
      assert !PadrinoPristine.instance_variable_get(:@_configured)
      PadrinoPristine.send(:setup_application!)
      assert_equal :padrino_pristine, PadrinoPristine.app_name
      assert_equal 'StandardFormBuilder', PadrinoPristine.default_builder
      assert  PadrinoPristine.instance_variable_get(:@_configured)
      assert !PadrinoPristine.reload?
    end

    it 'should set global project settings' do
      Padrino.configure_apps { enable :sessions; set :foo, "bar" }
      PadrinoTestApp.send(:default_configuration!)
      PadrinoTestApp2.send(:default_configuration!)
      assert PadrinoTestApp.sessions, "should have sessions enabled"
      assert_equal "bar", PadrinoTestApp.settings.foo, "should have foo assigned"
      assert_equal PadrinoTestApp.session_secret, PadrinoTestApp2.session_secret
    end

    it 'should be able to configure_apps multiple times' do
      Padrino.configure_apps { set :foo1, "bar" }
      Padrino.configure_apps { set :foo1, "bam" }
      Padrino.configure_apps { set :foo2, "baz" }
      PadrinoTestApp.send(:default_configuration!)
      assert_equal "bam", PadrinoTestApp.settings.foo1, "should have foo1 assigned to bam"
      assert_equal "baz", PadrinoTestApp.settings.foo2, "should have foo2 assigned to baz"
    end

    it 'should have shared sessions accessible in project' do
      Padrino.configure_apps { enable :sessions; set :session_secret, PadrinoTestApp2.session_secret }
      Padrino.mount("PadrinoTestApp").to("/write")
      Padrino.mount("PadrinoTestApp2").to("/read")
      PadrinoTestApp.send :default_configuration!
      PadrinoTestApp.get('/') { session[:foo] = "shared" }
      PadrinoTestApp2.send(:default_configuration!)
      PadrinoTestApp2.get('/') { session[:foo] }
      @app = Padrino.application
      get '/write'
      get '/read'
      assert_equal 'shared', body
    end

    it 'should be able to execute the register keyword inside the configure_apps block' do
      Asdf = Module.new
      Padrino.configure_apps { register Asdf }
      class GodFather < Padrino::Application; end
      assert_includes GodFather.extensions, Asdf
    end

    it 'should able to set custome session management' do
      class PadrinoTestApp3 < Padrino::Application
        set :sessions, :use => Rack::Session::Pool
      end
      Padrino.mount("PadrinoTestApp3").to("/")
      PadrinoTestApp3.get('/write') { session[:foo] = "pool" }
      PadrinoTestApp3.get('/read') { session[:foo] }
      @app = Padrino.application
      get '/write'
      get '/read'
      assert_equal 'pool', body
    end

    it 'should have different session values in different session management' do
      class PadrinoTestApp4 < Padrino::Application
        enable :sessions
      end
      class PadrinoTestApp5 < Padrino::Application
        set :sessions, :use => Rack::Session::Pool
      end
      Padrino.mount("PadrinoTestApp4").to("/write")
      Padrino.mount("PadrinoTestApp5").to("/read")
      PadrinoTestApp4.get('/') { session[:foo] = "cookie" }
      PadrinoTestApp5.get('/') { session[:foo] }
      @app = Padrino.application
      get '/write'
      get '/read'
      assert_equal '', body
    end

    # compare to: test_routing: allow global provides
    it 'should set content_type to nil if none can be determined' do
      mock_app do
        provides :xml

        get("/foo"){ "Foo in #{content_type.inspect}" }
        get("/bar"){ "Foo in #{content_type.inspect}" }
      end

      get '/foo', {}, { 'HTTP_ACCEPT' => 'application/xml' }
      assert_equal 'Foo in :xml', body
      get '/foo'
      assert_equal 'Foo in :xml', body

      get '/bar', {}, { 'HTTP_ACCEPT' => 'application/xml' }
      assert_equal "Foo in nil", body
    end

    it 'should resolve views and layouts paths' do
      assert_equal Padrino.root('views')+'/users/index', PadrinoPristine.view_path('users/index')
      assert_equal Padrino.root('views')+'/layouts/app', PadrinoPristine.layout_path(:app)
    end

    describe "errors" do
      it 'should have not mapped errors on development' do
        mock_app { get('/'){ 'HI' } }
        get "/"
        assert @app.errors.empty?
      end

      it 'should have mapped errors on production' do
        mock_app { set :environment, :production; get('/'){ 'HI' } }
        get "/"
        assert_equal 1, @app.errors.size
      end

      it 'should overide errors' do
        mock_app do
          set :environment, :production
          get('/'){ raise }
          error(::Exception){ 'custom error' }
        end
        get "/"
        assert_equal 1, @app.errors.size
        assert_equal 'custom error', body
      end

      it 'should pass Routing#parent to Module#parent' do
        # see naming collision in issue #1814
        begin
          ConstTest = Class.new(Padrino::Application)
          class Module
            def parent
              :dirty
            end
          end
          assert_equal :dirty, ConstTest.parent
        ensure
          Module.instance_eval{ undef :parent }
        end
      end
    end

    describe "pre-compile routes" do
      it "should compile routes before first request if enabled the :precompile_routes option" do
        require File.expand_path(File.dirname(__FILE__) + '/fixtures/apps/precompiled_app')
        assert_instance_of Padrino::PathRouter::Compiler, PrecompiledApp::App.compiled_router.engine
        assert_instance_of Padrino::PathRouter::Compiler, PrecompiledApp::SubApp.compiled_router.engine
        assert_equal true, PrecompiledApp::App.compiled_router.engine.compiled?
        assert_equal true, PrecompiledApp::SubApp.compiled_router.engine.compiled?
        assert_equal 20, PrecompiledApp::App.compiled_router.engine.routes.length
        assert_equal 20, PrecompiledApp::SubApp.compiled_router.engine.routes.length
      end
    end

    describe 'global prerequisites' do
      after do
        Padrino::Application.prerequisites.clear
      end

      it 'should be inherited by children of Padrino::Application' do
        Padrino::Application.prerequisites << 'my_prerequisites'
        class InheritanceTest < Padrino::Application; end
        assert_includes InheritanceTest.prerequisites, 'my_prerequisites'
      end
    end
  end # application functionality
end
