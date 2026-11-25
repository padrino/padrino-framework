require File.expand_path('helper', __dir__)

describe 'PadrinoCache' do
  after do
    tmp = File.expand_path('tmp', __dir__)
    `rm -rf #{tmp}`
  end

  it 'names a page served from the cache in sinatra.route' do
    routes = []
    mock_app do
      register Padrino::Cache
      enable :caching
      get('/page/:id', cache: true) { "page #{params[:id]}" }
      after { routes << env['sinatra.route'] }
    end
    2.times { get '/page/1' }
    assert_equal 'page 1', body
    assert_equal ['GET /page/:id', 'GET /page/:id'], routes
  end

  it 'should cache a fragment' do
    called = false
    mock_app do
      register Padrino::Cache
      enable :caching
      get('/foo') { cache(:test) { called ? halt(500) : (called = 'test fragment') } }
    end
    get '/foo'
    assert_equal 200, status
    assert_equal 'test fragment', body
    get '/foo'
    assert_equal 200, status
    assert_equal 'test fragment', body
    refute_equal called, false
  end

  it 'should cache with a logger without Padrino::Logger::Extensions' do
    log = StringIO.new
    save_logger = Padrino.logger
    Padrino.logger = Logger.new(log)
    mock_app do
      register Padrino::Cache
      enable :caching
      get('/foo') { cache(:test) { 'test fragment' } }
      get('/bar', cache: true) { cache_object(:object) { 'test object' } }
    end
    2.times do
      get '/foo'
      assert_equal 200, status
      assert_equal 'test fragment', body
      get '/bar'
      assert_equal 200, status
      assert_equal 'test object', body
    end
    ['SET FRAGMENT', 'GET FRAGMENT', 'SET OBJECT', 'SET CACHE', 'GET CACHE'].each do |action|
      assert_match(/#{action} \(\d+\.\d+s\)/, log.string)
    end
  ensure
    Padrino.logger = save_logger
  end

  it 'should cache with a logger that lacks bench' do
    log = StringIO.new
    mock_app do
      register Padrino::Cache
      enable :caching
      helpers { define_method(:logger) { @logger ||= Logger.new(log).freeze } }
      get('/foo') { cache(:test) { 'test fragment' } }
      get('/bar', cache: true) { cache_object(:object) { 'test object' } }
      get('/baz') { cache_object(:uncached_page) { 'object only' } }
    end
    2.times do
      get '/foo'
      assert_equal 'test fragment', body
      get '/bar'
      assert_equal 'test object', body
      get '/baz'
      assert_equal 'object only', body
    end
  end

  it 'should cache a page' do
    called = false
    mock_app do
      register Padrino::Cache
      enable :caching
      get('/foo', cache: true) { called ? halt(500) : (called = 'test page') }
    end
    get '/foo'
    assert_equal 200, status
    assert_equal 'test page', body
    get '/foo'
    assert_equal 200, status
    assert_equal 'test page', body
    refute_equal false, called
  end

  it 'should cache the page of a route given host: for that host only' do
    calls = Hash.new(0)
    mock_app do
      register Padrino::Cache
      enable :caching
      get(:index, host: 'admin.example.com', cache: true) { "admin #{calls[:admin] += 1}" }
      get(:index, cache: true) { "public #{calls[:public] += 1}" }
    end
    get '/', {}, 'HTTP_HOST' => 'admin.example.com'
    assert_equal 'admin 1', body
    get '/', {}, 'HTTP_HOST' => 'www.example.com'
    assert_equal 'public 1', body
    get '/', {}, 'HTTP_HOST' => 'Admin.Example.COM'
    assert_equal 'admin 1', body
    get '/', {}, 'HTTP_HOST' => 'www.example.com'
    assert_equal 'public 1', body
  end

  it 'should cache HEAD verb' do
    called_times = 0
    mock_app do
      register Padrino::Cache
      enable :caching
      get('/foo', cache: true) { called_times += 1; called_times.to_s }
    end
    head '/foo'
    head '/foo'
    assert_equal 1, called_times
  end

  it 'should not cache POST verb' do
    called_times = 0
    mock_app do
      register Padrino::Cache
      enable :caching
      post('/foo', cache: true) { called_times += 1; called_times.to_s }
    end
    post '/foo'
    assert_equal 1, called_times
    post '/foo'
    assert_equal 2, called_times
  end

  it 'should not cache DELETE verb' do
    called_times = 0
    mock_app do
      register Padrino::Cache
      enable :caching
      delete('/foo', cache: true) { called_times += 1; called_times.to_s }
    end
    delete '/foo'
    assert_equal 1, called_times
    delete '/foo'
    assert_equal 2, called_times
  end

  it 'should not cache PUT verb' do
    called_times = 0
    mock_app do
      register Padrino::Cache
      enable :caching
      put('/foo', cache: true) { called_times += 1; called_times.to_s }
    end
    put '/foo'
    assert_equal 1, called_times
    put '/foo'
    assert_equal 2, called_times
  end

  it 'should delete from the cache' do
    called = false
    mock_app do
      register Padrino::Cache
      enable :caching
      get('/foo', cache: true) { called ? 'test page again' : (called = 'test page') }
      get('/delete_foo') { expire('/foo') }
    end
    get '/foo'
    assert_equal 200, status
    assert_equal 'test page', body
    get '/delete_foo'
    get '/foo'
    assert_equal 200, status
    assert_equal 'test page again', body
    refute_equal false, called
  end

  it 'should accept custom cache keys' do
    called = false
    mock_app do
      register Padrino::Cache
      enable :caching
      get '/foo', cache: true do
        if called
          "you'll never see me"
        else
          cache_key :foo
          called = 'foo'

          called
        end
      end

      get '/bar', cache: true do
        if called
          cache_key :bar
          called = 'bar'

          called
        else
          "you'll never see me"
        end
      end
    end
    get '/foo'
    assert_equal 200, status
    assert_equal 'foo', body
    assert_equal 'foo', @app.cache[:foo][:body]
    get '/foo'
    assert_equal 'foo', body

    get '/bar'
    assert_equal 200, status
    assert_equal 'bar', body
    assert_equal 'bar', @app.cache[:bar][:body]
    get '/bar'
    assert_equal 'bar', body
  end

  it 'should delete based on urls' do
    called = false
    mock_app do
      register Padrino::Cache
      enable :caching
      get(:foo, with: :id, cache: true) { called ? 'test page again' : (called = 'test page') }
      get(:delete_foo, with: :id) { expire(:foo, params[:id]) }
    end
    get '/foo/12'
    assert_equal 200, status
    assert_equal 'test page', body
    get '/delete_foo/12'
    get '/foo/12'
    assert_equal 200, status
    assert_equal 'test page again', body
  end

  it 'should allow controller-wide caching' do
    called = false
    mock_app do
      controller cache: true do
        register Padrino::Cache
        enable :caching
        get('/foo') { called ? halt(500) : (called = 'test') }
      end
    end
    get '/foo'
    assert_equal 200, status
    assert_equal 'test', body
    get '/foo'
    assert_equal 200, status
    assert_equal 'test', body
  end

  it 'should allow controller-wide expires' do
    called = false
    mock_app do
      register Padrino::Cache
      controller cache: true do
        enable :caching
        expires 1
        get('/foo') { called ? halt(500) : (called = 'test') }
      end
    end
    get '/foo'
    assert_equal 200, status
    assert_equal 'test', body
    get '/foo'
    assert_equal 200, status
    assert_equal 'test', body
    Time.stub(:now, Time.now + 2) { get '/foo' }
    assert_equal 500, status
  end

  it 'should allow cache disabling on a per route basis' do
    called = false
    mock_app do
      register Padrino::Cache
      enable :caching
      controller cache: true do
        get('/foo', cache: false) { called ? 'test again' : (called = 'test') }
      end
    end
    get '/foo'
    assert_equal 200, status
    assert_equal 'test', body
    get '/foo'
    assert_equal 200, status
    assert_equal 'test again', body
  end

  it 'should allow expiring for pages' do
    called = false
    mock_app do
      register Padrino::Cache
      enable :caching
      controller cache: true do
        get('/foo') do
          expires 1
          called ? 'test again' : (called = 'test')
        end
      end
    end
    get '/foo'
    assert_equal 200, status
    assert_equal 'test', body
    get '/foo'
    assert_equal 200, status
    assert_equal 'test', body
    Time.stub(:now, Time.now + 3) { get '/foo' }
    assert_equal 200, status
    assert_equal 'test again', body
  end

  it 'should allow expiring for fragments' do
    called = false
    mock_app do
      register Padrino::Cache
      enable :caching
      controller do
        get('/foo') do
          expires 1
          cache(:test, expires: 2) do
            called ? 'test again' : (called = 'test')
          end
        end
      end
    end
    get '/foo'
    assert_equal 200, status
    assert_equal 'test', body
    get '/foo'
    assert_equal 200, status
    assert_equal 'test', body
    Time.stub(:now, Time.now + 3) { get '/foo' }
    assert_equal 200, status
    assert_equal 'test again', body
  end

  it 'should allow disabling of the cache' do
    called = false
    mock_app do
      register Padrino::Cache
      disable :caching
      controller cache: true do
        get('/foo') { called ? halt(500) : (called = 'test') }
      end
    end
    get '/foo'
    assert_equal 200, status
    assert_equal 'test', body
    get '/foo'
    assert_equal 500, status
  end

  it 'should not cache integer statuses' do
    mock_app do
      register Padrino::Cache
      enable :caching
      get('/404', cache: true) { not_found }
      get('/503', cache: true) { error 503 }
      not_found { 'fancy 404' }
      error(503) { 'fancy 503' }
    end
    get '/404'
    assert_equal 'fancy 404', body
    assert_equal 404, status
    assert_nil @app.cache['/404']
    get '/404'
    assert_equal 'fancy 404', body
    assert_equal 404, status
    get '/503'
    assert_equal 'fancy 503', body
    assert_equal 503, status
    assert_nil @app.cache['/503']
    get '/503'
    assert_equal 'fancy 503', body
    assert_equal 503, status
  end

  it 'should cache should not hit with unique params' do
    call_count = 0
    mock_app do
      register Padrino::Cache
      enable :caching
      before do
        param = params[:test] || 'none'
        cache_key "foo?#{param}"
      end
      get '/foo/:test', cache: true do
        param = params[:test] || 'none'
        call_count += 1
        "foo?#{param}"
      end
    end

    get '/foo/none'
    get '/foo/none'
    assert_equal 200, status
    assert_equal 'foo?none', body
    assert_equal 1, call_count

    get '/foo/yes'
    assert_equal 'foo?yes', body
    assert_equal 2, call_count
  end

  it 'should not reuse a string cache key from another request' do
    mock_app do
      register Padrino::Cache
      enable :caching
      get '/post/:id', cache: true do
        cache_key "post-#{params[:id]}"
        "post #{params[:id]}"
      end
    end

    get '/post/1'
    assert_equal 'post 1', body
    get '/post/2'
    assert_equal 'post 2', body
    get '/post/1'
    assert_equal 'post 1', body
  end

  it 'should run controller before filters on a cached response' do
    mock_app do
      register Padrino::Cache
      enable :caching
      controller :secret, cache: true do
        before { halt 403, 'denied' unless params[:ok] }
        get(:index) { 'secret page' }
      end
    end

    get '/secret?ok=1'
    assert_equal 'secret page', body
    get '/secret'
    assert_equal 403, status
    assert_equal 'denied', body
  end

  it 'should use a cache key set in a controller before filter for the lookup' do
    calls = 0
    mock_app do
      register Padrino::Cache
      enable :caching
      controller :users, cache: true do
        before { cache_key "user-#{params[:u]}" }
        get(:show, with: :u) { calls += 1; "user #{params[:u]}" }
      end
    end

    get '/users/show/a'
    get '/users/show/b'
    get '/users/show/a'
    assert_equal 'user a', body
    assert_equal 2, calls
  end

  it 'should not apply a cache key to the next route after pass' do
    capture_io do
      mock_app do
        register Padrino::Cache
        enable :caching
        get '/x/:id', cache: true do
          cache_key :shared
          pass if params[:id] == 'skip'
          "A #{params[:id]}"
        end
        get('/x/:id', cache: true) { "B #{params[:id]}" }
      end

      get '/x/skip'
      assert_equal 'B skip', body
      get '/x/1'
      assert_equal 'A 1', body
    end
  end

  it 'should check route conditions on a cached response' do
    mock_app do
      register Padrino::Cache
      enable :caching
      def self.protect(protected)
        condition { halt 403, 'No secrets for you!' unless params[:key] == 's3cr3t' } if protected
      end
      controller cache: true, conditions: { protect: true } do
        get('/private') { 'secret stuff' }
      end
    end

    get '/private?key=s3cr3t'
    assert_equal 'secret stuff', body
    get '/private'
    assert_equal 403, status
    assert_equal 'No secrets for you!', body
  end

  it 'should keep a cache key from an app-level before filter for the route reached through pass' do
    capture_io do
      mock_app do
        register Padrino::Cache
        enable :caching
        before { cache_key "u-#{params[:u]}" }
        get('/z', cache: true) { pass }
        get('/z', cache: true) { "B for #{params[:u]}" }
      end

      get '/z?u=alice'
      assert_equal 'B for alice', body
      get '/z?u=bob'
      assert_equal 'B for bob', body
    end
  end

  it 'should keep expires to the request that set it' do
    stored = []
    store = Object.new
    store.define_singleton_method(:[]) { |_key| nil }
    store.define_singleton_method(:store) { |key, _value, options| stored << [key, options[:expires]] }
    mock_app do
      register Padrino::Cache
      enable :caching
      set :cache, store
      get '/foo', cache: true do
        expires 100 if params[:long]
        'foo'
      end
    end

    get '/foo?long=1'
    get '/foo'
    assert_equal [100, nil], stored.map(&:last)
    assert(stored.all? { |key, _| key.match?(%r{\A@\h{16}/foo\z}) })
    assert_equal 1, stored.map(&:first).uniq.size
  end

  it 'should let expires false in a handler override the route expiry' do
    stored = []
    store = Object.new
    store.define_singleton_method(:[]) { |_key| nil }
    store.define_singleton_method(:store) { |key, _value, options| stored << [key, options[:expires]] }
    mock_app do
      register Padrino::Cache
      enable :caching
      set :cache, store
      get '/ef', cache: true, expires: 60 do
        expires false
        'ef'
      end
    end

    get '/ef'
    assert_equal [false], stored.map(&:last)
    assert_match(%r{\A@\h{16}/ef\z}, stored.first.first)
  end

  it 'should resolve block cache keys' do
    call_count = 0
    mock_app do
      register Padrino::Cache
      enable :caching

      get '/foo', cache: true do
        cache_key { "key #{params[:id]}" }
        call_count += 1
        params[:id]
      end
    end

    get '/foo?id=1'
    get '/foo?id=2'
    get '/foo?id=2'
    get '/foo?id=1&something_else=42'
    get '/foo?id=3&something_else=42'

    assert_equal 3, call_count
  end

  it "should look a page up under the route's own cache key from the first request" do
    calls = 0
    mock_app do
      register Padrino::Cache
      enable :caching
      get '/dash', cache: true do
        cache_key { "dash-#{params[:u]}" }
        calls += 1
        "page for #{params[:u]}"
      end
    end
    @app.cache.store('/dash', { body: 'stored under the path', content_type: 'text/html' })

    get '/dash?u=alice'
    assert_equal 'page for alice', body
    get '/dash?u=bob'
    assert_equal 'page for bob', body
    get '/dash?u=alice'
    assert_equal 'page for alice', body
    assert_equal 2, calls
  end

  it 'should not serve a page stored under another key to a route with a Symbol cache key' do
    calls = 0
    mock_app do
      register Padrino::Cache
      enable :caching
      get '/about', cache: true do
        cache_key :about
        calls += 1
        'about page'
      end
    end
    @app.cache.store('/about', { body: 'stored under the path', content_type: 'text/html' })

    head '/about'
    assert_equal 1, calls
    get '/about'
    assert_equal 'about page', body
    get '/about'
    assert_equal 'about page', body
    assert_equal 1, calls
  end

  it 'should not serve a page stored under the path to a route that sets a String cache key in its body' do
    mock_app do
      register Padrino::Cache
      enable :caching
      get '/post/:id', cache: true do
        cache_key "post-#{params[:id]}"
        "post #{params[:id]}"
      end
    end
    @app.cache.store('/post/1', { body: 'stored under the path', content_type: 'text/html' })

    2.times { get '/post/1' }
    assert_equal 'post 1', body
  end

  it 'should not serve the page of another route on the same path to a route with a block cache key' do
    mock_app do
      register Padrino::Cache
      enable :caching
      get('/p', cache: true, agent: /bot/) { 'bot page' }
      get '/p', cache: true do
        cache_key { "p-#{params[:u]}" }
        "page for #{params[:u]}"
      end
    end

    get '/p', {}, 'HTTP_USER_AGENT' => 'bot'
    assert_equal 'bot page', body
    get '/p?u=alice', {}, 'HTTP_USER_AGENT' => 'browser'
    assert_equal 'page for alice', body
    get '/p', {}, 'HTTP_USER_AGENT' => 'bot'
    assert_equal 'bot page', body
  end

  it 'should raise an error if providing both a cache_key and block' do
    mock_app do
      register Padrino::Cache
      enable :caching

      get '/foo', cache: true do
        cache_key(:some_key) { "key #{params[:id]}" }
      end
    end

    assert_raises(RuntimeError) { get '/foo' }
  end

  it 'should cache content_type' do
    called = false
    mock_app do
      register Padrino::Cache
      enable :caching
      get '/foo', cache: true do
        content_type :json
        if called
          "you'll never see me"
        else
          cache_key :foo
          called = '{"foo":"bar"}'

          called
        end
      end
    end
    get '/foo'
    assert_equal 200, status
    assert_equal '{"foo":"bar"}', body
    assert_equal '{"foo":"bar"}', @app.cache[:foo][:body]
    get '/foo'
    assert_equal '{"foo":"bar"}', body
    assert_match(/json/, last_response.content_type)
  end

  it 'should cache an object' do
    counter = 0
    mock_app do
      register Padrino::Cache
      enable :caching
      get '/' do
        result = ''
        2.times do
          result = cache_object 'object1' do
            counter += 1
            { foo: 'bar' }
          end
        end
        result[:foo].to_s
      end
    end
    get '/'
    assert_equal 'bar', body
    assert_equal 1, counter
  end

  it 'should allow different expiring times for different pages' do
    skip
    called_times_a = 0
    called_times_b = 0
    mock_app do
      register Padrino::Cache
      enable :caching
      controller cache: true do
        get('/foo') do
          expires 1
          called_times_a += 1
          called_times_b.to_s
        end
        get('/bar') do
          expires 3
          called_times_b += 1
          called_times_b.to_s
        end
      end
    end
    Time.stub(:now, Time.now) { get '/foo'; get '/bar' }
    assert_equal 1, called_times_a
    assert_equal 1, called_times_b
    Time.stub(:now, Time.now + 0.5) { get '/foo'; get '/bar' }
    assert_equal 1, called_times_a
    assert_equal 1, called_times_b
    Time.stub(:now, Time.now + 2) { get '/foo'; get '/bar' }
    assert_equal 2, called_times_a
    assert_equal 1, called_times_b
    Time.stub(:now, Time.now + 2.5) { get '/foo'; get '/bar' }
    assert_equal 2, called_times_a
    assert_equal 1, called_times_b
    Time.stub(:now, Time.now + 4) { get '/foo'; get '/bar' }
    assert_equal 3, called_times_a
    assert_equal 2, called_times_b
    Time.stub(:now, Time.now + 5.5) { get '/foo'; get '/bar' }
    assert_equal 4, called_times_a
    assert_equal 2, called_times_b
  end

  it "preserve the app's `caching` setting if set before registering the module" do
    mock_app do
      enable :caching
      register Padrino::Cache
    end

    assert @app.caching
  end

  it "preserve the app's `cache` setting if set before registering the module" do
    mock_app do
      set :cache, Padrino::Cache.new(:Memory)
      register Padrino::Cache
    end

    adapter = @app.cache.adapter
    adapter = adapter.adapter while adapter.respond_to?(:adapter)
    assert_kind_of Moneta::Adapters::Memory, adapter
  end

  describe 'default store' do
    def standalone_app(text, base = Sinatra.new)
      base.class_eval do
        register Padrino::Routing
        register Padrino::Cache
        enable :caching
        get('/foo', cache: true) { text }
      end
      base
    end

    def store_adapter(app)
      adapter = app.cache.adapter
      adapter = adapter.adapter while adapter.respond_to?(:adapter)
      adapter
    end

    it 'should keep the cache directory of a Padrino app at tmp/<app_name>/cache' do
      mock_app { register Padrino::Cache }
      assert_equal Padrino.root('tmp', @app.app_name.to_s, 'cache'), store_adapter(@app).config.dir
    end

    it 'should give each named Sinatra app its own store' do
      Object.const_set(:CacheSpecShop, Class.new(Sinatra::Base))
      Object.const_set(:CacheSpecNs, Module.new)
      CacheSpecNs.const_set(:CacheSpecShop, Class.new(Sinatra::Base))
      Object.const_set(:CacheSpecBlog, Class.new(Sinatra::Base))
      @app = Rack::URLMap.new(
        '/shop' => standalone_app('top-level shop', CacheSpecShop),
        '/ns' => standalone_app('namespaced shop', CacheSpecNs::CacheSpecShop),
        '/blog' => standalone_app('blog', CacheSpecBlog)
      )
      2.times do
        get '/shop/foo'
        assert_equal 'top-level shop', body
        get '/ns/foo'
        assert_equal 'namespaced shop', body
        get '/blog/foo'
        assert_equal 'blog', body
      end
      assert_equal Padrino.root('tmp', 'cache_spec_ns', 'cache_spec_shop', 'cache'), store_adapter(CacheSpecNs::CacheSpecShop).config.dir
    ensure
      %i[CacheSpecShop CacheSpecNs CacheSpecBlog].each { |name| Object.send(:remove_const, name) if Object.const_defined?(name, false) }
    end

    it 'should give each anonymous Sinatra app its own store' do
      @app = Rack::URLMap.new('/a' => standalone_app('from A'), '/b' => standalone_app('from B'))
      2.times do
        get '/a/foo'
        assert_equal 'from A', body
        get '/b/foo'
        assert_equal 'from B', body
      end
    end
  end

  it 'should check key existence' do
    count1, count2 = 0, 0
    mock_app do
      register Padrino::Cache
      enable :caching
      get '/' do
        cache(:foo) do
          count1 += 1
          nil
        end
        count1.inspect
      end

      get '/object' do
        cache_object(:bar) do
          count2 += 1
          nil
        end
        count2.inspect
      end
    end
    2.times { get '/' }
    assert_equal '1', body
    2.times { get '/object' }
    assert_equal '1', body
  end

  it 'should cache full mime type of content_type' do
    mock_app do
      register Padrino::Cache
      enable :caching
      get '/foo', cache: true do
        content_type :json, charset: 'utf-8'
        '{}'
      end
    end
    get '/foo'
    assert_equal 'application/json;charset=utf-8', last_response.content_type
    get '/foo'
    assert_equal 'application/json;charset=utf-8', last_response.content_type
  end

  it 'should keep cached fragment escaping with LRUHash store' do
    mock_app do
      register Padrino::Cache
      register Padrino::Helpers
      enable :caching
      set :cache, Padrino::Cache.new(:LRUHash)
      get '/plain' do
        erb '<div><%= cache(:plain_frag) { "<b>escaped</b>" } %></div>'
      end
      get '/safe' do
        erb '<div><%= cache(:safe_frag) { "<b>raw</b>".html_safe } %></div>'
      end
    end

    2.times do
      get '/plain'
      assert_equal '<div>&lt;b&gt;escaped&lt;/b&gt;</div>', body
    end

    2.times do
      get '/safe'
      assert_equal '<div><b>raw</b></div>', body
    end
  end

  it 'should keep cached fragment escaping with File store' do
    dir = Dir.mktmpdir('padrino-cache-frag-file')
    begin
      mock_app do
        register Padrino::Cache
        register Padrino::Helpers
        enable :caching
        set :cache, Padrino::Cache.new(:File, dir: dir)
        get '/plain' do
          erb '<div><%= cache(:plain_frag) { "<b>escaped</b>" } %></div>'
        end
        get '/safe' do
          erb '<div><%= cache(:safe_frag) { "<b>raw</b>".html_safe } %></div>'
        end
      end

      2.times do
        get '/plain'
        assert_equal '<div>&lt;b&gt;escaped&lt;/b&gt;</div>', body
      end

      2.times do
        get '/safe'
        assert_equal '<div><b>raw</b></div>', body
      end

      refute_empty Dir.children(dir)
    ensure
      FileUtils.remove_entry(dir) if dir && Dir.exist?(dir)
    end
  end

  it 'should re-escape cached html_safe fragment in a store that does not preserve string class' do
    plain_store = Class.new(Hash) do
      def store(key, value, _options = {})
        super(key, value.is_a?(String) ? String.new(value) : value)
      end
    end.new
    mock_app do
      register Padrino::Cache
      register Padrino::Helpers
      enable :caching
      set :cache, plain_store
      get '/safe' do
        erb '<div><%= cache(:plain_safe_frag) { "<b>ok</b>".html_safe } %></div>'
      end
    end

    get '/safe'
    assert_equal '<div><b>ok</b></div>', body

    get '/safe'
    assert_equal '<div>&lt;b&gt;ok&lt;/b&gt;</div>', body
  end
  it 'should keep separate cached pages for same-path routes with different conditions' do
    mock_app do
      register Padrino::Cache
      enable :caching
      set(:variant) { |v| condition { params[:v] == v.to_s } }
      get('/p', cache: true, variant: :alpha) { 'page A' }
      get('/p', cache: true) { 'page B' }
    end

    get '/p'
    assert_equal 'page B', body
    get '/p?v=alpha'
    assert_equal 'page A', body
    get '/p'
    assert_equal 'page B', body
  end

  it 'should keep separate cached pages for routes with distinct condition options on the same path' do
    mock_app do
      register Padrino::Cache
      enable :caching
      set(:tier) { |level| condition { params[:tier] == level.to_s } }
      get('/p', cache: true, tier: :one) { 'view 1' }
      get('/p', cache: true, tier: :two) { 'view 2' }
      get('/p', cache: true, tier: :three) { 'view 3' }
    end

    get '/p?tier=one'
    assert_equal 'view 1', body
    get '/p?tier=two'
    assert_equal 'view 2', body
    get '/p?tier=three'
    assert_equal 'view 3', body
    get '/p?tier=one'
    assert_equal 'view 1', body
  end

  it 'should isolate cached pages for routes defined inside a loop with different option values' do
    mock_app do
      register Padrino::Cache
      enable :caching
      set(:tier) { |level| condition { params[:tier] == level.to_s } }
      %i[alpha beta].each do |level|
        get('/dash', cache: true, tier: level) { "dash #{level}" }
      end
    end

    get '/dash?tier=alpha'
    assert_equal 'dash alpha', body
    get '/dash?tier=beta'
    assert_equal 'dash beta', body
    get '/dash?tier=alpha'
    assert_equal 'dash alpha', body
  end

  it 'should keep separate cached pages for same-path routes with different host matchers' do
    Dir.mktmpdir do |dir|
      Object.const_set(:HostMatcherDeployApp, Class.new(Padrino::Application) do
        register Padrino::Cache
        enable :caching
        set :app_name, :host_matcher_deploy
        set :cache, Padrino::Cache.new(:File, dir: dir)
        get('/h/:id', cache: true, host: 'a.example.com') { "host A #{params[:id]}" }
      end)
      s1 = Rack::Test::Session.new(Rack::MockSession.new(Object::HostMatcherDeployApp))
      s1.get '/h/1', {}, 'HTTP_HOST' => 'a.example.com'
      assert_equal 'host A 1', s1.last_response.body

      Object.send(:remove_const, :HostMatcherDeployApp)
      Object.const_set(:HostMatcherDeployApp, Class.new(Padrino::Application) do
        register Padrino::Cache
        enable :caching
        set :app_name, :host_matcher_deploy
        set :cache, Padrino::Cache.new(:File, dir: dir)
        get('/h/:id', cache: true, host: /\.example\.com\z/) { "host regex #{params[:id]}" }
      end)
      s2 = Rack::Test::Session.new(Rack::MockSession.new(Object::HostMatcherDeployApp))
      s2.get '/h/2', {}, 'HTTP_HOST' => 'a.example.com'
      assert_equal 'host regex 2', s2.last_response.body
      s2.get '/h/1', {}, 'HTTP_HOST' => 'a.example.com'
      assert_equal 'host regex 1', s2.last_response.body
    ensure
      Object.send(:remove_const, :HostMatcherDeployApp) if Object.const_defined?(:HostMatcherDeployApp, false)
    end
  end

  it 'should keep separate cached pages per request host for a regexp host matcher' do
    mock_app do
      register Padrino::Cache
      enable :caching
      get('/rh', cache: true, host: /\.example\.com\z/) { "host #{request.host}" }
    end

    get '/rh', {}, 'HTTP_HOST' => 'one.example.com'
    assert_equal 'host one.example.com', body
    get '/rh', {}, 'HTTP_HOST' => 'two.example.com'
    assert_equal 'host two.example.com', body
    get '/rh', {}, 'HTTP_HOST' => 'one.example.com'
    assert_equal 'host one.example.com', body
  end

  it 'should isolate cached pages across two named app classes sharing one cache store' do
    shared_store = Padrino::Cache.new(:Memory)
    Object.const_set(:SharedCacheAppAlpha, Class.new(Padrino::Application) do
      register Padrino::Cache
      enable :caching
      set :app_name, :shared_site
      set :cache, shared_store
      get('/same/:id', cache: true) { "alpha #{params[:id]}" }
    end)
    Object.const_set(:SharedCacheAppBeta, Class.new(Padrino::Application) do
      register Padrino::Cache
      enable :caching
      set :app_name, :shared_site
      set :cache, shared_store
      get('/same/:id', cache: true) { "beta #{params[:id]}" }
    end)

    sa = Rack::Test::Session.new(Rack::MockSession.new(Object::SharedCacheAppAlpha))
    sb = Rack::Test::Session.new(Rack::MockSession.new(Object::SharedCacheAppBeta))
    sa.get '/same/1'
    assert_equal 'alpha 1', sa.last_response.body
    sb.get '/same/2'
    assert_equal 'beta 2', sb.last_response.body
    sb.get '/same/1'
    assert_equal 'beta 1', sb.last_response.body
  ensure
    Object.send(:remove_const, :SharedCacheAppAlpha) if Object.const_defined?(:SharedCacheAppAlpha, false)
    Object.send(:remove_const, :SharedCacheAppBeta) if Object.const_defined?(:SharedCacheAppBeta, false)
  end

  it 'should isolate cached pages across two anonymous app classes with the same app_name on one store' do
    shared_store = Padrino::Cache.new(:Memory)
    app_a = Class.new(Padrino::Application) do
      register Padrino::Cache
      enable :caching
      set :app_name, :same_anon_app
      set :cache, shared_store
      get('/same/:id', cache: true) { "app A #{params[:id]}" }
    end
    app_b = Class.new(Padrino::Application) do
      register Padrino::Cache
      enable :caching
      set :app_name, :same_anon_app
      set :cache, shared_store
      get('/same/:id', cache: true) { "app B #{params[:id]}" }
    end

    sa = Rack::Test::Session.new(Rack::MockSession.new(Rack::Lint.new(app_a)))
    sb = Rack::Test::Session.new(Rack::MockSession.new(Rack::Lint.new(app_b)))
    sa.get '/same/1'
    assert_equal 'app A 1', sa.last_response.body
    sb.get '/same/2'
    assert_equal 'app B 2', sb.last_response.body
    sb.get '/same/1'
    assert_equal 'app B 1', sb.last_response.body
  end

  it 'should isolate anonymous apps with the same app_name across separate processes on one File store' do
    Dir.mktmpdir do |dir|
      store_dir = File.join(dir, 'store')
      script = File.join(dir, 'worker.rb')
      File.write(script, <<~RUBY)
        require 'padrino-core'
        require 'padrino-cache'
        require 'rack/test'

        store_dir, mode, out_file = ARGV
        store = Padrino::Cache.new(:File, dir: store_dir)
        app_a = Class.new(Padrino::Application) do
          register Padrino::Cache
          enable :caching
          set :app_name, :site
          set :cache, store
          get('/doc/:id', cache: true) { "page A \#{params[:id]}" }
        end
        app_b = Class.new(Padrino::Application) do
          register Padrino::Cache
          enable :caching
          set :app_name, :site
          set :cache, store
          get('/doc/:id', cache: true) { "page B \#{params[:id]}" }
        end
        sa = Rack::Test::Session.new(Rack::MockSession.new(app_a))
        sb = Rack::Test::Session.new(Rack::MockSession.new(app_b))
        body = if mode == 'first'
                 sa.get('/doc/1').body
               else
                 sb.get('/doc/2')
                 sb.get('/doc/1').body
               end
        File.write(out_file, body)
      RUBY

      load_flags = [
        File.expand_path('../lib', __dir__),
        File.expand_path('../../padrino-core/lib', __dir__),
        File.expand_path('../../padrino-helpers/lib', __dir__),
        File.expand_path('../../padrino-support/lib', __dir__)
      ].flat_map { |p| ['-I', p] }

      out1 = File.join(dir, 'out1.txt')
      out2 = File.join(dir, 'out2.txt')
      assert system(RbConfig.ruby, *load_flags, script, store_dir, 'first', out1, out: File::NULL, err: File::NULL)
      assert_equal 'page A 1', File.read(out1)
      assert system(RbConfig.ruby, *load_flags, script, store_dir, 'second', out2, out: File::NULL, err: File::NULL)
      assert_equal 'page B 1', File.read(out2)
    end
  end

  it 'should give one anonymous app definition the same page keys in every process' do
    Dir.mktmpdir do |dir|
      store_dir = File.join(dir, 'store')
      script = File.join(dir, 'worker.rb')
      File.write(script, <<~RUBY)
        require 'padrino-core'
        require 'padrino-cache'
        require 'rack/test'

        store_dir = ARGV.first
        app = Class.new(Padrino::Application) do
          register Padrino::Cache
          enable :caching
          set :cache, Padrino::Cache.new(:File, dir: store_dir)
          get('/doc', cache: true) { 'doc' }
        end
        Rack::Test::Session.new(Rack::MockSession.new(app)).get('/doc')
      RUBY

      load_flags = [
        File.expand_path('../lib', __dir__),
        File.expand_path('../../padrino-core/lib', __dir__),
        File.expand_path('../../padrino-helpers/lib', __dir__),
        File.expand_path('../../padrino-support/lib', __dir__)
      ].flat_map { |p| ['-I', p] }

      2.times { assert system(RbConfig.ruby, *load_flags, script, store_dir, out: File::NULL, err: File::NULL) }
      assert_equal 1, Dir.children(store_dir).size
    end
  end

  it 'should isolate cached pages when app_name changes for a named class on a persistent File store' do
    Dir.mktmpdir do |dir|
      Object.const_set(:RenamedAppIdApp, Class.new(Padrino::Application) do
        register Padrino::Cache
        enable :caching
        set :app_name, :site_alpha
        set :cache, Padrino::Cache.new(:File, dir: dir)
        get('/doc/:id', cache: true) { "alpha #{params[:id]}" }
      end)
      s1 = Rack::Test::Session.new(Rack::MockSession.new(Object::RenamedAppIdApp))
      s1.get '/doc/1'
      assert_equal 'alpha 1', s1.last_response.body

      Object.send(:remove_const, :RenamedAppIdApp)
      Object.const_set(:RenamedAppIdApp, Class.new(Padrino::Application) do
        register Padrino::Cache
        enable :caching
        set :app_name, :site_beta
        set :cache, Padrino::Cache.new(:File, dir: dir)
        get('/doc/:id', cache: true) { "beta #{params[:id]}" }
      end)
      s2 = Rack::Test::Session.new(Rack::MockSession.new(Object::RenamedAppIdApp))
      s2.get '/doc/2'
      assert_equal 'beta 2', s2.last_response.body
      s2.get '/doc/1'
      assert_equal 'beta 1', s2.last_response.body
    ensure
      Object.send(:remove_const, :RenamedAppIdApp) if Object.const_defined?(:RenamedAppIdApp, false)
    end
  end

  it 'should isolate cached pages when the same app class is mounted at two SCRIPT_NAME prefixes' do
    shared_store = Padrino::Cache.new(:Memory)
    app_cls = Class.new(Padrino::Application) do
      register Padrino::Cache
      enable :caching
      set :cache, shared_store
      get('/page', cache: true) { "mount=#{request.script_name}" }
    end

    router = Padrino::Router.new do
      map(path: '/one', to: app_cls)
      map(path: '/two', to: app_cls)
    end
    session = Rack::Test::Session.new(Rack::MockSession.new(router))
    session.get '/one/page'
    assert_equal 'mount=/one', session.last_response.body
    session.get '/two/page'
    assert_equal 'mount=/two', session.last_response.body
    session.get '/one/page'
    assert_equal 'mount=/one', session.last_response.body
  end

  it 'should keep host mappings apart when an inner router maps the same app class' do
    shared_store = Padrino::Cache.new(:Memory)
    app_cls = Class.new(Padrino::Application) do
      register Padrino::Cache
      enable :caching
      set :cache, shared_store
      get('/', cache: true) { "host=#{request.host}" }
    end
    inner_one = Padrino::Router.new { map(path: '/', to: app_cls) }
    inner_two = Padrino::Router.new { map(path: '/', to: app_cls) }
    router = Padrino::Router.new do
      map(path: '/', host: 'one.example.org', to: inner_one)
      map(path: '/', host: 'two.example.org', to: inner_two)
    end
    session = Rack::Test::Session.new(Rack::MockSession.new(router))
    2.times do
      session.get '/', {}, 'HTTP_HOST' => 'one.example.org'
      assert_equal 'host=one.example.org', session.last_response.body
      session.get '/', {}, 'HTTP_HOST' => 'two.example.org'
      assert_equal 'host=two.example.org', session.last_response.body
    end
  end

  it 'should keep outer host mappings apart when inner routers map the same app class by host too' do
    shared_store = Padrino::Cache.new(:Memory)
    app_cls = Class.new(Padrino::Application) do
      register Padrino::Cache
      enable :caching
      set :cache, shared_store
      get('/', cache: true) { "host=#{request.host}" }
    end
    inner_one = Padrino::Router.new { map(path: '/', host: /example\.org/, to: app_cls) }
    inner_two = Padrino::Router.new { map(path: '/', host: /example\.org/, to: app_cls) }
    router = Padrino::Router.new do
      map(path: '/', host: 'one.example.org', to: inner_one)
      map(path: '/', host: 'two.example.org', to: inner_two)
    end
    session = Rack::Test::Session.new(Rack::MockSession.new(router))
    2.times do
      session.get '/', {}, 'HTTP_HOST' => 'one.example.org'
      assert_equal 'host=one.example.org', session.last_response.body
      session.get '/', {}, 'HTTP_HOST' => 'two.example.org'
      assert_equal 'host=two.example.org', session.last_response.body
    end
  end

  it 'should give the next app in a cascade the host mapping marker it was reached with' do
    shared_store = Padrino::Cache.new(:Memory)
    other = Class.new(Padrino::Application) { get('/elsewhere') { 'elsewhere' } }
    app_cls = Class.new(Padrino::Application) do
      register Padrino::Cache
      enable :caching
      set :cache, shared_store
      get('/x', cache: true) { "host=#{request.host}" }
    end
    inner = Padrino::Router.new { map(path: '/', host: 'one.example.org', to: other) }
    router = Padrino::Router.new do
      map(path: '/', host: 'one.example.org', to: Rack::Cascade.new([inner, app_cls]))
      map(path: '/', to: app_cls)
    end
    session = Rack::Test::Session.new(Rack::MockSession.new(router))
    2.times do
      session.get '/x', {}, 'HTTP_HOST' => 'one.example.org'
      assert_equal 'host=one.example.org', session.last_response.body
      session.get '/x', {}, 'HTTP_HOST' => 'two.example.org'
      assert_equal 'host=two.example.org', session.last_response.body
    end
  end

  it 'should expire pages from a stream block in an app behind a host mapping' do
    calls = 0
    app_cls = Class.new(Padrino::Application) do
      register Padrino::Cache
      enable :caching
      get('/x', cache: true) { "x #{calls += 1}" }
      get('/sclear') { stream { |out| expire('/x'); out << 'cleared' } }
    end
    router = Padrino::Router.new { map(path: '/', host: 'one.example.org', to: app_cls) }
    session = Rack::Test::Session.new(Rack::MockSession.new(router))
    session.get '/x', {}, 'HTTP_HOST' => 'one.example.org'
    session.get '/x', {}, 'HTTP_HOST' => 'one.example.org'
    assert_equal 'x 1', session.last_response.body
    session.get '/sclear', {}, 'HTTP_HOST' => 'one.example.org'
    assert_equal 'cleared', session.last_response.body
    session.get '/x', {}, 'HTTP_HOST' => 'one.example.org'
    assert_equal 'x 2', session.last_response.body
  end

  it 'should expire pages from a stream block in an app mounted with Rack::Builder' do
    calls = 0
    app_cls = Class.new(Padrino::Application) do
      register Padrino::Cache
      enable :caching
      get('/x', cache: true) { "x #{calls += 1}" }
      get('/sclear') { stream { |out| expire('/x'); out << 'cleared' } }
    end
    builder = Rack::Builder.new { map('/blog') { run app_cls } }
    session = Rack::Test::Session.new(Rack::MockSession.new(builder))
    session.get '/blog/x'
    session.get '/blog/x'
    assert_equal 'x 1', session.last_response.body
    session.get '/blog/sclear'
    assert_equal 'cleared', session.last_response.body
    session.get '/blog/x'
    assert_equal 'x 2', session.last_response.body
  end

  it 'should expire a provides page stored without a negotiated format' do
    version = 0
    mock_app do
      register Padrino::Cache
      enable :caching
      get('/r', cache: true, provides: %i[html txt]) { "v#{version}" }
      get('/bump') { version += 1; expire('/r'); 'ok' }
    end

    get '/r', {}, 'HTTP_ACCEPT' => 'text/plain, */*'
    get '/r', {}, 'HTTP_ACCEPT' => 'text/plain, */*'
    assert_equal 'v0', body
    get '/bump'
    get '/r', {}, 'HTTP_ACCEPT' => 'text/plain, */*'
    assert_equal 'v1', body
  end

  it 'should expire a provides page when a filter set another content type first' do
    version = 0
    mock_app do
      register Padrino::Cache
      enable :caching
      before { content_type :json }
      get('/r', cache: true, provides: %i[html txt]) { "v#{version}" }
      get('/bump') { version += 1; expire('/r'); 'ok' }
    end

    get '/r', {}, 'HTTP_ACCEPT' => 'text/plain, */*'
    get '/r', {}, 'HTTP_ACCEPT' => 'text/plain, */*'
    assert_equal 'v0', body
    get '/bump'
    get '/r', {}, 'HTTP_ACCEPT' => 'text/plain, */*'
    assert_equal 'v1', body
  end

  it 'should not leave a host mapping marker behind for the next app in a cascade' do
    calls = 0
    other = Class.new(Padrino::Application) { get('/elsewhere') { 'elsewhere' } }
    cached = Class.new(Padrino::Application) do
      register Padrino::Cache
      enable :caching
      get('/x', cache: true) { "x #{calls += 1}" }
      get('/clear') { expire('/x'); 'cleared' }
    end
    app = Rack::Cascade.new([Padrino::Router.new { map(path: '/', host: 'one.example.org', to: other) }, cached])
    session = Rack::Test::Session.new(Rack::MockSession.new(app))
    session.get '/x', {}, 'HTTP_HOST' => 'one.example.org'
    session.get '/x', {}, 'HTTP_HOST' => 'one.example.org'
    assert_equal 'x 1', session.last_response.body
    session.get '/clear', {}, 'HTTP_HOST' => 'two.example.org'
    session.get '/x', {}, 'HTTP_HOST' => 'one.example.org'
    assert_equal 'x 2', session.last_response.body
  end

  it 'should keep the default page key of an anonymous app when its routes are rebuilt' do
    calls = 0
    mock_app do
      register Padrino::Cache
      enable :caching
      get('/anon', cache: true) { "anon #{calls += 1}" }
    end

    get '/anon'
    get '/anon'
    assert_equal 'anon 1', body
    @app.set :cache_namespace, 'other'
    get '/anon'
    @app.set :cache_namespace, nil
    get '/anon'
    assert_equal 'anon 1', body
  end

  it 'should keep default page keys apart from request paths' do
    stored = []
    store = Object.new
    store.define_singleton_method(:[]) { |_key| nil }
    store.define_singleton_method(:store) { |key, _value, _options = {}| stored << key }
    mock_app do
      register Padrino::Cache
      enable :caching
      set :cache, store
      get('/page', cache: true) { 'page' }
    end

    get '/page'
    assert_equal 1, stored.size
    refute stored.first.start_with?('/')
  end

  it 'should not share a cached GET page with a separately defined HEAD route' do
    mock_app do
      register Padrino::Cache
      enable :caching
      set(:tier) { |v| condition { params[:tier] == v.to_s } }
      route('GET', '/s/:id', tier: :plus, cache: true) do
        content_type :json
        "{\"view\":\"plus #{params[:id]}\"}"
      end
      route('HEAD', '/s/:id', cache: true) { '' }
    end

    get '/s/1?tier=plus'
    assert_equal '{"view":"plus 1"}', body
    head '/s/1'
    assert_equal 200, status
    assert_equal '', body
    get '/s/1?tier=plus'
    assert_equal '{"view":"plus 1"}', body
  end

  it 'should isolate cached pages across inheritance router depth levels on one store' do
    shared_store = Padrino::Cache.new(:Memory)
    parent = Class.new(Padrino::Application) do
      register Padrino::Cache
      enable :caching
      set :cache, shared_store
      condition { params[:v] == 'parent' }
      get('/d', cache: true) { 'parent page' }
    end
    child = Class.new(parent) do
      condition { params[:v] == 'child' }
      get('/d', cache: true) { 'child page' }
    end

    sc = Rack::Test::Session.new(Rack::MockSession.new(child))
    sc.get '/d?v=child'
    assert_equal 'child page', sc.last_response.body
    sc.get '/d?v=parent'
    assert_equal 'parent page', sc.last_response.body
    sc.get '/d?v=child'
    assert_equal 'child page', sc.last_response.body
  end

  it 'should not serve a stale cached page from a persistent File store after removing a conditional route' do
    Dir.mktmpdir do |dir|
      Object.const_set(:DeployRouteChangeApp, Class.new(Padrino::Application) do
        register Padrino::Cache
        enable :caching
        set :app_name, :deploy_route_change
        set :cache, Padrino::Cache.new(:File, dir: dir)
        set(:tier) { |v| condition { params[:tier] == v.to_s } }
        get('/doc/:id', cache: true, tier: :plus) { "plus #{params[:id]}" }
      end)

      s1 = Rack::Test::Session.new(Rack::MockSession.new(Object::DeployRouteChangeApp))
      s1.get '/doc/1?tier=plus'
      assert_equal 'plus 1', s1.last_response.body

      Object.send(:remove_const, :DeployRouteChangeApp)
      Object.const_set(:DeployRouteChangeApp, Class.new(Padrino::Application) do
        register Padrino::Cache
        enable :caching
        set :app_name, :deploy_route_change
        set :cache, Padrino::Cache.new(:File, dir: dir)
        get('/doc/:id', cache: true) { "basic #{params[:id]}" }
      end)

      s2 = Rack::Test::Session.new(Rack::MockSession.new(Object::DeployRouteChangeApp))
      s2.get '/doc/2'
      assert_equal 'basic 2', s2.last_response.body
      s2.get '/doc/1'
      assert_equal 'basic 1', s2.last_response.body
    ensure
      Object.send(:remove_const, :DeployRouteChangeApp) if Object.const_defined?(:DeployRouteChangeApp, false)
    end
  end

  it 'should not serve a stale cached page from a persistent File store after adding an inherited app-level before filter' do
    Dir.mktmpdir do |dir|
      base_v1 = Class.new(Padrino::Application) do
        register Padrino::Cache
        enable :caching
      end
      Object.const_set(:DeployBeforeFilterApp, Class.new(base_v1) do
        set :app_name, :deploy_before_filter
        set :cache, Padrino::Cache.new(:File, dir: dir)
        get('/doc/:id', cache: true) { "unfiltered #{params[:id]}" }
      end)

      s1 = Rack::Test::Session.new(Rack::MockSession.new(Object::DeployBeforeFilterApp))
      s1.get '/doc/1'
      assert_equal 'unfiltered 1', s1.last_response.body

      Object.send(:remove_const, :DeployBeforeFilterApp)
      base_v2 = Class.new(Padrino::Application) do
        register Padrino::Cache
        enable :caching
        before { halt 403 unless params[:ok] == '1' }
      end
      Object.const_set(:DeployBeforeFilterApp, Class.new(base_v2) do
        set :app_name, :deploy_before_filter
        set :cache, Padrino::Cache.new(:File, dir: dir)
        get('/doc/:id', cache: true) { "filtered #{params[:id]}" }
      end)

      s2 = Rack::Test::Session.new(Rack::MockSession.new(Object::DeployBeforeFilterApp))
      s2.get '/doc/2?ok=1'
      assert_equal 'filtered 2', s2.last_response.body
      s2.get '/doc/1?ok=1'
      assert_equal 'filtered 1', s2.last_response.body
    ensure
      Object.send(:remove_const, :DeployBeforeFilterApp) if Object.const_defined?(:DeployBeforeFilterApp, false)
    end
  end

  it 'should not serve a stale cached page from a persistent File store after adding a controller before filter' do
    Dir.mktmpdir do |dir|
      Object.const_set(:DeployRouteBeforeApp, Class.new(Padrino::Application) do
        register Padrino::Cache
        enable :caching
        set :app_name, :deploy_route_before
        set :cache, Padrino::Cache.new(:File, dir: dir)
        controller '/c' do
          get('/doc/:id', cache: true) { "v1 #{params[:id]}" }
        end
      end)

      s1 = Rack::Test::Session.new(Rack::MockSession.new(Object::DeployRouteBeforeApp))
      s1.get '/c/doc/1'
      assert_equal 'v1 1', s1.last_response.body

      Object.send(:remove_const, :DeployRouteBeforeApp)
      Object.const_set(:DeployRouteBeforeApp, Class.new(Padrino::Application) do
        register Padrino::Cache
        enable :caching
        set :app_name, :deploy_route_before
        set :cache, Padrino::Cache.new(:File, dir: dir)
        controller '/c' do
          before { @tag = 'checked' }
          get('/doc/:id', cache: true) { "v2 #{params[:id]}" }
        end
      end)

      s2 = Rack::Test::Session.new(Rack::MockSession.new(Object::DeployRouteBeforeApp))
      s2.get '/c/doc/2'
      assert_equal 'v2 2', s2.last_response.body
      s2.get '/c/doc/1'
      assert_equal 'v2 1', s2.last_response.body
    ensure
      Object.send(:remove_const, :DeployRouteBeforeApp) if Object.const_defined?(:DeployRouteBeforeApp, false)
    end
  end

  it 'should keep cache keys stable across route reordering when each route has a unique name' do
    Dir.mktmpdir do |dir|
      calls = Hash.new(0)
      Object.const_set(:NamedReorderApp, Class.new(Padrino::Application) do
        register Padrino::Cache
        enable :caching
        set :app_name, :named_reorder
        set :cache, Padrino::Cache.new(:File, dir: dir)
        condition { params[:v] == 'a' }
        get(:view_a, map: '/item/:id', cache: true) { "A #{params[:id]} ##{calls[:a] += 1}" }
        condition { params[:v] == 'b' }
        get(:view_b, map: '/item/:id', cache: true) { "B #{params[:id]} ##{calls[:b] += 1}" }
      end)

      s1 = Rack::Test::Session.new(Rack::MockSession.new(Object::NamedReorderApp))
      s1.get '/item/1?v=a'
      assert_equal 'A 1 #1', s1.last_response.body
      s1.get '/item/1?v=b'
      assert_equal 'B 1 #1', s1.last_response.body

      Object.send(:remove_const, :NamedReorderApp)
      Object.const_set(:NamedReorderApp, Class.new(Padrino::Application) do
        register Padrino::Cache
        enable :caching
        set :app_name, :named_reorder
        set :cache, Padrino::Cache.new(:File, dir: dir)
        condition { params[:v] == 'b' }
        get(:view_b, map: '/item/:id', cache: true) { "B #{params[:id]} ##{calls[:b] += 1}" }
        condition { params[:v] == 'a' }
        get(:view_a, map: '/item/:id', cache: true) { "A #{params[:id]} ##{calls[:a] += 1}" }
      end)

      s2 = Rack::Test::Session.new(Rack::MockSession.new(Object::NamedReorderApp))
      s2.get '/item/2?v=b'
      assert_equal 'B 2 #2', s2.last_response.body
      s2.get '/item/1?v=b'
      assert_equal 'B 1 #1', s2.last_response.body
      s2.get '/item/2?v=a'
      assert_equal 'A 2 #2', s2.last_response.body
      s2.get '/item/1?v=a'
      assert_equal 'A 1 #1', s2.last_response.body
    ensure
      Object.send(:remove_const, :NamedReorderApp) if Object.const_defined?(:NamedReorderApp, false)
    end
  end

  it 'should not serve a stale cached page after reset_routes! and redefining routes' do
    shared_store = Padrino::Cache.new(:Memory)
    mock_app do
      register Padrino::Cache
      enable :caching
      set :cache, shared_store
      set(:tier) { |v| condition { params[:tier] == v.to_s } }
      get('/doc/:id', cache: true, tier: :plus) { "plus #{params[:id]}" }
      get('/doc/:id', cache: true) { "basic #{params[:id]}" }
    end

    get '/doc/1?tier=plus'
    assert_equal 'plus 1', body

    @app.reset_routes!
    @app.get('/doc/:id', cache: true) { "rebuilt #{params[:id]}" }

    get '/doc/2'
    assert_equal 'rebuilt 2', body
    get '/doc/1'
    assert_equal 'rebuilt 1', body
  end

  it 'should not cache when a route is no longer registered on the current router' do
    writes = []
    spy_store = Class.new do
      def initialize(writes)
        @writes = writes
        @data = {}
      end

      def [](key)
        @data[key]
      end

      def store(key, val, _opts = {})
        @writes << key
        @data[key] = val
      end

      def delete(key)
        @data.delete(key)
      end
    end.new(writes)

    mock_app do
      register Padrino::Cache
      enable :caching
      set :cache, spy_store
      before { settings.reset_router! if params[:reset] == '1' }
      get('/detached', cache: true) { 'fresh response' }
    end

    get '/detached?reset=1'
    assert_equal 200, status
    assert_equal 'fresh response', body
    assert_empty writes
  end

  it 'should keep separate cached pages per negotiated format for provides: routes' do
    mock_app do
      register Padrino::Cache
      enable :caching
      get('/items', provides: %i[html json], cache: true) do
        content_type == :json ? '{"items":[]}' : '<p>items</p>'
      end
    end

    get '/items', {}, 'HTTP_ACCEPT' => 'text/html'
    assert_equal '<p>items</p>', body
    get '/items', {}, 'HTTP_ACCEPT' => 'application/json'
    assert_equal '{"items":[]}', body
    get '/items', {}, 'HTTP_ACCEPT' => 'text/html'
    assert_equal '<p>items</p>', body
  end

  it 'should capture negotiated format at lookup time rather than after handler mutates content_type' do
    calls = 0
    mock_app do
      register Padrino::Cache
      enable :caching
      get('/mut', provides: %i[html json], cache: true) do
        content_type :xml
        "call #{calls += 1}"
      end
    end

    get '/mut', {}, 'HTTP_ACCEPT' => 'text/html'
    assert_equal 'call 1', body
    get '/mut', {}, 'HTTP_ACCEPT' => 'text/html'
    assert_equal 'call 1', body
  end

  it 'should ignore rotating Host or X-Forwarded-Host headers on routes without host:' do
    calls = 0
    mock_app do
      register Padrino::Cache
      enable :caching
      get('/stable', cache: true) { "hit #{calls += 1}" }
    end

    get '/stable', {}, 'HTTP_HOST' => 'one.example.com', 'HTTP_X_FORWARDED_HOST' => 'x1.example.com'
    assert_equal 'hit 1', body
    get '/stable', {}, 'HTTP_HOST' => 'two.example.com', 'HTTP_X_FORWARDED_HOST' => 'x2.example.com'
    assert_equal 'hit 1', body
  end

  it 'should warn once per process when indistinguishable cached routes share a verb and path, and stay quiet when named or distinct' do
    _, err_dup = capture_io do
      app = Class.new(Padrino::Application) do
        register Padrino::Cache
        enable :caching
        condition { params[:a] == '1' }
        get('/dup', cache: true) { 'page A' }
        condition { params[:b] == '1' }
        get('/dup', cache: true) { 'page B' }
      end
      app.compiled_router
      app.compiled_router
    end
    assert_equal 1, err_dup.lines.size
    assert_includes err_dup, 'give each a unique route name so reordering routes does not change their cache keys.'

    _, err_clean = capture_io do
      app = Class.new(Padrino::Application) do
        register Padrino::Cache
        enable :caching
        set(:tier) { |v| condition { params[:tier] == v.to_s } }
        get('/distinct', cache: true, tier: :alpha) { 'page A' }
        get('/distinct', cache: true, tier: :beta) { 'page B' }
        condition { params[:a] == '1' }
        get(:named_a, map: '/named', cache: true) { 'page A' }
        condition { params[:b] == '1' }
        get(:named_b, map: '/named', cache: true) { 'page B' }
      end
      app.compiled_router
    end
    assert_equal '', err_clean
  end

  it 'should emit at most one duplicate-route warning across a parent class and multiple subclasses' do
    _, err_cached_parent = capture_io do
      parent = Class.new(Padrino::Application) do
        register Padrino::Cache
        enable :caching
        condition { params[:a] == '1' }
        get('/parent-dup', cache: true) { 'A' }
        condition { params[:b] == '1' }
        get('/parent-dup', cache: true) { 'B' }
      end
      child_one = Class.new(parent) { get('/child-one', cache: true) { 'C1' } }
      child_two = Class.new(parent) { get('/child-two', cache: true) { 'C2' } }
      child_one.compiled_router
      child_two.compiled_router
    end
    assert_equal 1, err_cached_parent.lines.size
    assert_includes err_cached_parent, '/parent-dup'

    _, err_uncached_parent = capture_io do
      parent = Class.new(Padrino::Application) do
        condition { params[:a] == '1' }
        get('/plain-parent-dup', cache: true) { 'A' }
        condition { params[:b] == '1' }
        get('/plain-parent-dup', cache: true) { 'B' }
      end
      child = Class.new(parent) do
        register Padrino::Cache
        enable :caching
        get('/child-only', cache: true) { 'C' }
      end
      child.compiled_router
    end
    assert_equal 1, err_uncached_parent.lines.size
    assert_includes err_uncached_parent, '/plain-parent-dup'
  end

  it 'should expire host: route pages via expire("app.example.com/")' do
    calls = 0
    store = Padrino::Cache.new(:Memory)
    mock_app do
      register Padrino::Cache
      enable :caching
      set :cache, store
      get(:index, host: 'app.example.com', cache: true) { "host #{calls += 1}" }
      get('/expire-host') { expire('app.example.com/') }
    end

    get '/', {}, 'HTTP_HOST' => 'app.example.com'
    assert_equal 'host 1', body
    get '/expire-host'
    get '/', {}, 'HTTP_HOST' => 'app.example.com'
    assert_equal 'host 2', body
  end

  it 'should render again when a store returns cached pages with String keys' do
    calls = 0
    entries = {}
    store = Object.new
    store.define_singleton_method(:[]) { |key| entries[key] }
    store.define_singleton_method(:store) do |key, value, _options = {}|
      entries[key] = value.is_a?(Hash) ? value.transform_keys(&:to_s) : value
    end
    store.define_singleton_method(:delete) { |key| entries.delete(key) }
    mock_app do
      register Padrino::Cache
      enable :caching
      set :cache, store
      get('/string-keys', cache: true) { "fresh #{calls += 1}" }
    end

    get '/string-keys'
    assert_equal 'fresh 1', body
    get '/string-keys'
    assert_equal 'fresh 2', body
  end

  it 'should not expire a plain route when expire is called with an explicit host/path' do
    calls = 0
    mock_app do
      register Padrino::Cache
      enable :caching
      get('/plain-item', cache: true) { "plain #{calls += 1}" }
      get('/exp-with-host') { expire('app.example.com/plain-item'); 'ok' }
      get('/exp-plain') { expire('/plain-item'); 'ok' }
    end

    get '/plain-item'
    assert_equal 'plain 1', body
    get '/exp-with-host'
    get '/plain-item'
    assert_equal 'plain 1', body
    get '/exp-plain'
    get '/plain-item'
    assert_equal 'plain 2', body
  end

  it 'should expire host: route pages for every host the route serves' do
    calls = 0
    mock_app do
      register Padrino::Cache
      enable :caching
      get('/dash', host: 'intranet', cache: true) { "intra #{calls += 1}" }
      get('/re', host: /\A(web|my_box\.corp\.example|www\.example\.com\.)\z/, cache: true) { "re #{calls += 1}" }
      get('/up', host: /\AAdmin\./, cache: true) { "up #{calls += 1}" }
      get('/exp') { expire(params[:t]); 'ok' }
    end

    [['intranet', '/dash', 'INTRANET/dash'],
     ['web', '/re', 'web/re'],
     ['my_box.corp.example', '/re', 'my_box.corp.example/re'],
     ['www.example.com.', '/re', 'www.example.com./re'],
     ['Admin.example.com', '/up', 'admin.example.com/up']].each do |host, path, target|
      get path, {}, 'HTTP_HOST' => host
      get path, {}, 'HTTP_HOST' => host
      before = body
      get '/exp', { t: target }
      get path, {}, 'HTTP_HOST' => host
      refute_equal before, body, "expire(#{target.inspect}) should clear the page for #{host}"
    end
  end

  it 'should ignore invalid byte sequences and other encodings in expire' do
    mock_app do
      register Padrino::Cache
      enable :caching
      set :cache, Padrino::Cache.new(:Memory)
      get('/:m/:d', cache: true, host: 'app.example.com') { 'host A' }
      get('/expire-invalid-utf8') { expire("\xFF\xFE/11/24".dup.force_encoding(Encoding::UTF_8)); 'ok' }
      get('/expire-binary') { expire("\xFF\xFE/11/24".b); 'ok' }
      get('/expire-binary-path') { expire("/\xFF\xFE".b); 'ok' }
      get('/expire-utf16') { expire('/11/24'.encode(Encoding::UTF_16LE)); 'ok' }
    end

    %w[/expire-invalid-utf8 /expire-binary /expire-binary-path /expire-utf16].each do |path|
      get path
      assert_equal 200, status
    end
  end

  it 'should allow expire outside a request with nil env and still delete the raw key' do
    store = Padrino::Cache.new(:Memory)
    app_cls = Class.new(Padrino::Application) do
      register Padrino::Cache
      enable :caching
      set :cache, store
      get(:show, map: '/items/:id', cache: true) { "item #{params[:id]}" }
    end

    store['/foo'] = 'raw-val'
    store['/items/1'] = 'raw-item'
    assert_nil app_cls.new!.expire('/foo')
    assert_nil store['/foo']
    assert_nil app_cls.new!.expire(:show, id: 1)
    assert_nil store['/items/1']
  end

  it 'should match Set host patterns in expire the same way routing does' do
    calls = 0
    mock_app do
      register Padrino::Cache
      enable :caching
      get('/set-host', host: Set['app.example.com'], cache: true) { "set #{calls += 1}" }
      get('/expire-set-host') { expire('app.example.com/set-host') }
    end

    get '/set-host', {}, 'HTTP_HOST' => 'app.example.com'
    assert_equal 'set 1', body
    get '/expire-set-host'
    get '/set-host', {}, 'HTTP_HOST' => 'app.example.com'
    assert_equal 'set 2', body
  end

  it 'should isolate deploys via cache_namespace including non-String values like Time' do
    shared_store = Padrino::Cache.new(:Memory)
    calls = 0
    mock_app do
      register Padrino::Cache
      enable :caching
      set :cache, shared_store
      set :cache_namespace, 'release-1'
      get('/rel', cache: true) { "rel #{calls += 1}" }
    end

    get '/rel'
    assert_equal 'rel 1', body
    get '/rel'
    assert_equal 'rel 1', body

    @app.set :cache_namespace, 'release-2'
    get '/rel'
    assert_equal 'rel 2', body

    @app.set :cache_namespace, Time.utc(2026, 1, 1, 0, 0, 1)
    get '/rel'
    assert_equal 'rel 3', body
    get '/rel'
    assert_equal 'rel 3', body

    @app.set :cache_namespace, Time.utc(2026, 1, 1, 0, 0, 2)
    get '/rel'
    assert_equal 'rel 4', body
  end

  it 'should digest Hash condition options deterministically regardless of mixed key insertion order' do
    Dir.mktmpdir do |dir|
      calls = 0
      Object.const_set(:MixedHashKeyApp, Class.new(Padrino::Application) do
        register Padrino::Cache
        enable :caching
        set :app_name, :mixed_hash_keys
        set :cache, Padrino::Cache.new(:File, dir: dir)
        set(:meta) { |_h| condition { true } }
        get('/m/:id', cache: true, meta: [{ 'a' => 1, :a => 2 }]) { "v #{params[:id]} ##{calls += 1}" }
      end)
      s1 = Rack::Test::Session.new(Rack::MockSession.new(Object::MixedHashKeyApp))
      s1.get '/m/1'
      assert_equal 'v 1 #1', s1.last_response.body

      Object.send(:remove_const, :MixedHashKeyApp)
      Object.const_set(:MixedHashKeyApp, Class.new(Padrino::Application) do
        register Padrino::Cache
        enable :caching
        set :app_name, :mixed_hash_keys
        set :cache, Padrino::Cache.new(:File, dir: dir)
        set(:meta) { |_h| condition { true } }
        get('/m/:id', cache: true, meta: [{ :a => 2, 'a' => 1 }]) { "v #{params[:id]} ##{calls += 1}" }
      end)
      s2 = Rack::Test::Session.new(Rack::MockSession.new(Object::MixedHashKeyApp))
      s2.get '/m/2'
      assert_equal 'v 2 #2', s2.last_response.body
      s2.get '/m/1'
      assert_equal 'v 1 #1', s2.last_response.body
    ensure
      Object.send(:remove_const, :MixedHashKeyApp) if Object.const_defined?(:MixedHashKeyApp, false)
    end
  end

  it 'should digest Proc condition options by source file and source line text across deploys' do
    Dir.mktmpdir do |dir|
      store_dir = File.join(dir, 'store')
      app_file = File.join(dir, 'proc_app.rb')

      File.write(app_file, <<~RUBY)
        class ProcSourceLineApp < Padrino::Application
          register Padrino::Cache
          enable :caching
          set :app_name, :proc_source_line
          set :cache, Padrino::Cache.new(:File, dir: #{store_dir.inspect})
          set(:check) { |fn| condition { instance_exec(&fn) } }
          get('/doc/:id', cache: true, check: -> { env['HTTP_X_MODE'] == 'alpha' }) do
            "mode A \#{params[:id]}"
          end
        end
      RUBY
      load app_file
      s1 = Rack::Test::Session.new(Rack::MockSession.new(Object::ProcSourceLineApp))
      s1.get '/doc/1', {}, 'HTTP_X_MODE' => 'alpha'
      assert_equal 'mode A 1', s1.last_response.body
      Object.send(:remove_const, :ProcSourceLineApp)

      File.write(app_file, <<~RUBY)
        class ProcSourceLineApp < Padrino::Application
          register Padrino::Cache
          enable :caching
          set :app_name, :proc_source_line
          set :cache, Padrino::Cache.new(:File, dir: #{store_dir.inspect})
          set(:check) { |fn| condition { instance_exec(&fn) } }
          get('/doc/:id', cache: true, check: -> { true }) do
            "mode B \#{params[:id]}"
          end
        end
      RUBY
      load app_file
      s2 = Rack::Test::Session.new(Rack::MockSession.new(Object::ProcSourceLineApp))
      s2.get '/doc/2'
      assert_equal 'mode B 2', s2.last_response.body
      s2.get '/doc/1'
      assert_equal 'mode B 1', s2.last_response.body
    ensure
      Object.send(:remove_const, :ProcSourceLineApp) if Object.const_defined?(:ProcSourceLineApp, false)
    end
  end

  it 'should isolate raw condition blocks on the same path using route ordinal' do
    capture_io do
      mock_app do
        register Padrino::Cache
        enable :caching
        condition { params[:v] == '1' }
        get('/raw', cache: true) { 'raw A' }
        condition { params[:v] == '2' }
        get('/raw', cache: true) { 'raw B' }
      end

      get '/raw?v=1'
      assert_equal 'raw A', body
      get '/raw?v=2'
      assert_equal 'raw B', body
      get '/raw?v=1'
      assert_equal 'raw A', body
    end
  end

  it 'should isolate reordered conditional routes when option values differ' do
    shared_store = Padrino::Cache.new(:Memory)
    Object.const_set(:OptionReorderApp, Class.new(Padrino::Application) do
      register Padrino::Cache
      enable :caching
      set :app_name, :option_reorder
      set :cache, shared_store
      set(:tier) { |v| condition { params[:tier] == v.to_s } }
      get('/opt/:id', cache: true, tier: :alpha) { "alpha #{params[:id]}" }
      get('/opt/:id', cache: true, tier: :beta) { "beta #{params[:id]}" }
    end)

    s1 = Rack::Test::Session.new(Rack::MockSession.new(Object::OptionReorderApp))
    s1.get '/opt/1?tier=alpha'
    assert_equal 'alpha 1', s1.last_response.body

    Object.send(:remove_const, :OptionReorderApp)
    Object.const_set(:OptionReorderApp, Class.new(Padrino::Application) do
      register Padrino::Cache
      enable :caching
      set :app_name, :option_reorder
      set :cache, shared_store
      set(:tier) { |v| condition { params[:tier] == v.to_s } }
      get('/opt/:id', cache: true, tier: :beta) { "beta #{params[:id]}" }
      get('/opt/:id', cache: true, tier: :alpha) { "alpha #{params[:id]}" }
    end)

    s2 = Rack::Test::Session.new(Rack::MockSession.new(Object::OptionReorderApp))
    s2.get '/opt/2?tier=beta'
    assert_equal 'beta 2', s2.last_response.body
    s2.get '/opt/1?tier=beta'
    assert_equal 'beta 1', s2.last_response.body
  ensure
    Object.send(:remove_const, :OptionReorderApp) if Object.const_defined?(:OptionReorderApp, false)
  end

  it 'should scope router-host marker expiration, skip provides :any, and require explicit host/path for host: routes' do
    shared_store = Padrino::Cache.new(:Memory)
    calls = Hash.new(0)

    app_a = Class.new(Padrino::Application) do
      register Padrino::Cache
      enable :caching
      set :cache, shared_store
      get('/scoped', cache: true) { "appA #{calls[:a] += 1}" }
      get('/exp-scoped') { expire('/scoped'); 'ok' }
      get('/any', provides: :any, cache: true) { "any #{calls[:any] += 1}" }
      get('/exp-any') { expire('/any'); 'ok' }
      get('/host-only', host: 'app.example.com', cache: true) { "host #{calls[:host] += 1}" }
      get('/exp-host-plain') { expire('/host-only'); 'ok' }
      get('/exp-host-explicit') { expire('app.example.com/host-only'); 'ok' }
      get(:idx, map: '/idx', cache: true) { "idx #{calls[:idx] += 1}" }
      get('/exp-idx-sym') { expire(:idx); 'ok' }
      get('/exp-idx-route') { expire(:idx, {}); 'ok' }
    end

    app_b = Class.new(Padrino::Application) do
      register Padrino::Cache
      enable :caching
      set :cache, shared_store
      get('/scoped', cache: true) { "appB #{calls[:b] += 1}" }
    end

    router = Padrino::Router.new do
      map(path: '/', host: 'one.example.com', to: app_a)
      map(path: '/', host: 'two.example.com', to: app_b)
    end

    s = Rack::Test::Session.new(Rack::MockSession.new(router))
    s.get '/scoped', {}, 'HTTP_HOST' => 'one.example.com'
    assert_equal 'appA 1', s.last_response.body
    s.get '/scoped', {}, 'HTTP_HOST' => 'two.example.com'
    assert_equal 'appB 1', s.last_response.body
    s.get '/exp-scoped', {}, 'HTTP_HOST' => 'one.example.com'
    s.get '/scoped', {}, 'HTTP_HOST' => 'one.example.com'
    assert_equal 'appA 2', s.last_response.body
    s.get '/scoped', {}, 'HTTP_HOST' => 'two.example.com'
    assert_equal 'appB 1', s.last_response.body

    deleted_any = []
    spy_any = Class.new do
      def initialize(deleted)
        @deleted = deleted
        @data = {}
      end

      def [](key)
        @data[key]
      end

      def store(key, val, _opts = {})
        @data[key] = val
      end

      def delete(key)
        @deleted << key
        @data.delete(key)
      end
    end.new(deleted_any)
    app_any = Class.new(Padrino::Application) do
      register Padrino::Cache
      enable :caching
      set :cache, spy_any
      get('/any', provides: :any, cache: true) { "any #{calls[:any] += 1}" }
      get('/exp-any') { expire('/any'); 'ok' }
    end
    any_s = Rack::Test::Session.new(Rack::MockSession.new(app_any))
    any_s.get '/any', {}, 'HTTP_ACCEPT' => 'text/html'
    assert_equal 'any 1', any_s.last_response.body
    any_s.get '/exp-any'
    assert_equal ['/any'], deleted_any
    any_s.get '/any', {}, 'HTTP_ACCEPT' => 'text/html'
    assert_equal 'any 1', any_s.last_response.body

    direct = Rack::Test::Session.new(Rack::MockSession.new(app_a))

    direct.get '/host-only', {}, 'HTTP_HOST' => 'app.example.com'
    assert_equal 'host 1', direct.last_response.body
    direct.get '/exp-host-plain'
    direct.get '/host-only', {}, 'HTTP_HOST' => 'app.example.com'
    assert_equal 'host 1', direct.last_response.body
    direct.get '/exp-host-explicit'
    direct.get '/host-only', {}, 'HTTP_HOST' => 'app.example.com'
    assert_equal 'host 2', direct.last_response.body

    direct.get '/idx'
    assert_equal 'idx 1', direct.last_response.body
    direct.get '/exp-idx-sym'
    direct.get '/idx'
    assert_equal 'idx 1', direct.last_response.body
    direct.get '/exp-idx-route'
    direct.get '/idx'
    assert_equal 'idx 2', direct.last_response.body
  end
end
