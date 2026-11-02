require_relative 'helper'

describe 'Filters' do
  it 'should filters by accept header' do
    mock_app do
      get '/foo', provides: %i[xml js] do
        request.env['HTTP_ACCEPT']
      end
    end

    get '/foo', {}, { 'HTTP_ACCEPT' => 'application/xml' }
    assert ok?
    assert_equal 'application/xml', body
    assert_equal 'application/xml;charset=utf-8', response.headers['Content-Type']

    get '/foo.xml'
    assert ok?
    assert_equal 'application/xml;charset=utf-8', response.headers['Content-Type']

    get '/foo', {}, { 'HTTP_ACCEPT' => 'text/javascript' }
    assert ok?
    assert_equal 'text/javascript', body
    assert_equal 'text/javascript;charset=utf-8', response.headers['Content-Type']

    get '/foo.js'
    assert ok?
    assert_equal 'text/javascript;charset=utf-8', response.headers['Content-Type']

    get '/foo', {}, { 'HTTP_ACCEPT' => 'text/html' }
    assert_equal 406, status
  end

  it 'should allow passing & halting in before filters' do
    mock_app do
      controller do
        before { env['QUERY_STRING'] == 'secret' or pass }
        get :index do
          'secret index'
        end
      end

      controller do
        before { env['QUERY_STRING'] == 'halt' and halt 401, 'go away!' }
        get :index do
          'index'
        end
      end
    end

    get '/?secret'
    assert_equal 'secret index', body

    get '/?halt'
    assert_equal 'go away!', body
    assert_equal 401, status

    get '/'
    assert_equal 'index', body
  end

  it 'should scope filters in the given controller' do
    mock_app do
      before { @global = 'global' }
      after { @global = nil }

      controller :foo do
        before { @foo = :foo }
        after { @foo = nil }
        get('/') { [@foo, @bar, @global].compact.join(' ') }
      end

      get('/') { [@foo, @bar, @global].compact.join(' ') }

      controller :bar do
        before { @bar = :bar }
        after { @bar = nil }
        get('/') { [@foo, @bar, @global].compact.join(' ') }
      end
    end

    get '/bar'
    assert_equal 'bar global', body

    get '/foo'
    assert_equal 'foo global', body

    get '/'
    assert_equal 'global', body
  end

  it 'should be able to access params in a before filter' do
    username_from_before_filter = nil

    mock_app do
      before do
        username_from_before_filter = params[:username]
      end

      get :users, with: :username do
      end
    end
    get '/users/josh'
    assert_equal 'josh', username_from_before_filter
  end

  it 'should be able to access params normally when a before filter is specified' do
    mock_app do
      before {}
      get :index do
        params.to_json
      end
    end
    get '/?test=what'
    assert_equal '{"test":"what"}', body
  end

  it 'should be able to filter based on a path' do
    mock_app do
      before('/') { @test = "#{@test}before" }
      get :index do
        @test
      end
      get :main do
        @test
      end
    end
    get '/'
    assert_equal 'before', body
    get '/main'
    assert_equal '', body
  end

  it 'should filter by path and Regexp on the decoded path the router matches' do
    mock_app do
      before('/private') { halt 403, 'filtered' }
      before(%r{\A/secret}) { halt 403, 'filtered' }
      before("/caf\u00e9") { @test = 'cafe filter' }
      get('/private') { 'private' }
      get('/secret/:id') { 'secret' }
      get("/caf\u00e9") { @test.to_s }
      get('/:page') { "page #{params[:page]}" }
    end
    ['/private', '/%70rivate', '/priv%61te', '/secret/1', '/%73ecret/1', '/secret%ff'].each do |path|
      get path
      assert_equal [403, 'filtered'], [status, body], path
    end
    get '/caf%C3%A9'
    assert_equal 'cafe filter', body
    get '/private%2Fx'
    assert_equal 'page private/x', body
  end

  it 'should filter by path a request the router serves with a trailing slash' do
    mock_app do
      before('/private') { halt 403, 'filtered' }
      before(%r{\A/locked\z}) { halt 403, 'filtered' }
      get('/private') { 'private' }
      get('/locked') { 'locked' }
    end
    ['/private', '/private/', '/%70rivate/', '/locked', '/locked/', '/%6Cocked/'].each do |path|
      get path
      assert_equal [403, 'filtered'], [status, body], path
    end
  end

  it 'should filter by path a request whose route params decode an escape again' do
    mock_app do
      before('/files/secret') { halt 403, 'filtered' }
      get('/files/:name') { "param #{params[:name]}" }
      get('/*path') { "splat #{params[:path]}" }
    end
    ['/files%252Fsecret', '/files/%2573ecret', '/%2566iles/secret', '/files/sec%2572et'].each do |path|
      get path
      assert_equal [403, 'filtered'], [status, body], path
    end
    get '/files%25252Fsecret'
    assert_equal 'splat files%2Fsecret', body
    get '/files/%252573ecret'
    assert_equal 'param %73ecret', body
  end

  it 'should filter by path a request whose encoded slash a splat route decodes' do
    mock_app do
      before('/files/secret') { halt 403, 'filtered' }
      get('/*path') { "file #{params[:path]}" }
    end
    ['/files/secret', '/files%2Fsecret', '/files%2fsecret'].each do |path|
      get path
      assert_equal [403, 'filtered'], [status, body], path
    end
    get '/files/public'
    assert_equal 'file files/public', body
  end

  it 'should skip an except filter only for the excepted path in its decoded forms' do
    mock_app do
      before(except: '/public/page') { halt 403, 'filtered' }
      get('/public/page') { 'public' }
      get('/:name') { "name #{params[:name]}" }
    end
    ['/public/page', '/%70ublic/page'].each do |path|
      get path
      assert_equal [200, 'public'], [status, body], path
    end
    ['/public%2Fpage', '/public/page/'].each do |path|
      get path
      assert_equal [403, 'filtered'], [status, body], path
    end
  end

  it 'should skip an except filter with a Regexp only for the paths it matches in every decoded form' do
    mock_app do
      before(except: %r{\A/public/page\z}) { halt 403, 'filtered' }
      get('/public/page') { 'public' }
      get('/:name') { "name #{params[:name]}" }
    end
    ['/public/page', '/%70ublic/page'].each do |path|
      get path
      assert_equal [200, 'public'], [status, body], path
    end
    ['/public%2Fpage', '/public%252Fpage', '/public%2Fpage/', '/public/page/'].each do |path|
      get path
      assert_equal [403, 'filtered'], [status, body], path
    end
  end

  it 'should not skip an except filter for the excepted path with a trailing slash' do
    mock_app do
      before(except: '/admin') { halt 401, 'auth' }
      get(%r{/admin/}) { 'admin slash' }
      get(%r{/admin}) { 'admin' }
    end
    get '/admin'
    assert_equal [200, 'admin'], [status, body]
    get '/admin/'
    assert_equal [401, 'auth'], [status, body]
  end

  it 'should filter by path on the request path as it is when the filter runs' do
    mock_app do
      before('/old') { request.path_info = '/new' }
      before('/new') { @test = 'new filter' }
      get('/old') { @test.to_s }
    end
    get '/old'
    assert_equal 'new filter', body
  end

  it 'should be able to filter based on a symbol' do
    mock_app do
      before(:index) { @test = 'before' }
      get :index do
        @test
      end
      get :main do
        @test
      end
    end
    get '/'
    assert_equal 'before', body
    get '/main'
    assert_equal '', body
  end

  it 'should be able to filter based on a symbol for a controller' do
    mock_app do
      controller :foo do
        before(:test) { @test = 'foo' }
        get(:test) { "#{@test} response" }
      end

      controller :bar do
        before(:test) { @test = 'bar' }
        get(:test) { "#{@test} response" }
      end
    end

    get '/foo/test'
    assert_equal 'foo response', body

    get '/bar/test'
    assert_equal 'bar response', body
  end

  it 'should be able to filter based on a symbol or path' do
    mock_app do
      before(:index, '/main') { @test = 'before' }
      get :index do
        @test
      end
      get :main do
        @test
      end
    end
    get '/'
    assert_equal 'before', body
    get '/main'
    assert_equal 'before', body
  end

  it 'should be able to filter based on a symbol or regexp' do
    mock_app do
      before(:index, /main/) { @test = 'before' }
      get :index do
        @test
      end
      get :main do
        @test
      end
      get :profile do
        @test
      end
    end
    get '/'
    assert_equal 'before', body
    get '/main'
    assert_equal 'before', body
    get '/profile'
    assert_equal '', body
  end

  it 'should be able to filter excluding based on a symbol' do
    mock_app do
      before(except: :index) { @test = 'before' }
      get :index do
        @test
      end
      get :main do
        @test
      end
    end
    get '/'
    assert_equal '', body
    get '/main'
    assert_equal 'before', body
  end

  it 'should be able to filter excluding based on a symbol when specify the multiple routes and use nested controller' do
    mock_app do
      controller :test, :nested do
        before(except: %i[test1 test2]) { @long = 'long' }
        before(except: [:test1]) { @short = 'short' }
        get :test1 do
          "#{@long} #{@short} normal"
        end
        get :test2 do
          "#{@long} #{@short} normal"
        end
        get :test3 do
          "#{@long} #{@short} normal"
        end
      end
    end
    get '/test/nested/test1'
    assert_equal '  normal', body
    get '/test/nested/test2'
    assert_equal ' short normal', body
    get '/test/nested/test3'
    assert_equal 'long short normal', body
  end

  it 'should be able to filter based on a request param' do
    mock_app do
      before(agent: /IE/) { @test = 'before' }
      get :index do
        @test
      end
    end
    get '/'
    assert_equal '', body
    get '/', {}, { 'HTTP_USER_AGENT' => 'This is IE' }
    assert_equal 'before', body
  end

  it 'should be able to filter based on a symbol or path in multiple controller' do
    mock_app do
      controllers :foo do
        before(:index, '/foo/main') { @test = 'before' }
        get :index do
          @test
        end
        get :main do
          @test
        end
      end
      controllers :bar do
        before(:index, '/bar/main') { @test = 'also before' }
        get :index do
          @test
        end
        get :main do
          @test
        end
      end
    end
    get '/foo'
    assert_equal 'before', body
    get '/bar'
    assert_equal 'also before', body
    get '/foo/main'
    assert_equal 'before', body
    get '/bar/main'
    assert_equal 'also before', body
  end

  it 'should call before filters even if there was no match' do
    test = nil
    mock_app do
      before(:index, '/foo') { test = 'before' }
      get :index do
        ''
      end
    end
    get '/foo'
    assert_equal 'before', test
  end

  it 'should ensure the call of before_filter at the first time' do
    once = ''
    mock_app do
      before do
        once += 'before'
      end
      get :index do
        raise Exception, 'Oops'
      end
      post :index do
        raise Exception, 'Oops'
      end
    end

    post '/'
    assert_equal 'before', once
  end

  it 'should call before filters only once' do
    once = ''
    mock_app do
      error 500 do
        'error 500'
      end
      before do
        once += 'before'
      end
      get :index do
        raise Exception, 'Oops'
      end
    end

    get '/'
    assert_equal 'before', once
  end

  it 'should catch exceptions in before filters' do
    doodle = ''
    mock_app do
      after do
        doodle = 'Been after'
      end
      before do
        raise StandardError, 'before'
      end
      get :index do
        doodle = 'Been now'
      end
      error 500 do
        "We broke #{env['sinatra.error'].message}"
      end
    end

    get '/'
    assert_equal 'We broke before', body
    assert_equal '', doodle
  end

  it 'should catch exceptions in after filters if no exceptions caught before' do
    doodle = ''
    mock_app do
      after do
        doodle += ' and after'
        raise StandardError, 'after'
      end
      get :foo do
        doodle = 'Been now'
        raise StandardError, 'now'
      end
      get :index do
        doodle = 'Been now'
      end
      error 500 do
        "We broke #{env['sinatra.error'].message}"
      end
    end

    get '/foo'
    assert_equal 'We broke now', body
    assert_equal 'Been now', doodle

    doodle = ''
    get '/'
    assert_equal 'We broke after', body
    assert_equal 'Been now and after', doodle
  end

  it 'should trigger filters if superclass responds to :filters' do
    class FilterApp < Padrino::Application
      before { @foo = 'foo' }
    end
    mock_app FilterApp do
      get('/') { @foo }
    end
    get '/'
    assert_equal 'foo', body
  end

  describe 'on a route with a format' do
    def mock_format_app
      mock_app do
        before('/data') { halt 401, 'stopped' }
        before(%r{\A/report\z}) { halt 401, 'stopped' }
        get('/data', provides: %i[html json]) { 'open' }
        get('/report', provides: %i[html json]) { 'open' }
      end
    end

    %w[/data /data.json /%64ata.json /data%2Ejson /data.json/ /report.json].each do |path|
      it "should run for #{path}" do
        mock_format_app
        get path
        assert_equal 401, status
        assert_equal 'stopped', body
      end
    end

    it 'should cover every way a route captures a format' do
      mock_app do
        before('/data') { halt 401, 'stopped' }
        before('/e') { halt 401, 'stopped' }
        before('/f') { halt 401, 'stopped' }
        get('/data(.:format)?') { 'open' }
        get('/e.:format') { 'open' }
        get('/f(.:format)') { 'open' }
      end
      %w[/data.json /data.a.b /e.json /f.json].each do |path|
        get path
        assert_equal 401, status, path
      end
    end

    it 'should cover a format after a trailing slash' do
      mock_app do
        before('/data') { halt 401, 'stopped' }
        before(%r{\A/report\z}) { halt 401, 'stopped' }
        get('/data/?', provides: %i[html json]) { 'open' }
        get('/report/?', provides: %i[html json]) { 'open' }
      end
      %w[/data/ /data// /data/.json /data.json/ /report// /report/.json].each do |path|
        get path
        refute_equal 'open', body, path
      end
    end

    it 'should cover every trailing slash of a route without a format' do
      mock_app do
        before('/data') { halt 401, 'stopped' }
        get('/data/?') { 'open' }
        get('/data//') { 'open' }
      end
      %w[/data/ /data//].each do |path|
        get path
        assert_equal 401, status, path
      end
    end

    it 'should keep the root path after every slash is stripped' do
      mock_app do
        before('/') { halt 401, 'stopped' }
        get('/', provides: %i[html json]) { 'open' }
        get('//') { 'open' }
      end
      %w[/ // /.json].each do |path|
        get path
        assert_equal 401, status, path
      end
    end

    it 'should cover a dot left by an optional format' do
      mock_app do
        before('/data') { halt 401, 'stopped' }
        get('/data.:format?') { 'open' }
      end
      %w[/data /data. /data./ /data%2E /data.json].each do |path|
        get path
        assert_equal 401, status, path
      end
    end

    it 'should cover a format with an optional dot' do
      mock_app do
        before('/data') { halt 401, 'stopped' }
        get('/data.?:format?') { 'open' }
      end
      %w[/data /data. /datajson /data.json].each do |path|
        get path
        assert_equal 401, status, path
      end
    end

    it 'should take a format after a slash for another path' do
      mock_app do
        before('/data') { halt 401, 'stopped' }
        get('/data/:format?') { 'open' }
      end
      get '/data/json'
      assert_equal 'open', body
      get '/data/'
      assert_equal 401, status
    end

    it 'should not strip a format from the middle of a route' do
      mock_app do
        before('/x') { halt 401, 'stopped' }
        get('/x.:format/y') { 'open' }
      end
      get '/x.json/y'
      assert_equal 'open', body
    end

    it 'should keep an except filter on a path with a newline' do
      mock_app do
        before(except: %r{^/public/}) { halt 401, 'stopped' }
        get('/:tenant/public/:id') { 'open' }
        get('/public/x') { 'public' }
      end
      get '/public/x'
      assert_equal 'public', body
      get '/acme%0A/public/b'
      assert_equal 401, status
    end

    it 'should exempt only what an except filter with an encoded slash names' do
      mock_app do
        before(except: '/a%2Fb') { halt 401, 'stopped' }
        get('/*rest') { 'open' }
      end
      get '/a%2Fb'
      assert_equal 401, status
    end

    [
      ['/files/', '/files/*path', {}, '/files//'],
      ['/data/', '/data/:id?', {}, '/data//'],
      ['/a/b/', '/a/*rest', {}, '/a/b//'],
      [%r{/a/b/\z}, '/a/*rest', {}, '/a/b//'],
      ['/data/', '/data/?', { provides: :json }, '/data/.json']
    ].each do |guard, pattern, options, path|
      describe "with a guard #{guard.inspect} that ends in a slash on #{pattern}" do
        it "should run a before filter for #{path}" do
          mock_app do
            before(guard) { halt 401, 'stopped' }
            get(pattern, options) { 'open' }
          end
          get path
          assert_equal 401, status
        end

        it "should run an after filter for #{path}" do
          seen = []
          mock_app do
            after(guard) { seen << :after }
            get(pattern, options) { 'open' }
          end
          get path
          assert_equal 'open', body
          assert_equal [:after], seen
        end

        it "should apply the path and path_info options for #{path}" do
          %i[path path_info].each do |name|
            mock_app do
              before(name => guard) { halt 401, 'stopped' }
              get(pattern, options) { 'open' }
            end
            get path
            assert_equal 401, status, name
          end
        end
      end
    end

    it 'should keep a guard that ends in a slash off the path without one' do
      mock_app do
        before('/data/') { halt 401, 'stopped' }
        get('/data', provides: :json) { 'open' }
      end
      get '/data'
      assert_equal 'open', body
      get '/data/'
      assert_equal 401, status
    end

    %i[path path_info].each do |name|
      it "should not raise for invalid UTF-8 in the #{name} option" do
        mock_app do
          before(name => '/data') { halt 401, 'stopped' }
          get('/data') { 'open' }
        end
        env = Rack::MockRequest.env_for('/')
        env['PATH_INFO'] = "/data\xFF".dup.force_encoding(Encoding::UTF_8)
        assert_equal 404, @app.call(env).first
      end
    end

    it 'should not strip a suffix from a route without a format' do
      mock_app do
        before('/plain') { halt 401, 'stopped' }
        get('/plain.json') { 'plain' }
      end
      get '/plain.json'
      assert_equal 'plain', body
    end

    it 'should not strip a query string format' do
      mock_app do
        before('/plain') { halt 401, 'stopped' }
        get('/plain.json') { 'plain' }
      end
      get '/plain.json?format=json'
      assert_equal 'plain', body
    end

    it 'should keep an except filter on a path with a format' do
      mock_app do
        before(except: '/data') { halt 401, 'stopped' }
        get('/data', provides: %i[html json]) { 'open' }
        get('/other', provides: %i[html json]) { 'other' }
      end
      get '/data'
      assert_equal 'open', body
      get '/data.json'
      assert_equal 401, status
      get '/other.json'
      assert_equal 401, status
    end

    it 'should stand aside for a path an except filter names with its format' do
      mock_app do
        before(except: /\.json$/) { halt 401, 'stopped' }
        get('/feed', provides: %i[html json]) { 'open' }
      end
      get '/feed.json'
      assert_equal 'open', body
      get '/feed'
      assert_equal 401, status
    end

    it 'should apply the path and path_info options' do
      mock_app do
        before(path: '/g') { halt 401, 'stopped' }
        before(path_info: %r{\A/h\z}) { halt 401, 'stopped' }
        get('/g(.:format)') { 'open' }
        get('/h(.:format)') { 'open' }
      end
      %w[/g.json /h.json].each do |path|
        get path
        assert_equal 401, status, path
      end
    end

    it 'should apply the path and path_info options to the decoded path' do
      mock_app do
        before(path_info: %r{\A/opt\z}) { halt 401, 'stopped' }
        before(path: %r{\A/way\z}) { halt 401, 'stopped' }
        get('/opt') { 'open' }
        get('/way') { 'open' }
      end
      %w[/%6Fpt /opt/ /%77ay /way/].each do |path|
        get path
        assert_equal 401, status, path
      end
    end

    it 'should keep matching a path option written with the encoded path' do
      mock_app do
        before(path_info: '/caf%C3%A9') { halt 401, 'stopped' }
        get('/café') { 'open' }
      end
      get '/caf%C3%A9'
      assert_equal 401, status
    end

    it 'should cover the format of a mounted app on the path option' do
      mock_app do
        before(path: '/sub/foo') { halt 401, 'stopped' }
        get('/foo', provides: %i[html json]) { 'open' }
      end
      get '/foo.json', {}, 'SCRIPT_NAME' => '/sub'
      assert_equal 401, status
    end

    it 'should run an after filter for a route with a format' do
      seen = []
      mock_app do
        after('/data') { seen << :after }
        get('/data(.:format)') { 'open' }
      end
      get '/data.json'
      assert_equal 'open', body
      assert_equal [:after], seen
    end
  end

  describe 'when a route hands the request to a later route' do
    it 'should run a filter named for the later route' do
      mock_app do
        before(:priv) { halt 401, 'stopped' }
        get(:pub, map: '/doc') { pass }
        get(:priv, map: '/doc') { 'open' }
      end
      get '/doc'
      assert_equal 401, status
    end

    it 'should run a filter named for the route left when a condition fails' do
      mock_app do
        set(:never) { |_value| condition { false } }
        before(:priv) { halt 401, 'stopped' }
        get(:pub, map: '/doc', never: true) { 'public' }
        get(:priv, map: '/doc') { 'open' }
      end
      get '/doc'
      assert_equal 401, status
      assert_equal 'stopped', body
    end

    it 'should run an except filter for the later route' do
      mock_app do
        before(except: :pub) { halt 401, 'stopped' }
        get(:pub, map: '/doc') { pass }
        get(:priv, map: '/doc') { 'open' }
      end
      get '/doc'
      assert_equal 401, status
    end

    it 'should run a path filter that covers the format of the later route' do
      mock_app do
        before('/data') { halt 401, 'stopped' }
        get('/:page') { pass }
        get('/data', provides: %i[html json]) { 'open' }
      end
      get '/data.json'
      assert_equal 401, status
    end

    it 'should run a matching filter once' do
      runs = []
      mock_app do
        before { runs << :plain }
        before('/doc') { runs << :path }
        before(:pub, :priv) { runs << :name }
        before(except: :other) { runs << :except }
        get(:pub, map: '/doc') { pass }
        get(:priv, map: '/doc') { 'open' }
        get(:other, map: '/other') { 'other' }
      end
      get '/doc'
      assert_equal 'open', body
      assert_equal %i[plain path name except], runs
    end

    it 'should keep a filter from a route that did not run the request' do
      runs = []
      mock_app do
        before(:priv) { runs << :priv }
        get(:pub, map: '/doc') { 'open' }
        get(:priv, map: '/doc') { 'never' }
      end
      get '/doc'
      assert_equal 'open', body
      assert_empty runs
    end

    it 'should run a controller filter for each route it applies to' do
      mock_app do
        controller :posts do
          before('/doc') { pass unless params[:ok] }
          get(:pub, map: '/doc') { pass }
          get(:priv, map: '/doc') { 'later' }
        end
      end
      get '/doc'
      assert_equal 404, status
      get '/doc?ok=1'
      assert_equal 'later', body
    end

    it 'should run a controller after filter for the route that answers' do
      runs = []
      mock_app do
        controller :posts do
          after('/doc') { runs << :after }
          get(:pub, map: '/doc') { pass }
          get(:priv, map: '/doc') { 'open' }
        end
      end
      get '/doc'
      assert_equal 'open', body
      assert_equal %i[after after], runs
    end

    it 'should run filters for a request made from inside a route' do
      mock_app do
        before('/stopped') { halt 401, 'stopped' }
        get('/stopped') { 'open' }
        get('/inner') { call(env.merge('PATH_INFO' => '/stopped')) }
        get(:pub, map: '/doc') { pass }
        get(:priv, map: '/doc') { call(env.merge('PATH_INFO' => '/stopped')) }
      end
      get '/doc'
      assert_equal 401, status
    end

    it 'should let a filter for a later route pass on to the next one' do
      mock_app do
        before(:second) { pass }
        get(:first, map: '/doc') { pass }
        get(:second, map: '/doc') { 'second' }
        get(:third, map: '/doc') { 'third' }
      end
      get '/doc'
      assert_equal 'third', body
    end

    it 'should not run a filter again for what it set up' do
      mock_app do
        before { params[:seen] = 'yes' }
        before('/doc') { halt 401, 'stopped' unless params[:seen] }
        get(:pub, map: '/doc') { pass }
        get(:priv, map: '/doc') { 'open' }
      end
      get '/doc'
      assert_equal 'open', body
    end

    it 'should not run a filter twice along three routes' do
      runs = []
      mock_app do
        before(:one, :three) { runs << :named }
        get(:one, map: '/doc') { pass }
        get(:two, map: '/doc') { pass }
        get(:three, map: '/doc') { 'open' }
      end
      get '/doc'
      assert_equal 'open', body
      assert_equal [:named], runs
    end

    it 'should not skip a filter because an earlier one passed' do
      mock_app do
        before(:b) { pass }
        before(:b, :c) { halt 401, 'stopped' }
        get(:b, map: '/doc') { 'b' }
        get(:c, map: '/doc') { 'c' }
      end
      get '/doc'
      assert_equal 401, status
    end

    it 'should answer 404 when a filter passes on the last route' do
      mock_app do
        before(:b) { pass }
        get(:a, map: '/doc') { pass }
        get(:b, map: '/doc') { 'b' }
      end
      get '/doc'
      assert_equal 404, status
    end

    it 'should let a filter pass on the first route' do
      mock_app do
        before(:a) { pass }
        get(:a, map: '/doc') { 'a' }
        get(:b, map: '/doc') { 'b' }
      end
      get '/doc'
      assert_equal 'b', body
    end

    it 'should decide the action and controller options for the later route' do
      mock_app do
        before(action: :priv) { halt 401, 'stopped' }
        get(:pub, map: '/doc') { pass }
        get(:priv, map: '/doc') { 'open' }
      end
      get '/doc'
      assert_equal 401, status
    end

    it 'should not run route after filters when a filter halts' do
      runs = []
      mock_app do
        before('/doc') { halt 401, 'stopped' }
        controller :posts do
          after { runs << :after }
          get(:a, map: '/doc') { 'open' }
        end
      end
      get '/doc'
      assert_equal 401, status
      assert_empty runs
    end

    it 'should run a filter named for a superclass route' do
      runs = []
      parent = Class.new(Padrino::Application) do
        set :logging, false
        before { runs << :plain }
        before(:one, :three) { runs << :named }
        get(:two, map: '/doc') { pass }
        get(:three, map: '/doc') { 'open' }
      end
      @app = Class.new(parent) do
        set :protect_from_csrf, false
        get(:one, map: '/doc') { pass }
      end
      get '/doc'
      assert_equal 'open', body
      assert_includes runs, :named
    end

    it 'should run filters once when no route takes the request' do
      runs = []
      mock_app do
        before { runs << :plain }
        before('/missing') { runs << :path }
        get(:a, map: '/doc') { pass }
      end
      get '/missing'
      assert_equal 404, status
      assert_equal %i[plain path], runs
    end

    it 'should run a subclass filter again for a superclass route' do
      parent = Class.new(Padrino::Application) do
        set :logging, false
        get(:admin, map: '/doc') { 'later' }
      end
      @app = Class.new(parent) do
        set :protect_from_csrf, false
        before { halt 403, 'forbidden' if route.name == :admin }
        get(:own, map: '/doc') { pass }
      end
      get '/doc'
      assert_equal 403, status
    end

    it 'should run the rest of a filter that passed for an earlier route' do
      mock_app do
        before do
          pass if route.name == :a
          halt 403, 'forbidden'
        end
        get(:a, map: '/doc') { 'a' }
        get(:b, map: '/doc') { 'b' }
      end
      get '/doc'
      assert_equal 403, status
    end

    it 'should answer 404 when a plain filter passes for every route' do
      mock_app do
        before { pass }
        get(:a, map: '/doc') { 'a' }
      end
      get '/doc'
      assert_equal 404, status
    end

    it 'should keep the block of a pass in a filter' do
      mock_app do
        before(:a) { pass { 'from the block' } }
        get(:a, map: '/doc') { 'a' }
      end
      get '/doc'
      assert_equal 'from the block', body
    end

    it 'should run a controller filter once' do
      runs = []
      mock_app do
        controller :posts do
          before { runs << :controller }
          get(:pub, map: '/doc') { pass }
          get(:priv, map: '/doc') { 'open' }
        end
      end
      get '/doc'
      assert_equal 'open', body
      assert_equal 2, runs.size
    end

    it 'should decide a filter added through add_filter for the later route' do
      mock_app do
        add_filter :before, &Padrino::Filter.new(true, nil, {}, [:priv]) { halt 401, 'stopped' }
        get(:pub, map: '/doc') { pass }
        get(:priv, map: '/doc') { 'open' }
      end
      get '/doc'
      assert_equal 401, status
    end

    it 'should decide a filter wrapped in another block for the later route' do
      guard = Padrino::Filter.new(true, nil, {}, [:priv]) { halt 401, 'stopped' }.to_proc
      mock_app do
        add_filter(:before) { instance_eval(&guard) }
        get(:pub, map: '/doc') { pass }
        get(:priv, map: '/doc') { 'open' }
      end
      get '/doc'
      assert_equal 401, status
    end

    it 'should decide a copied filter for the later route' do
      mock_app do
        before(:priv) { halt 401, 'stopped' }
        filters[:before].map!(&:dup)
        get(:pub, map: '/doc') { pass }
        get(:priv, map: '/doc') { 'open' }
      end
      get '/doc'
      assert_equal 401, status
    end

    it 'should not call anything on what a filter returns' do
      result = Class.new do
        def equal?(_other)
          raise 'called'
        end
      end
      mock_app do
        before { result.new }
        get('/doc') { 'open' }
      end
      get '/doc'
      assert_equal 'open', body
    end

    it 'should decide the controller option for the later route' do
      mock_app do
        before(controller: 'priv') { halt 401, 'stopped' }
        controller(:pub) { get(:doc, map: '/doc') { pass } }
        controller(:priv) { get(:doc, map: '/doc') { 'open' } }
      end
      get '/doc'
      assert_equal 401, status
    end

    it 'should run a filter named for a later route once when the condition of that route fails' do
      runs = []
      mock_app do
        set(:never) { |_value| condition { false } }
        before { runs << :plain }
        before(:priv) { runs << :named }
        get(:pub, map: '/doc') { pass }
        get(:priv, map: '/doc', never: true) { 'never' }
      end
      get '/doc'
      assert_equal 404, status
      assert_equal %i[plain named], runs
    end

    it 'should run a filter once when a route raises NotFound' do
      runs = []
      mock_app do
        before { runs << :plain }
        before(:gone) { runs << :named }
        get(:gone, map: '/doc') { raise Sinatra::NotFound }
      end
      get '/doc'
      assert_equal 404, status
      assert_equal %i[plain named], runs
    end

    it 'should run filters again for each inner call' do
      runs = []
      mock_app do
        before { runs << :plain }
        get('/outer') { call(env.merge('PATH_INFO' => '/inner')) }
        get('/inner') { 'inner' }
      end
      get '/outer'
      assert_equal 'inner', body
      assert_equal %i[plain plain], runs
    end
  end
end
