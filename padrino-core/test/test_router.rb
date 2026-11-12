require_relative 'helper'
require_relative 'fixtures/apps/simple'

describe 'Router' do
  def setup
    Padrino.clear!
  end

  it 'should dispatch paths correctly' do
    app = lambda { |env|
      [200, {
        'X-ScriptName' => env['SCRIPT_NAME'],
        'X-PathInfo' => env['PATH_INFO'],
        'Content-Type' => 'text/plain'
      }, ['']]
    }
    map = Padrino::Router.new(
      { path: '/bar',     to: app },
      { path: '/foo/bar', to: app },
      { path: '/foo',     to: app }
    )

    res = Rack::MockRequest.new(map).get('/')
    assert res.not_found?

    res = Rack::MockRequest.new(map).get('/qux')
    assert res.not_found?

    res = Rack::MockRequest.new(map).get('/foo')
    assert res.ok?
    assert_equal '/foo', res['X-ScriptName']
    assert_equal '/', res['X-PathInfo']

    res = Rack::MockRequest.new(map).get('/foo/')
    assert res.ok?
    assert_equal '/foo', res['X-ScriptName']
    assert_equal '/', res['X-PathInfo']

    res = Rack::MockRequest.new(map).get('/foo/bar')
    assert res.ok?
    assert_equal '/foo/bar', res['X-ScriptName']
    assert_equal '/', res['X-PathInfo']

    res = Rack::MockRequest.new(map).get('/foo/bar/')
    assert res.ok?
    assert_equal '/foo/bar', res['X-ScriptName']
    assert_equal '/', res['X-PathInfo']

    res = Rack::MockRequest.new(map).get('/foo///bar//quux')
    assert_equal 200, res.status
    assert res.ok?
    assert_equal '/foo/bar', res['X-ScriptName']
    assert_equal '//quux', res['X-PathInfo']

    res = Rack::MockRequest.new(map).get('/foo/quux', 'SCRIPT_NAME' => '/bleh')
    assert res.ok?
    assert_equal '/bleh/foo', res['X-ScriptName']
    assert_equal '/quux', res['X-PathInfo']

    res = Rack::MockRequest.new(map).get('/bar', 'HTTP_HOST' => 'foo.org')
    assert res.ok?
    assert_equal '/bar', res['X-ScriptName']
    assert_equal '/', res['X-PathInfo']

    res = Rack::MockRequest.new(map).get('/bar/', 'HTTP_HOST' => 'foo.org')
    assert res.ok?
    assert_equal '/bar', res['X-ScriptName']
    assert_equal '/', res['X-PathInfo']
  end

  it 'should dispatch requests to cascade mounted apps' do
    app = lambda { |env|
      scary = env['PATH_INFO'].match?(/scary/)
      [scary ? 404 : 200, {
        'X-ScriptName' => env['SCRIPT_NAME'],
        'X-PathInfo' => env['PATH_INFO'],
        'Content-Type' => 'text/plain'
      }, ['']]
    }
    api = lambda { |env|
      spooky = env['QUERY_STRING'].match?(/spooky/)
      [spooky ? 200 : 404, {
        'X-API' => spooky,
        'X-ScriptName' => env['SCRIPT_NAME'],
        'X-PathInfo' => env['PATH_INFO'],
        'Content-Type' => 'application/json'
      }, ['']]
    }
    map = Padrino::Router.new(
      { path: '/bar',     to: api },
      { path: '/bar',     to: app }
    )

    res = Rack::MockRequest.new(map).get('/werewolf')
    assert_equal 404, res.status
    refute_includes res, 'X-API'
    refute_includes res, 'X-ScriptName'
    refute_includes res, 'X-PathInfo'

    res = Rack::MockRequest.new(map).get('/bar/mitzvah')
    assert res.ok?
    refute_includes res, 'X-API'
    assert_equal 'text/plain', res['Content-Type']
    assert_equal '/bar', res['X-ScriptName']
    assert_equal '/mitzvah', res['X-PathInfo']

    res = Rack::MockRequest.new(map).get('/bar?spooky')
    assert res.ok?
    assert res['X-API']
    assert_equal 'application/json', res['Content-Type']
    assert_equal '/bar', res['X-ScriptName']
    assert_equal '/', res['X-PathInfo']

    res = Rack::MockRequest.new(map).get('/bar/scary')
    assert_equal 404, res.status
    refute_includes res, 'X-API'
    assert_equal 'text/plain', res['Content-Type']
    assert_equal '/bar', res['X-ScriptName']
    assert_equal '/scary', res['X-PathInfo']
  end

  it 'should dispatch requests to cascade mounted apps and not cascade ok statuses' do
    api = mock_app do
      get('scary') { '1' }
      set :cascade, true
    end

    app = mock_app do
      get('scary') { '2' }
      set :cascade, false
    end

    app2 = mock_app do
      get('terrifying') { '' }
    end

    map = Padrino::Router.new(
      { path: '/bar', to: api },
      { path: '/bar', to: app  },
      { path: '/bar', to: app2 }
    )

    res = Rack::MockRequest.new(map).get('/bar/scary')
    assert res.ok?
    # asserting that on ok we're good to go
    assert_equal '1', res.body

    res = Rack::MockRequest.new(map).get('/bar/terrifying')
    refute res.ok?
  end

  it 'should dispatch requests to cascade mounted apps until it sees a cascade == false or []g' do
    app = mock_app do
      get('scary') { '' }
      set :cascade, []
    end

    app2 = mock_app do
      get('terrifying') { '' }
    end

    map = Padrino::Router.new(
      { path: '/bar', to: app },
      { path: '/bar', to: app2 }
    )

    request_case = -> { Rack::MockRequest.new(map).get('/bar/terrifying') }

    app.cascade = false
    refute request_case.call.ok?

    app.cascade = true
    assert request_case.call.ok?
  end

  it 'should tell only an app whose response may be cascaded the statuses it cascades on' do
    key = Padrino::Router::CASCADE_STATUSES_KEY
    seen = []
    recorder = ->(status) { ->(env) { seen << env[key]; [status, { 'content-type' => 'text/plain' }, ['']] } }
    failing = ->(env) { seen << env[key]; raise 'broke' }
    map = Padrino::Router.new(
      { path: '/bar', to: recorder.call(404) },
      { path: '/bar', to: recorder.call(200) },
      { path: '/baz', to: recorder.call(200) }
    )
    env = Rack::MockRequest.env_for('/bar')
    map.call(env)
    refute env.key?(key)

    map = Padrino::Router.new({ path: '/bar', to: failing }, { path: '/bar', to: recorder.call(200) })
    env = Rack::MockRequest.env_for('/bar')
    assert_raises(RuntimeError) { map.call(env) }
    refute env.key?(key)
    assert_equal [[404, 405], nil, [404, 405]], seen
  end

  it 'should keep the statuses of an outer router for the last app of a router inside it' do
    key = Padrino::Router::CASCADE_STATUSES_KEY
    seen = []
    recorder = ->(status) { ->(env) { seen << env[key]; [status, { 'content-type' => 'text/plain' }, ['']] } }
    inner = Padrino::Router.new({ path: '/', to: recorder.call(404) }, { path: '/', to: recorder.call(404) })
    outer = Padrino::Router.new({ path: '/', to: inner }, { path: '/', to: recorder.call(200) })
    env = Rack::MockRequest.env_for('/page')
    status, = outer.call(env)
    assert_equal 200, status
    assert_equal [[404, 405], [404, 405], nil], seen
    refute env.key?(key)
  end

  it 'should take any cascade setting that answers include?' do
    only_include = Object.new
    def only_include.include?(status)
      status == 404
    end
    [only_include, ..404, 404.0..404.0].each do |setting|
      first = ->(_env) { [404, { 'content-type' => 'text/plain' }, ['first']] }
      first.define_singleton_method(:cascade) { setting }
      second = ->(_env) { [200, { 'content-type' => 'text/plain' }, ['second']] }
      map = Padrino::Router.new({ path: '/', to: first }, { path: '/', to: second })
      _, _, body = map.call(Rack::MockRequest.env_for('/page'))
      assert_equal ['second'], body, "cascade #{setting.inspect}"
    end
  end

  it 'should dispatches hosts correctly' do
    app = lambda do |position, env|
      headers = {
        'Content-Type' => 'text/plain',
        'X-Host' => env['HTTP_HOST'] || env['SERVER_NAME'],
        'X-Position' => position
      }

      [200, headers, ['']]
    end.curry

    map = Padrino::Router.new(
      { host: 'foo.org',           to: app['foo.org'] },
      { host: 'subdomain.foo.org', to: app['subdomain.foo.org'] },
      { host: /.*\.bar.org/,       to: app['bar.org'] }
    )

    res = Rack::MockRequest.new(map).get('/', 'HTTP_HOST' => 'bar.org')
    assert res.not_found?

    res = Rack::MockRequest.new(map).get('/', 'HTTP_HOST' => 'at.bar.org')
    assert res.ok?
    assert_equal 'bar.org', res['X-Position']

    res = Rack::MockRequest.new(map).get('/', 'HTTP_HOST' => 'foo.org')
    assert res.ok?
    assert_equal 'foo.org', res['X-Position']

    res = Rack::MockRequest.new(map).get('/', 'HTTP_HOST' => 'subdomain.foo.org', 'SERVER_NAME' => 'foo.org')
    assert res.ok?
    assert_equal 'subdomain.foo.org', res['X-Position']
  end

  it 'should works with padrino core applications' do
    Padrino.mount('simple_demo').host('padrino.org')
    assert_equal ['simple_demo'], Padrino.mounted_apps.map(&:name)
    assert_equal ['padrino.org'], Padrino.mounted_apps.map(&:app_host)

    res = Rack::MockRequest.new(Padrino.application).get('/')
    assert res.not_found?

    res = Rack::MockRequest.new(Padrino.application).get('/', 'HTTP_HOST' => 'bar.org')
    assert res.not_found?

    res = Rack::MockRequest.new(Padrino.application).get('/', 'HTTP_HOST' => 'padrino.org')
    assert res.ok?
  end

  it 'should works with padrino applications' do
    Padrino.mount('simple_demo').to('/foo').host(/.*\.padrino.org/)

    res = Rack::MockRequest.new(Padrino.application).get('/')
    assert res.not_found?

    res = Rack::MockRequest.new(Padrino.application).get('/', 'HTTP_HOST' => 'bar.org')
    assert res.not_found?

    res = Rack::MockRequest.new(Padrino.application).get('/', 'HTTP_HOST' => 'padrino.org')
    assert res.not_found?

    res = Rack::MockRequest.new(Padrino.application).get('/none', 'HTTP_HOST' => 'foo.padrino.org')
    assert res.not_found?

    res = Rack::MockRequest.new(Padrino.application).get('/foo', 'HTTP_HOST' => 'bar.padrino.org')
    assert res.ok?

    res = Rack::MockRequest.new(Padrino.application).get('/foo/', 'HTTP_HOST' => 'bar.padrino.org')
    assert res.ok?
  end

  it 'should keep the same environment object' do
    app = lambda do |env|
      env['path'] = env['PATH_INFO']
      [200, { 'Content-Type' => 'text/plain' }, ['']]
    end

    map = Padrino::Router.new(
      { path: '/bar',     to: app },
      { path: '/foo/bar', to: app },
      { path: '/foo',     to: app }
    )

    env = Rack::MockRequest.env_for('/bar/foo')
    map.call(env)
    assert_equal '/foo', env['path']
  end
end
