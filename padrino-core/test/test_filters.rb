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
      before('/report') { halt 403, 'filtered' }
      before(%r{\A/files}) { halt 403, 'filtered' }
      before("/caf\u00e9") { @test = 'cafe filter' }
      get('/report') { 'report' }
      get('/files/:id') { 'files' }
      get("/caf\u00e9") { @test.to_s }
      get('/:page') { "page #{params[:page]}" }
    end
    ['/report', '/%72eport', '/rep%6Frt', '/files/1', '/%66iles/1', '/files%ff'].each do |path|
      get path
      assert_equal [403, 'filtered'], [status, body], path
    end
    get '/caf%C3%A9'
    assert_equal 'cafe filter', body
    get '/report%2Fx'
    assert_equal 'page report/x', body
  end

  it 'should filter by path a request the router serves with a trailing slash' do
    mock_app do
      before('/report') { halt 403, 'filtered' }
      before(%r{\A/locked\z}) { halt 403, 'filtered' }
      get('/report') { 'report' }
      get('/locked') { 'locked' }
    end
    ['/report', '/report/', '/%72eport/', '/locked', '/locked/', '/%6Cocked/'].each do |path|
      get path
      assert_equal [403, 'filtered'], [status, body], path
    end
  end

  it 'should filter by path a request whose route params decode an escape again' do
    mock_app do
      before('/files/report') { halt 403, 'filtered' }
      get('/files/:name') { "param #{params[:name]}" }
      get('/*path') { "splat #{params[:path]}" }
    end
    ['/files%252Freport', '/files/%2572eport', '/%2566iles/report', '/files/rep%256Frt'].each do |path|
      get path
      assert_equal [403, 'filtered'], [status, body], path
    end
    get '/files%25252Freport'
    assert_equal 'splat files%2Freport', body
    get '/files/%252572eport'
    assert_equal 'param %72eport', body
  end

  it 'should filter by path a request whose encoded slash a splat route decodes' do
    mock_app do
      before('/files/report') { halt 403, 'filtered' }
      get('/*path') { "file #{params[:path]}" }
    end
    ['/files/report', '/files%2Freport', '/files%2freport'].each do |path|
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

  it 'should give 404 for a path that decodes to a newline with a Regexp filter' do
    mock_app do
      before(%r{\A/admin/.*\z}) { halt 401, 'stopped' }
      before(%r{^/staff/.+$}) { halt 401, 'stopped' }
      after(%r{\A/admin/.*\z}) { response.status = 401 }
      get('/admin/:id') { 'admin' }
      get('/staff/:id') { 'staff' }
      get('/other/:id') { 'other' }
    end
    get '/other/1'
    assert_equal 'other', body
    ['/admin/1', '/staff/1'].each do |path|
      get path
      assert_equal 401, status, path
    end
    ['/admin/a%0Ab', '/staff/%0Ab', '/other/a%0Ab'].each do |path|
      get path
      assert_equal 404, status, path
    end
  end

  it 'should run an except filter for a path that decodes to a newline' do
    mock_app do
      before(except: %r{\A/public$}) { halt 401, 'stopped' }
      after(except: %r{\A/public$}) { response.status = 401 }
      get('/public') { 'public' }
      get('/:x/:y') { 'two' }
    end
    get '/public'
    assert_equal 'public', body
    get '/public/report'
    assert_equal 401, status
    get '/public%0A/report'
    assert_equal [401, 'stopped'], [status, body]
  end

  it 'should keep a path filter for a path with a control character' do
    mock_app do
      before('/login') { @public = true }
      before(except: %r{\A/admin}) { @public = true }
      before { halt 401, 'login' unless @public }
      get('/admin/:id') { 'admin' }
      get('/login') { 'form' }
    end
    get '/login'
    assert_equal 'form', body
    ['/admin/1', '/admin/1%09', '/admin/1%0D'].each do |path|
      get path
      assert_equal [401, 'login'], [status, body], path
    end
    get '/admin/1%0A'
    assert_equal 404, status
  end

  it 'should run an except filter for a path that decodes to a newline under a mounted sub-path' do
    mock_app do
      before(except: %r{^/public}) { halt 401, 'stopped' }
      get('/users/:id/:tab') { 'user' }
    end
    request = Rack::MockRequest.new(Padrino::Router.new({ path: '/blog', to: @app }, { path: '/', to: @app }))
    assert_equal 401, request.get('/blog/users/1/public').status
    assert_equal 401, request.get('/blog/users/1%0A/public').status
    assert_equal 401, request.get('/users/1%0A/public').status
  end

  it 'should compare a path option with a binary path' do
    mock_app do
      before(path_info: /café/) { halt 401, 'stopped' }
      before(path: '/café') { halt 401, 'stopped' }
      get('/*rest') { 'shown' }
    end
    env = Rack::MockRequest.env_for('/')
    env['PATH_INFO'] = "/\xFF".b
    status, = @app.call(env)
    refute_equal 500, status
    env = Rack::MockRequest.env_for('/')
    env['PATH_INFO'] = '/café'.b
    status, = @app.call(env)
    assert_equal 401, status
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

  it 'should apply one except options hash to each filter it is passed to' do
    opts = { except: :index }
    mock_app do
      before(opts) { @first = 'first' }
      before(opts) { @second = 'second' }
      get(:index) { "#{@first}#{@second}" }
      get(:main) { "#{@first}#{@second}" }
    end
    get '/'
    assert_equal '', body
    get '/main'
    assert_equal 'firstsecond', body
    assert_equal({ except: :index }, opts)
  end

  it 'should apply one except list with options to each filter it is passed to' do
    except = [:index, { agent: /IE/ }]
    mock_app do
      before(except: except) { @first = 'first' }
      before(except: except) { @second = 'second' }
      get(:index) { "#{@first}#{@second}" }
      get(:main) { "#{@first}#{@second}" }
    end
    get '/main', {}, { 'HTTP_USER_AGENT' => 'IE' }
    assert_equal '', body
    get '/main'
    assert_equal 'firstsecond', body
    assert_equal [:index, { agent: /IE/ }], except
  end

  it 'should accept frozen except options' do
    mock_app do
      before({ except: :index }.freeze) { @first = 'first' }
      before(except: [:index, { agent: /IE/ }.freeze].freeze) { @second = 'second' }
      get(:index) { "#{@first}#{@second}" }
      get(:main) { "#{@first}#{@second}" }
    end
    get '/'
    assert_equal '', body
    get '/main'
    assert_equal 'firstsecond', body
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
        get('/data', provides: %i[html json]) { 'shown' }
        get('/report', provides: %i[html json]) { 'shown' }
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
        get('/data(.:format)?') { 'shown' }
        get('/e.:format') { 'shown' }
        get('/f(.:format)') { 'shown' }
      end
      %w[/data.json /data.a.b /e.json /f.json].each do |path|
        get path
        assert_equal 401, status, path
      end
    end

    it 'should cover a format the route makes optional' do
      mock_app do
        before('/data') { halt 401, 'stopped' }
        get('/data(.:format)?') { 'shown' }
      end
      %w[/data.json /data.a.b /data.json/ /data/].each do |path|
        get path
        assert_equal 401, status, path
      end
    end

    [
      ['provides:', proc { get('/list', provides: %i[html json]) { 'list' } }],
      ['map: and provides:', proc { get(:list, map: '/list', provides: :json) { 'list' } }],
      ['controller provides:', proc { controller(:list, provides: %i[html json]) { get(:index) { 'list' } } }],
      ['provides', proc { provides :json; get('/list') { 'list' } }]
    ].each do |label, routes|
      it "should run a filter for the path with a slash only for a format the route provides (#{label})" do
        mock_app do
          before('/list/') { @public = true }
          before { halt 401, 'login' unless @public }
          instance_eval(&routes)
          get('/list.:format') { 'member' }
        end
        %w[/list/ /list.json].each do |path|
          get path
          assert_equal 'list', body, path
        end
        %w[/list.xml /list.JSON].each do |path|
          get path
          assert_equal [401, 'login'], [status, body], path
        end
      end
    end

    it 'should run a filter for the path without the format of a route that requires one' do
      mock_app do
        before('/list') { halt 401, 'stopped' }
        get('/list.:format') { 'member' }
      end
      get '/list.xml'
      assert_equal [401, 'stopped'], [status, body]
    end

    it 'should not run a filter for a path the route does not serve (/data_:format)' do
      seen = []
      mock_app do
        before('/data') { halt 401, 'stopped' }
        before(path: '/data') { halt 401, 'stopped' }
        before(path_info: '/data') { halt 401, 'stopped' }
        after('/data') { seen << :after }
        get('/data_:format') { 'shown' }
      end
      get '/data_json'
      assert_equal 'shown', body
      assert_empty seen
    end

    it 'should run a filter for a format the route provides' do
      mock_app do
        before('/list') { halt 403, 'stopped' }
        before('/data') { halt 403, 'stopped' }
        before('/any') { halt 403, 'stopped' }
        get('/list', provides: :json) { 'list' }
        get('/data(.:format)?', provides: :json) { 'data' }
        get('/any', provides: :any) { 'any' }
        get('/:id.:format') { 'member' }
      end
      %w[/list.json /data.json /any.xml].each do |path|
        get path
        assert_equal [403, 'stopped'], [status, body], path
      end
    end

    { 'a path' => ['/list', 401], 'the path_info option' => [{ path_info: '/list' }, 402] }.each do |label, (filter, code)|
      it "should decide a provided format as route params receive it, for #{label}" do
        mock_app do
          before(filter) { halt code, 'stopped' }
          get('/list', provides: :json) { 'list' }
        end
        %w[/list.%256Ason /list.j%2573on /list.%256A%2573on /list.js%256Fn /list.js%256Fn/].each do |path|
          get path
          assert_equal [code, 'stopped'], [status, body], path
        end
        head '/list.js%256Fn'
        assert_equal code, status
      end
    end

    it 'should not run a filter for the path with a slash for an encoded format the route does not provide' do
      mock_app do
        before('/list/') { @public = true }
        before { halt 401, 'login' unless @public }
        get('/list', provides: :json) { 'list' }
        get('/list.:format') { "member #{params[:format]}" }
      end
      %w[/list.%2578ml /list.x%256Dl].each do |path|
        get path
        assert_equal [401, 'login'], [status, body], path
      end
    end

    it 'should not run a filter for the path with a slash for a format with no MIME type on a provides :any route' do
      mock_app do
        before('/any/') { @public = true }
        before { halt 401, 'login' unless @public }
        get('/any', provides: :any) { 'any' }
        get('/any.:format') { "member #{params[:format]}" }
      end
      get '/any.nosuchext'
      assert_equal [401, 'login'], [status, body]
      get '/any.json'
      assert_equal [200, 'any'], [status, body]
    end

    it 'should run a filter for a format the route answers itself with treat_format_as_accept' do
      mock_app do
        enable :treat_format_as_accept
        before('/list') { halt 401, 'stopped' }
        get('/list', provides: %i[html json]) { 'list' }
      end
      get '/list.xml'
      assert_equal [401, 'stopped'], [status, body]
    end

    it 'should decide a format for each app that runs a shared route' do
      base = Class.new(Padrino::Application) do
        set :environment, :test
        set(:only_for) { |tag| condition { settings.tag == tag } }
        get('/list', only_for: :b, provides: :json) { 'list' }
        get('/list.:format', only_for: :b) { "flag #{@flag.inspect}" }
      end
      a = Class.new(base) do
        set :tag, :a
        enable :treat_format_as_accept
        before('/list/') { @flag = true }
      end
      b = Class.new(base) do
        set :tag, :b
        before('/list/') { @flag = true }
      end
      response = Rack::MockRequest.new(Padrino::Router.new({ path: '/', to: a }, { path: '/', to: b })).get('/list.xml')
      assert_equal [200, 'flag nil'], [response.status, response.body]
    end

    it 'should cover a format after a trailing slash' do
      mock_app do
        before('/data') { halt 401, 'stopped' }
        before(%r{\A/report\z}) { halt 401, 'stopped' }
        get('/data/?', provides: %i[html json]) { 'shown' }
        get('/report/?', provides: %i[html json]) { 'shown' }
      end
      %w[/data/ /data// /data/.json /data.json/ /report// /report/.json].each do |path|
        get path
        assert_equal [401, 'stopped'], [status, body], path
      end
    end

    it 'should cover every trailing slash of a route without a format' do
      mock_app do
        before('/data') { halt 401, 'stopped' }
        get('/data/?') { 'shown' }
        get('/data//') { 'shown' }
      end
      %w[/data/ /data//].each do |path|
        get path
        assert_equal 401, status, path
      end
    end

    it 'should keep the root path after every slash is stripped' do
      mock_app do
        before('/') { halt 401, 'stopped' }
        get('/', provides: %i[html json]) { 'shown' }
        get('//') { 'shown' }
      end
      %w[/ // /.json].each do |path|
        get path
        assert_equal 401, status, path
      end
    end

    it 'should cover a dot left by an optional format' do
      mock_app do
        before('/data') { halt 401, 'stopped' }
        get('/data.:format?') { 'shown' }
      end
      %w[/data /data. /data./ /data%2E /data.json].each do |path|
        get path
        assert_equal 401, status, path
      end
    end

    it 'should cover a format after a dot for the path with the dot' do
      mock_app do
        before('/data.') { halt 401, 'stopped' }
        get('/data.:format?') { 'shown' }
      end
      %w[/data. /data./ /data%2E /data.json /data.json/].each do |path|
        get path
        assert_equal [401, 'stopped'], [status, body], path
      end
    end

    it 'should cover a format with an optional dot' do
      mock_app do
        before('/data') { halt 401, 'stopped' }
        get('/data.?:format?') { 'shown' }
      end
      %w[/data /data. /datajson /data.json].each do |path|
        get path
        assert_equal 401, status, path
      end
    end

    it 'should cover a format with an optional dot for the longest path the route serves without it' do
      mock_app do
        before('/data.') { halt 403, 'dot' }
        get('/data.?:format?') { 'shown' }
      end
      %w[/data. /data.json].each do |path|
        get path
        assert_equal [403, 'dot'], [status, body], path
      end
    end

    it 'should take a format after a slash for another path' do
      mock_app do
        before('/data') { halt 401, 'stopped' }
        get('/data/:format?') { 'shown' }
      end
      get '/data/json'
      assert_equal 'shown', body
      get '/data/'
      assert_equal 401, status
    end

    it 'should not strip a format from the middle of a route' do
      mock_app do
        before('/x') { halt 401, 'stopped' }
        get('/x.:format/y') { 'shown' }
      end
      get '/x.json/y'
      assert_equal 'shown', body
    end

    it 'should keep an except filter on a path with a newline' do
      mock_app do
        before(except: %r{^/public/}) { halt 401, 'stopped' }
        get('/:tenant/public/:id') { 'shown' }
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
        get('/*rest') { 'shown' }
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
    ].each do |filter, pattern, options, path|
      describe "with a filter #{filter.inspect} that ends in a slash on #{pattern}" do
        it "should run a before filter for #{path}" do
          mock_app do
            before(filter) { halt 401, 'stopped' }
            get(pattern, options) { 'shown' }
          end
          get path
          assert_equal 401, status
        end

        it "should run an after filter for #{path}" do
          seen = []
          mock_app do
            after(filter) { seen << :after }
            get(pattern, options) { 'shown' }
          end
          get path
          assert_equal 'shown', body
          assert_equal [:after], seen
        end

        it "should apply the path and path_info options for #{path}" do
          %i[path path_info].each do |name|
            mock_app do
              before(name => filter) { halt 401, 'stopped' }
              get(pattern, options) { 'shown' }
            end
            assert_equal 401, Rack::MockRequest.new(app).get(path).status, name
          end
        end
      end
    end

    it 'should keep a filter that ends in a slash off the path without one' do
      mock_app do
        before('/data/') { halt 401, 'stopped' }
        get('/data', provides: :json) { 'shown' }
      end
      get '/data'
      assert_equal 'shown', body
      get '/data/'
      assert_equal 401, status
    end

    %i[path path_info].each do |name|
      it "should not raise for invalid UTF-8 in the #{name} option" do
        mock_app do
          before(name => '/data') { halt 401, 'stopped' }
          get('/data') { 'shown' }
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
        get('/data', provides: %i[html json]) { 'shown' }
        get('/other', provides: %i[html json]) { 'other' }
      end
      get '/data'
      assert_equal 'shown', body
      get '/data.json'
      assert_equal 401, status
      get '/other.json'
      assert_equal 401, status
    end

    it 'should stand aside for a path an except filter names with its format' do
      mock_app do
        before(except: /\.json$/) { halt 401, 'stopped' }
        get('/feed', provides: %i[html json]) { 'shown' }
      end
      get '/feed.json'
      assert_equal 'shown', body
      get '/feed'
      assert_equal 401, status
    end

    it 'should apply the path and path_info options' do
      mock_app do
        before(path: '/g') { halt 401, 'stopped' }
        before(path_info: %r{\A/h\z}) { halt 401, 'stopped' }
        get('/g(.:format)') { 'shown' }
        get('/h(.:format)') { 'shown' }
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
        get('/opt') { 'shown' }
        get('/way') { 'shown' }
      end
      %w[/%6Fpt /opt/ /%77ay /way/].each do |path|
        get path
        assert_equal 401, status, path
      end
    end

    it 'should keep matching a path option written with the encoded path' do
      mock_app do
        before(path_info: '/caf%C3%A9') { halt 401, 'stopped' }
        get('/café') { 'shown' }
      end
      get '/caf%C3%A9'
      assert_equal 401, status
    end

    it 'should cover the format of a mounted app on the path option' do
      mock_app do
        before(path: '/sub/foo') { halt 401, 'stopped' }
        get('/foo', provides: %i[html json]) { 'shown' }
      end
      get '/foo.json', {}, 'SCRIPT_NAME' => '/sub'
      assert_equal 401, status
    end

    it 'should run an after filter for a route with a format' do
      seen = []
      mock_app do
        after('/data') { seen << :after }
        get('/data(.:format)?') { 'shown' }
      end
      get '/data.json'
      assert_equal 'shown', body
      assert_equal [:after], seen
    end
  end

  describe 'on a route with a part after a delimiter' do
    def mounted_request
      Rack::MockRequest.new(Padrino::Router.new({ path: '/blog', to: @app }, { path: '/', to: @app }))
    end

    [
      ['/data', '/data(-:format)?', '/data-json'],
      ['/data', '/data(,:format)?', '/data,json'],
      ['/data', '/data(_:format)?', '/data_json'],
      ['/data', '/data(~:format)?', '/data~json'],
      ['/data', '/data(--:format)?', '/data--json']
    ].each do |filter, pattern, path|
      describe "with a filter #{filter} on #{pattern}" do
        it "should run a before filter for #{path}" do
          mock_app do
            before(filter) { halt 401, 'stopped' }
            get(pattern) { 'shown' }
          end
          get path
          assert_equal [401, 'stopped'], [status, body]
        end

        it "should run a before filter for #{path} under a mounted sub-path" do
          mock_app do
            before(filter) { halt 401, 'stopped' }
            get(pattern) { 'shown' }
          end
          assert_equal 401, mounted_request.get("/blog#{path}").status
        end

        it "should run an after filter for #{path}" do
          seen = []
          mock_app do
            after(filter) { seen << :after }
            get(pattern) { 'shown' }
          end
          get path
          assert_equal 'shown', body
          assert_equal [:after], seen
        end

        it "should keep an except filter running for #{path}" do
          seen = []
          mock_app do
            before(except: filter) { seen << :before }
            after(except: filter) { seen << :after }
            get(pattern) { 'shown' }
          end
          get path
          assert_equal 'shown', body
          assert_equal %i[before after], seen
        end

        it "should apply the path option for #{path} under a mounted sub-path" do
          mock_app do
            before(path: "/blog#{filter}") { halt 401, 'stopped' }
            get(pattern) { 'shown' }
          end
          assert_equal 401, mounted_request.get("/blog#{path}").status
          assert_equal 401, mounted_request.get("/blog#{filter}").status
        end
      end
    end

    it 'should take a part after a slash for another segment' do
      mock_app do
        before('/data') { halt 401, 'stopped' }
        get('/data/:format?') { 'shown' }
        get('/files/x(-:format)?') { 'file' }
      end
      get '/data/json'
      assert_equal 'shown', body
      get '/files/x-json'
      assert_equal 'file', body
    end

    it 'should not cover a part the route requires' do
      mock_app do
        before('/posts/2024') { halt 403, 'stopped' }
        before('/data') { halt 401, 'stopped' }
        before('/file') { halt 401, 'stopped' }
        get('/posts/:year-:month') { "posts #{params[:year]} #{params[:month]}" }
        get('/data-:id') { 'data' }
        get('/file(.:ext)') { "file #{params[:ext]}" }
      end
      get '/posts/2024-05'
      assert_equal 'posts 2024 05', body
      get '/data-5'
      assert_equal 'data', body
      get '/file.txt'
      assert_equal 'file txt', body
    end

    [
      ['/reports', proc { get('/reports') { 'public' }; get('/reports(.:v)?') { 'member' } }, %w[/reports.internal]],
      ['/api/users', proc { get('/api/users') { 'public' }; get('/api(.:format)?/users') { 'member' } }, %w[/api.admin/users]],
      ['/c', proc { get('/c') { 'public' }; get('/c++(.:format)?') { 'member' } }, %w[/c++.json]],
      ['/', proc { get('/') { 'public' }; get('/~(.:format)?') { 'member' } }, %w[/~.json]]
    ].each do |filter, routes, paths|
      it "should not apply a filter for #{filter} to #{paths.join(', ')}" do
        mock_app do
          before(filter) { @public = true }
          before { halt 401, 'login' unless @public }
          instance_eval(&routes)
        end
        get filter
        assert_equal 'public', body
        paths.each do |path|
          get path
          assert_equal [401, 'login'], [status, body], path
        end
      end
    end

    it 'should cut the path the route writes before its format' do
      mock_app do
        before('/c++') { halt 401, 'c' }
        before('/~') { halt 401, 'tilde' }
        before('/a.') { halt 401, 'a' }
        before('/naïve') { halt 401, 'naive' }
        before('/v') { halt 401, 'v' }
        get('/c++(.:format)?') { 'shown' }
        get('/naïve(.:format)?') { 'shown' }
        get('/v:format?') { 'shown' }
        get('/~(.:format)?') { 'shown' }
        get('/a.(.:format)?') { 'shown' }
      end
      { '/c++.json' => 'c', '/~.json' => 'tilde', '/a..json' => 'a', '/a.' => 'a', '/na%C3%AFve.json' => 'naive', '/vjson' => 'v' }.each do |path, filter|
        get path
        assert_equal [401, filter], [status, body], path
      end
    end

    it 'should cut a format after a path with non-ASCII characters' do
      mock_app do
        before('/ééé') { @seen = 'eee' }
        before('/日本語') { @seen = 'jp' }
        before('/naïve') { @seen = 'naive' }
        get('/ééé', provides: %i[html json]) { "eee #{@seen}" }
        get('/日本語(.:format)?') { "jp #{@seen}" }
        get('/naïve(.:format)?') { "naive #{@seen}" }
      end
      { '/%C3%A9%C3%A9%C3%A9' => 'eee eee', '/%C3%A9%C3%A9%C3%A9.json' => 'eee eee',
        '/%E6%97%A5%E6%9C%AC%E8%AA%9E.json' => 'jp jp', '/na%C3%AFve' => 'naive naive',
        '/na%C3%AFve.json' => 'naive naive' }.each do |path, served|
        get path
        assert_equal [200, served], [status, body], path
      end
    end

    it 'should cut a format at the path the route serves without it' do
      mock_app do
        before('/c') { halt 403, 'shorter' }
        before('/doc') { halt 403, 'shorter' }
        before('/c+') { halt 401, 'c' }
        before('/doc~') { halt 401, 'doc' }
        get('/c+:format?') { 'c' }
        get('/doc~:format?') { 'doc' }
      end
      { '/c+json' => 'c', '/doc~json' => 'doc' }.each do |path, filter|
        get path
        assert_equal [401, filter], [status, body], path
      end
    end

    [
      ['/reports/', '/reports/:format', '/reports/csv'],
      ['/', '/:format', '/csv'],
      ['/data-', '/data--:format', '/data--json'],
      ['/data', '/data-:format?', '/data-json']
    ].each do |filter, pattern, path|
      it "should not run a filter for #{filter} on #{path} from #{pattern}" do
        mock_app do
          before(filter) { @public = true }
          before { halt 401, 'login' unless @public }
          get(pattern) { 'member' }
          get(filter) { 'public' }
        end
        get filter
        assert_equal 'public', body
        get path
        assert_equal [401, 'login'], [status, body]
      end
    end

    [
      ['/reports/', '/reports/:format?', '/reports/csv'],
      ['/', '/:format?', '/csv'],
      ['/data-', '/data-:format?', '/data-json'],
      ['/doc/', '/doc/(-:format)?', '/doc/-json'],
      ['/doc/', '/doc/(-:format)?', '/doc/-json/']
    ].each do |filter, pattern, path|
      it "should run a filter for #{filter} on #{path} from #{pattern}, which serves #{filter}" do
        mock_app do
          before(filter) { halt 403, 'stopped' }
          get(pattern) { 'shown' }
        end
        get path
        assert_equal [403, 'stopped'], [status, body]
      end
    end

    it 'should run a filter for a format the route provides when another route serves the path without it' do
      mock_app do
        before('/data') { halt 403, 'stopped' }
        get('/data', provides: :csv) { 'csv' }
        get('/data') { 'html' }
      end
      %w[/data /data.csv].each do |path|
        get path
        assert_equal [403, 'stopped'], [status, body], path
      end
    end

    [
      ['/reports/(-:format)?', '/reports/-json'],
      ['/reports/(-:format)?', '/reports/-json/'],
      ['/reports/-:format', '/reports/-csv/']
    ].each do |pattern, path|
      it "should not run a filter for the path before the slash of a format on #{pattern} (#{path})" do
        mock_app do
          before('/reports') { @index = true }
          before { halt 401, 'login' unless @index }
          get(pattern) { "export #{params[:format].inspect}" }
          get('/reports') { 'index' }
        end
        get '/reports'
        assert_equal 'index', body
        %i[get head].each do |verb|
          send(verb, path)
          assert_equal 401, status, "#{verb} #{path}"
        end
      end
    end

    %i[path path_info].each do |name|
      it "should run a #{name} option filter for the trailing slash the router drops for the same route" do
        mock_app do
          before(name => '/about') { @index = true }
          before { halt 401, 'login' unless @index }
          get('/about') { 'about' }
        end
        get '/about/'
        assert_equal 'about', body
      end
    end

    it 'should cover only a capture named format that ends the path' do
      mock_app do
        before('/v') { halt 403, 'stopped' }
        before('/m/x') { halt 403, 'stopped' }
        before('/d') { halt 403, 'stopped' }
        get('/v(.:v)?') { 'v' }
        get('/m(.:format)?/x') { 'm' }
        get('/d(.:v)?.:format') { 'd' }
      end
      { '/v.1' => 'v', '/m.json/x' => 'm', '/d.v1.json' => 'd' }.each do |path, served|
        get path
        assert_equal served, body, path
      end
    end

    it 'should cover the forms the same route serves' do
      mock_app do
        before('/data') { halt 401, 'stopped' }
        before('/s') { halt 401, 'stopped' }
        get('/data(.:format)?') { 'data' }
        get('/s') { 's' }
        get('/:slug(.:format)?') { 'slug' }
      end
      %w[/data /data.json /data.json/ /s /s/ /s//].each do |path|
        get path
        assert_equal [401, 'stopped'], [status, body], path
      end
    end

    it 'should not cover a part a greedy capture before it takes' do
      mock_app do
        before('/posts/2024-05') { halt 403, 'stopped' }
        get('/posts/:year-:month') { "posts #{params[:year]} #{params[:month]}" }
      end
      get '/posts/2024-05-01'
      assert_equal 'posts 2024-05 01', body
      get '/posts/2024-05'
      assert_equal 403, status
    end

    it 'should not cover an optional part after a delimiter other than a dot' do
      seen = []
      mock_app do
        before('/users/john') { seen << :before }
        get('/users/:first(-:last)?') { "user #{params[:first]} #{params[:last]}" }
      end
      get '/users/john-smith'
      assert_equal 'user john smith', body
      get '/users/john.'
      assert_equal 'user john. ', body
      assert_empty seen
      get '/users/john'
      assert_equal [:before], seen
    end
  end

  describe 'on the route that serves a form of the path' do
    [
      [['/e'], '/e.:format', %w[/e.json]],
      [['/f'], '/f(.:format)', %w[/f.json]],
      [[{ path: '/g' }, { path_info: '/g' }], '/g(.:format)', %w[/g.json]],
      [['/data'], '/data.:format?', %w[/data. /data.json]],
      [[%r{\A/users/\d+\z}], '/users/:id(.:format)?', %w[/users/1.json]],
      [[%r{/edit\z}], '/posts/:id/edit(.:format)?', %w[/posts/1/edit.json]],
      [['/files/report'], '/files/:name', %w[/files/%2572eport]],
      [[%r{\A/dashboard}], '/:section', %w[/%2564ashboard]],
      [['/report'], '/*', %w[/report/ /report//]]
    ].each do |filters, pattern, paths|
      it "should run a filter for #{filters.map(&:inspect).join(' and ')} on #{paths.join(' and ')} from #{pattern}" do
        filters.each do |filter|
          mock_app do
            before(filter) { halt 401, 'stopped' }
            get(pattern) { 'shown' }
          end
          paths.each do |path|
            response = Rack::MockRequest.new(app).get(path)
            assert_equal [401, 'stopped'], [response.status, response.body], "#{filter.inspect} #{path}"
          end
        end
      end

      it "should run an after filter for #{filters.map(&:inspect).join(' and ')} on #{paths.join(' and ')} from #{pattern}" do
        filters.each do |filter|
          seen = []
          mock_app do
            after(filter) { seen << :after }
            get(pattern) { 'shown' }
          end
          paths.each do |path|
            seen.clear
            assert_equal 'shown', Rack::MockRequest.new(app).get(path).body, "#{filter.inspect} #{path}"
            assert_equal [:after], seen, "#{filter.inspect} #{path}"
          end
        end
      end
    end

    it 'should not run a filter for another path' do
      mock_app do
        before('/e') { halt 401, 'stopped' }
        get('/e/:x') { 'shown' }
        get('/e(.:format)?') { 'shown' }
        get('/:name(.:format)?') { 'shown' }
        get('/*') { 'shown' }
      end
      %w[/elephant /elephant.json /e/x /e/x.json /ex.json /e.x/y /x/e /x/e.json].each do |path|
        get path
        assert_equal 'shown', body, path
      end
    end
  end

  describe 'when a route hands the request to a later route' do
    it 'should run a filter named for the later route' do
      mock_app do
        before(:priv) { halt 401, 'stopped' }
        get(:pub, map: '/doc') { pass }
        get(:priv, map: '/doc') { 'shown' }
      end
      get '/doc'
      assert_equal 401, status
    end

    it 'should run a filter named for the route left when a condition fails' do
      mock_app do
        set(:never) { |_value| condition { false } }
        before(:priv) { halt 401, 'stopped' }
        get(:pub, map: '/doc', never: true) { 'public' }
        get(:priv, map: '/doc') { 'shown' }
      end
      get '/doc'
      assert_equal 401, status
      assert_equal 'stopped', body
    end

    it 'should run an except filter for the later route' do
      mock_app do
        before(except: :pub) { halt 401, 'stopped' }
        get(:pub, map: '/doc') { pass }
        get(:priv, map: '/doc') { 'shown' }
      end
      get '/doc'
      assert_equal 401, status
    end

    it 'should run a path filter that covers the format of the later route' do
      mock_app do
        before('/data') { halt 401, 'stopped' }
        get('/:page') { pass }
        get('/data', provides: %i[html json]) { 'shown' }
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
        get(:priv, map: '/doc') { 'shown' }
        get(:other, map: '/other') { 'other' }
      end
      get '/doc'
      assert_equal 'shown', body
      assert_equal %i[plain path name except], runs
    end

    it 'should keep a filter from a route that did not run the request' do
      runs = []
      mock_app do
        before(:priv) { runs << :priv }
        get(:pub, map: '/doc') { 'shown' }
        get(:priv, map: '/doc') { 'never' }
      end
      get '/doc'
      assert_equal 'shown', body
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
          get(:priv, map: '/doc') { 'shown' }
        end
      end
      get '/doc'
      assert_equal 'shown', body
      assert_equal %i[after after], runs
    end

    it 'should run filters for a request made from inside a route' do
      mock_app do
        before('/stopped') { halt 401, 'stopped' }
        get('/stopped') { 'shown' }
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
        get(:priv, map: '/doc') { 'shown' }
      end
      get '/doc'
      assert_equal 'shown', body
    end

    it 'should not run a filter twice along three routes' do
      runs = []
      mock_app do
        before(:one, :three) { runs << :named }
        get(:one, map: '/doc') { pass }
        get(:two, map: '/doc') { pass }
        get(:three, map: '/doc') { 'shown' }
      end
      get '/doc'
      assert_equal 'shown', body
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
        get(:priv, map: '/doc') { 'shown' }
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
          get(:a, map: '/doc') { 'shown' }
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
        get(:three, map: '/doc') { 'shown' }
      end
      @app = Class.new(parent) do
        set :protect_from_csrf, false
        get(:one, map: '/doc') { pass }
      end
      get '/doc'
      assert_equal 'shown', body
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

    it 'should run a controller filter once per route tried' do
      runs = []
      mock_app do
        controller :posts do
          before { runs << :controller }
          get(:pub, map: '/doc') { pass }
          get(:priv, map: '/doc') { 'shown' }
        end
      end
      get '/doc'
      assert_equal 'shown', body
      assert_equal 2, runs.size
    end

    it 'should decide a filter added through add_filter for the later route' do
      mock_app do
        add_filter :before, &Padrino::Filter.new(true, nil, {}, [:priv]) { halt 401, 'stopped' }
        get(:pub, map: '/doc') { pass }
        get(:priv, map: '/doc') { 'shown' }
      end
      get '/doc'
      assert_equal 401, status
    end

    it 'should decide a filter wrapped in another block for the later route' do
      filter = Padrino::Filter.new(true, nil, {}, [:priv]) { halt 401, 'stopped' }.to_proc
      mock_app do
        add_filter(:before) { instance_eval(&filter) }
        get(:pub, map: '/doc') { pass }
        get(:priv, map: '/doc') { 'shown' }
      end
      get '/doc'
      assert_equal 401, status
    end

    it 'should decide a copied filter for the later route' do
      mock_app do
        before(:priv) { halt 401, 'stopped' }
        filters[:before].map!(&:dup)
        get(:pub, map: '/doc') { pass }
        get(:priv, map: '/doc') { 'shown' }
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
        get('/doc') { 'shown' }
      end
      get '/doc'
      assert_equal 'shown', body
    end

    it 'should decide the controller option for the later route' do
      mock_app do
        before(controller: 'priv') { halt 401, 'stopped' }
        controller(:pub) { get(:doc, map: '/doc') { pass } }
        controller(:priv) { get(:doc, map: '/doc') { 'shown' } }
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
