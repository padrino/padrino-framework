require_relative 'helper'

describe 'Application' do
  before { Padrino.clear! }

  describe 'CSRF protection' do
    describe 'with CSRF protection on' do
      before do
        @token =
          begin
            Rack::Protection::AuthenticityToken.random_token
          rescue StandardError
            'a_token'
          end

        mock_app do
          enable :sessions
          enable :protect_from_csrf
          post('/') { 'HI' }
        end
      end

      it 'should not allow requests without tokens' do
        post '/'
        assert_equal 403, status
      end

      it 'should allow requests with correct tokens' do
        post '/', { 'authenticity_token' => @token }, 'rack.session' => { csrf: @token }
        assert_equal 200, status
      end

      it 'should not allow requests with incorrect tokens' do
        post '/', { 'authenticity_token' => 'b' }, 'rack.session' => { csrf: @token }
        assert_equal 403, status
      end

      it 'should allow requests with correct X-CSRF-TOKEN' do
        post '/', {}, 'rack.session' => { csrf: @token }, 'HTTP_X_CSRF_TOKEN' => @token
        assert_equal 200, status
      end

      it 'should not allow requests with incorrect X-CSRF-TOKEN' do
        post '/', {}, 'rack.session' => { csrf: @token }, 'HTTP_X_CSRF_TOKEN' => 'b'
        assert_equal 403, status
      end
    end

    describe 'without CSRF protection on' do
      before do
        mock_app do
          enable :sessions
          disable :protect_from_csrf
          post('/') { 'HI' }
        end
      end

      it 'should allows requests without tokens' do
        post '/'
        assert_equal 200, status
      end

      it 'should allow requests with correct tokens' do
        post '/', { 'authenticity_token' => 'a' }, 'rack.session' => { csrf: 'a' }
        assert_equal 200, status
      end

      it 'should allow requests with incorrect tokens' do
        post '/', { 'authenticity_token' => 'a' }, 'rack.session' => { csrf: 'b' }
        assert_equal 200, status
      end

      it 'should allow requests with correct X-CSRF-TOKEN' do
        post '/', {}, 'rack.session' => { csrf: 'a' }, 'HTTP_X_CSRF_TOKEN' => 'a'
        assert_equal 200, status
      end

      it 'should allow requests with incorrect X-CSRF-TOKEN' do
        post '/', {}, 'rack.session' => { csrf: 'a' }, 'HTTP_X_CSRF_TOKEN' => 'b'
        assert_equal 200, status
      end
    end

    describe 'with optional CSRF protection' do
      before do
        mock_app do
          enable :sessions
          enable :protect_from_csrf
          enable :allow_disabled_csrf
          post('/on') { 'HI' }
          post('/off', csrf_protection: false) { 'HI' }
        end
      end

      it 'should allow access to routes with csrf_protection off' do
        post '/off'
        assert_equal 200, status
      end

      it 'should not allow access to routes with csrf_protection on' do
        post '/on'
        assert_equal 403, status
        assert_equal 'Forbidden', body
      end
    end

    describe 'with :except option that is using Proc' do
      before do
        mock_app do
          enable :sessions
          set :protect_from_csrf, except: proc { |env| ['/', '/foo'].any? { |path| path == env['PATH_INFO'] } }
          post('/') { 'Hello' }
          post('/foo') { 'Hello, foo' }
          post('/bar') { 'Hello, bar' }
        end
      end

      it 'should allow ignoring CSRF protection on specific routes' do
        post '/'
        assert_equal 200, status
        post '/foo'
        assert_equal 200, status
        post '/bar'
        assert_equal 403, status
      end
    end

    describe 'with :except option that is using String and Regexp' do
      before do
        mock_app do
          enable :sessions
          set :protect_from_csrf, except: ['/a', %r{^/a.c$}]
          post('/a') { 'a' }
          post('/abc') { 'abc' }
          post('/foo') { 'foo' }
        end
      end

      it 'should allow ignoring CSRF protection on specific routes' do
        post '/a'
        assert_equal 200, status
        post '/abc'
        assert_equal 200, status
        post '/foo'
        assert_equal 403, status
      end
    end

    describe 'with :except option and an encoded path' do
      before do
        mock_app do
          enable :sessions
          set :protect_from_csrf, except: ['/hook', %r{\A/(?!admin)}]
          post('/hook') { 'hook' }
          post('/admin') { 'admin' }
        end
      end

      it 'should compare the path the router matches' do
        post '/hook'
        assert_equal 200, status
        post '/%68ook'
        assert_equal 200, status
        post '/admin'
        assert_equal 403, status
        post '/%61dmin'
        assert_equal 403, status
      end

      it 'should stay on for a path with a newline' do
        mock_app do
          enable :sessions
          set :protect_from_csrf, except: [%r{^/api/}, "/hook\nx"]
          post('/:tenant/api/:id') { 'tenant' }
          post('/api/x') { 'api' }
          post('/hook:rest') { 'hook' }
        end
        post '/api/x'
        assert_equal 200, status
        post '/acme%0A/api/b'
        assert_equal 403, status
        post '/hook%0Ax'
        assert_equal 403, status
      end

      it 'should not raise without a path' do
        env = Rack::MockRequest.env_for('/')
        env.delete('PATH_INFO')
        token = Padrino::AuthenticityToken.new(->(_env) { [200, {}, []] }, except: ['/a'])
        refute token.send(:except?, env)
      end
    end

    describe 'with :except option on every form of a path' do
      def mock_anchored_app(*except)
        mock_app do
          enable :sessions
          set :protect_from_csrf, except: except
          post('/admin(.:format)?') { 'admin' }
          post('/other(.:format)?') { 'other' }
          post('/') { 'root' }
        end
      end

      %w[/admin /%61dmin /admin/ /%61dmin/ /admin.json /admin%2Ejson /admin.json/ /admin.a.b].each do |path|
        it "should stay on for #{path}" do
          mock_anchored_app('/hook', %r{\A/(?!admin\z)})
          post path
          assert_equal 403, status
        end
      end

      %w[/other /other/ /other.json /%6Fther.json].each do |path|
        it "should stay off for #{path}" do
          mock_anchored_app('/hook', %r{\A/(?!admin\z)})
          post path
          assert_equal 200, status
        end
      end

      it 'should stay on for a suffix of a dotted name' do
        mock_app do
          enable :sessions
          set :protect_from_csrf, except: [%r{\A/(?!admin\.v1\z)}]
          post('/admin.v1(.:format)?') { 'admin' }
        end
        post '/admin.v1.json'
        assert_equal 403, status
      end

      it 'should keep exact String entries' do
        mock_app do
          enable :sessions
          set :protect_from_csrf, except: ['/hook', '/', '/feed.json']
          post('/hook') { 'hook' }
          post('/feed.json') { 'feed' }
          post('/') { 'root' }
        end
        %w[/hook / /feed.json].each do |path|
          post path
          assert_equal 200, status, path
        end
        post '/hook/'
        assert_equal 403, status
      end

      it 'should take the forms of a path from different entries' do
        mock_app do
          enable :sessions
          set :protect_from_csrf, except: ['/hook/', '/hook']
          post('/hook') { 'hook' }
        end
        post '/hook/'
        assert_equal 200, status
      end

      %w[/api/.json /api/.json/ /api// /api/].each do |path|
        it "should stay on for #{path} with a slash in the Regexp" do
          mock_app do
            enable :sessions
            set :protect_from_csrf, except: [%r{^/api/}]
            post('/api/?', provides: :any) { 'api' }
          end
          post path
          assert_equal 403, status
        end
      end

      it 'should keep String entries written with a trailing slash' do
        mock_app do
          enable :sessions
          set :protect_from_csrf, except: ['/api/', '/hook/']
          post('/api/?') { 'api' }
          post('/hook/?') { 'hook' }
        end
        %w[/api/ /hook/ /%68ook/].each do |path|
          post path
          assert_equal 200, status, path
        end
        post '/hook'
        assert_equal 403, status
      end

      it 'should exempt only what a String entry with an encoded slash names' do
        mock_app do
          enable :sessions
          set :protect_from_csrf, except: ['/a%2Fb']
          post('/*rest') { 'rest' }
        end
        post '/a%2Fb'
        assert_equal 403, status
        post '/a/b'
        assert_equal 403, status
      end

      it 'should take a path from both of its decoded forms' do
        mock_app do
          enable :sessions
          set :protect_from_csrf, except: ['/a%2Fb', '/a/b']
          post('/*rest') { 'rest' }
        end
        post '/a%2Fb'
        assert_equal 200, status
      end

      it 'should strip a dot suffix from the last segment only' do
        mock_app do
          enable :sessions
          set :protect_from_csrf, except: [%r{\A/v1\.2/}]
          post('/v1.2/hook') { 'hook' }
          post('/v1.2/hook.json') { 'hook' }
        end
        %w[/v1.2/hook /v1.2/hook.json].each do |path|
          post path
          assert_equal 200, status, path
        end
      end

      it 'should stay on for a long path of dots' do
        mock_app do
          enable :sessions
          set :protect_from_csrf, except: ['/hook', %r{\A/(?!admin\z)}]
          post('/:name') { 'name' }
        end
        post "/#{'.' * 80_000}"
        assert_equal 403, status
        post "/admin#{'.x' * 40_000}"
        assert_equal 403, status
      end

      it 'should keep a String entry for a path of many dots' do
        path = "/#{(['a'] * 40).join('.')}"
        mock_app do
          enable :sessions
          set :protect_from_csrf, except: [path]
          post('/:name') { 'name' }
        end
        post path
        assert_equal 200, status
      end

      it 'should exempt a path with a few dots' do
        mock_app do
          enable :sessions
          set :protect_from_csrf, except: [%r{\A/a}]
          post('/:name') { 'name' }
        end
        post "/a#{'.a' * 15}"
        assert_equal 200, status
      end

      it 'should keep a Regexp prefix on a path with a dot' do
        mock_app do
          enable :sessions
          set :protect_from_csrf, except: [%r{\A/webhooks/}]
          post('/webhooks/stripe.json') { 'stripe' }
        end
        post '/webhooks/stripe.json'
        assert_equal 200, status
      end

      it 'should stay on for a Regexp that needs the dot suffix' do
        mock_app do
          enable :sessions
          set :protect_from_csrf, except: [/\.json\z/]
          post('/feed.json') { 'feed' }
        end
        post '/feed.json'
        assert_equal 403, status
      end
    end

    describe 'with custom protection options' do
      before do
        @token =
          begin
            Rack::Protection::AuthenticityToken.random_token
          rescue StandardError
            'a_token'
          end

        mock_app do
          enable :sessions
          set :protect_from_csrf, authenticity_param: 'foobar', message: 'sucker!'
          post('/a') { 'a' }
        end
      end

      it 'should allow configuring protection options' do
        post '/a', { 'foobar' => @token }, 'rack.session' => { csrf: @token }
        assert_equal 200, status
      end

      it 'should allow configuring message' do
        post '/a'
        assert_equal 403, status
        assert_equal 'sucker!', body
      end
    end

    describe 'with middleware' do
      before do
        class Middleware < Sinatra::Base
          post('/middleware') { 'Hello, middleware' }
          post('/dummy') { 'Hello, dummy' }
        end
        mock_app do
          enable :sessions
          set :protect_from_csrf, except: proc { |env| ['/', '/middleware'].any? { |path| path == env['PATH_INFO'] } }
          use Middleware
          post('/') { 'Hello' }
        end
      end

      it 'should allow ignoring CSRF protection on specific routes of middleware' do
        post '/'
        assert_equal 200, status
        post '/middleware'
        assert_equal 200, status
        post '/dummy'
        assert_equal 403, status
      end
    end

    describe 'with standard report layout' do
      before do
        mock_app do
          enable :sessions
          set :protect_from_csrf, message: 'sucker!'
          enable :report_csrf_failure
          post('/a') { 'a' }
          error 403 do
            halt 406, 'please, do not hack'
          end
        end
      end

      it 'should allow configuring protection options' do
        post '/a'
        assert_equal 406, status
        assert_equal 'please, do not hack', body
      end
    end
  end
end
