require File.expand_path('../helper', __FILE__)

describe Padrino::Application do

  it 'creates a new Sinatra::Base subclass on new' do
    app = Padrino.new do
      get '/' do
        'Hello World'
      end
    end
    assert_same Padrino::Application, app.superclass
  end

  it "responds to #template_cache" do
    app = Padrino.new
    assert_kind_of Tilt::Cache, app.template_cache
  end

  class TestApp < Padrino::Application
    get '/' do
      'Hello World'
    end
  end

  it 'include Rack::Utils' do
    assert TestApp.included_modules.include?(Rack::Utils)
  end

  it 'processes requests with #call' do
    assert TestApp.respond_to?(:call)

    request = Rack::MockRequest.new(TestApp)
    response = request.get('/')
    assert response.ok?
    assert_equal 'Hello World', response.body
  end

  class TestApp < Padrino::Application
    get '/state' do
      @foo ||= "new"
      body = "Foo: #{@foo}"
      @foo = 'discard'
      body
    end
  end

  it 'does not maintain state between requests' do
    request = Rack::MockRequest.new(TestApp)
    2.times do
      response = request.get('/state')
      assert response.ok?
      assert_equal 'Foo: new', response.body
    end
  end

  it "passes the subclass to configure blocks" do
    ref = nil
    TestApp.configure { |app| ref = app }
    assert_equal TestApp, ref
  end

  it "allows the configure block arg to be omitted and does not change context" do
    context = nil
    TestApp.configure { context = self }
    assert_equal self, context
  end
end

describe "Padrino::Application as Rack middleware" do
  app = lambda { |env|
    headers = {'X-Downstream' => 'true'}
    headers['X-Route-Missing'] = env['padrino.route-missing'] || ''
    [210, headers, ['Hello from downstream']] }

  class TestMiddleware < Padrino::Application
  end

  it 'creates a middleware that responds to #call with .new' do
    middleware = TestMiddleware.new(app)
    assert middleware.respond_to?(:call)
  end

  it 'exposes the downstream app' do
    middleware = TestMiddleware.new!(app)
    assert_same app, middleware.app
  end

  class TestMiddleware < Padrino::Application
    def route_missing
      env['padrino.route-missing'] = '1'
      super
    end

    get '/' do
      'Hello from middleware'
    end
  end

  middleware = TestMiddleware.new(app)
  request = Rack::MockRequest.new(middleware)

  it 'intercepts requests' do
    response = request.get('/')
    assert response.ok?
    assert_equal 'Hello from middleware', response.body
  end

  it 'automatically forwards requests downstream when no matching route found' do
    response = request.get('/missing')
    assert_equal 210, response.status
    assert_equal 'Hello from downstream', response.body
  end

  it 'calls #route_missing before forwarding downstream' do
    response = request.get('/missing')
    assert_equal '1', response['X-Route-Missing']
  end

  class TestMiddleware < Padrino::Application
    get '/low-level-forward' do
      app.call(env)
    end
  end

  it 'can call the downstream app directly and return result' do
    response = request.get('/low-level-forward')
    assert_equal 210, response.status
    assert_equal 'true', response['X-Downstream']
    assert_equal 'Hello from downstream', response.body
  end

  class TestMiddleware < Padrino::Application
    get '/explicit-forward' do
      response['X-Middleware'] = 'true'
      res = forward
      assert_nil res
      assert_equal 210, response.status
      assert_equal 'true', response['X-Downstream']
      assert_equal ['Hello from downstream'], response.body
      'Hello after explicit forward'
    end
  end

  it 'forwards the request downstream and integrates the response into the current context' do
    response = request.get('/explicit-forward')
    assert_equal 210, response.status
    assert_equal 'true', response['X-Downstream']
    assert_equal 'Hello after explicit forward', response.body
    assert_equal '28', response['Content-Length']
  end

  app_content_length = lambda {|env|
    [200, {'Content-Length' => '16'}, 'From downstream!']}

  class TestMiddlewareContentLength < Padrino::Application
    get '/forward' do
      res = forward
      'From after explicit forward!'
    end
  end

  middleware_content_length = TestMiddlewareContentLength.new(app_content_length)
  request_content_length = Rack::MockRequest.new(middleware_content_length)

  it "sets content length for last response" do
    response = request_content_length.get('/forward')
    assert_equal '28', response['Content-Length']
  end
end
