require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "Application" do
  before { Padrino.clear! }
  after  { remove_views }

  context 'CSRF protection' do
    context "with CSRF protection on" do
      before do
        mock_app do
          enable :sessions
          enable :protect_from_csrf
          post('/'){ 'HI' }
        end
      end

      should "not allow requests without tokens" do
        post "/"
        assert_equal 403, status
      end

      should "allow requests with correct tokens" do
        post "/", {"authenticity_token" => "a"}, 'rack.session' => {:csrf => "a"}
        assert_equal 200, status
      end

      should "not allow requests with incorrect tokens" do
        post "/", {"authenticity_token" => "a"}, 'rack.session' => {:csrf => "b"}
        assert_equal 403, status
      end
    end

    context "without CSRF protection on" do
      before do
        mock_app do
          enable :sessions
          disable :protect_from_csrf
          post('/'){ 'HI' }
        end
      end

      should "allows requests without tokens" do
        post "/"
        assert_equal 200, status
      end

      should "allow requests with correct tokens" do
        post "/", {"authenticity_token" => "a"}, 'rack.session' => {:csrf => "a"}
        assert_equal 200, status        
      end

      should "allow requests with incorrect tokens" do
        post "/", {"authenticity_token" => "a"}, 'rack.session' => {:csrf => "b"}
        assert_equal 200, status
      end
    end

    context "with optional CSRF protection" do
      before do
        mock_app do
          enable :sessions
          enable :protect_from_csrf
          enable :allow_disabled_csrf
          post('/on') { 'HI' }
          post('/off', :csrf_protection => false) { 'HI' }
        end
      end

      should "allow access to routes with csrf_protection off" do
        post "/off"
        assert_equal 200, status
      end

      should "not allow access to routes with csrf_protection on" do
        post "/on"
        assert_equal 403, status
        assert_equal 'Forbidden', body
      end
    end

    context "with :except option that is using Proc" do
      before do
        mock_app do
          enable :sessions
          set :protect_from_csrf, :except => proc{|env| ["/", "/foo"].any?{|path| path == env['PATH_INFO'] }}
          post("/") { "Hello" }
          post("/foo") { "Hello, foo" }
          post("/bar") { "Hello, bar" }
        end
      end

      should "allow ignoring CSRF protection on specific routes" do
        post "/"
        assert_equal 200, status
        post "/foo"
        assert_equal 200, status
        post "/bar"
        assert_equal 403, status
      end
    end

    context "with :except option that is using String and Regexp" do
      before do
        mock_app do
          enable :sessions
          set :protect_from_csrf, :except => ["/a", %r{^/a.c$}]
          post("/a") { "a" }
          post("/abc") { "abc" }
          post("/foo") { "foo" }
        end
      end

      should "allow ignoring CSRF protection on specific routes" do
        post "/a"
        assert_equal 200, status
        post "/abc"
        assert_equal 200, status
        post "/foo"
        assert_equal 403, status
      end
    end

    context "with custom protection options" do
      before do
        mock_app do
          enable :sessions
          set :protect_from_csrf, :authenticity_param => 'foobar', :message => 'sucker!'
          post("/a") { "a" }
        end
      end

      should "allow configuring protection options" do
        post "/a", {"foobar" => "a"}, 'rack.session' => {:csrf => "a"}
        assert_equal 200, status
      end

      should "allow configuring message" do
        post "/a"
        assert_equal 403, status
        assert_equal 'sucker!', body
      end
    end

    context "with middleware" do
      before do
        class Middleware < Sinatra::Base
          post("/middleware") { "Hello, middleware" }
          post("/dummy") { "Hello, dummy" }
        end
        mock_app do
          enable :sessions
          set :protect_from_csrf, :except => proc{|env| ["/", "/middleware"].any?{|path| path == env['PATH_INFO'] }}
          use Middleware
          post("/") { "Hello" }
        end
      end

      should "allow ignoring CSRF protection on specific routes of middleware" do
        post "/"
        assert_equal 200, status
        post "/middleware"
        assert_equal 200, status
        post "/dummy"
        assert_equal 403, status
      end
    end

    context "with standard report layout" do
      before do
        mock_app do
          enable :sessions
          set :protect_from_csrf, :message => 'sucker!'
          enable :report_csrf_failure
          post("/a") { "a" }
          error 403 do
            halt 406, 'please, do not hack'
          end
        end
      end

      should "allow configuring protection options" do
        post "/a"
        assert_equal 406, status
        assert_equal 'please, do not hack', body
      end
    end
  end
end
