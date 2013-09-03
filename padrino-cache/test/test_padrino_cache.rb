require File.expand_path('../helper', __FILE__)

describe "PadrinoCache" do

  before do
  end

  after do
    tmp = File.expand_path("../tmp", __FILE__)
    %x[rm -rf #{tmp}]
  end

  should 'cache a fragment' do
    called = false
    mock_app do
      register Padrino::Cache
      enable :caching
      get("/foo"){ cache(:test) { called ? halt(500) : (called = 'test fragment') } }
    end
    get "/foo"
    assert_equal 200, status
    assert_equal 'test fragment', body
    get "/foo"
    assert_equal 200, status
    assert_equal 'test fragment', body
    assert_not_equal called, false
  end

  should 'cache a page' do
    called = false
    mock_app do
      register Padrino::Cache
      enable :caching
      get('/foo', :cache => true){ called ? halt(500) : (called = 'test page') }
    end
    get "/foo"
    assert_equal 200, status
    assert_equal 'test page', body
    get "/foo"
    assert_equal 200, status
    assert_equal 'test page', body
    assert_not_equal false, called
  end

  should 'delete from the cache' do
    called = false
    mock_app do
      register Padrino::Cache
      enable :caching
      get('/foo', :cache => true){ called ? 'test page again' : (called = 'test page') }
      get('/delete_foo'){ expire('/foo') }
    end
    get "/foo"
    assert_equal 200, status
    assert_equal 'test page', body
    get "/delete_foo"
    get "/foo"
    assert_equal 200, status
    assert_equal 'test page again', body
    assert_not_equal false, called
  end

  should 'accept custom cache keys' do
    called = false
    mock_app do
      register Padrino::Cache
      enable :caching
      get '/foo', :cache => true do
        if called
          "you'll never see me"
        else
          cache_key :foo
          called = 'foo'

          called
        end
      end

      get '/bar', :cache => true do
        if called
          cache_key :bar
          called = 'bar'

          called
        else
          "you'll never see me"
        end
      end
    end
    get "/foo"
    assert_equal 200, status
    assert_equal 'foo', body
    assert_equal 'foo', @app.cache.get(:foo)
    get "/foo"
    assert_equal 'foo', body

    get "/bar"
    assert_equal 200, status
    assert_equal 'bar', body
    assert_equal 'bar', @app.cache.get(:bar)
    get "/bar"
    assert_equal 'bar', body
  end

  should 'delete based on urls' do
    called = false
    mock_app do
      register Padrino::Cache
      enable :caching
      get(:foo, :with => :id, :cache => true) { called ? 'test page again' : (called = 'test page') }
      get(:delete_foo, :with => :id) { expire(:foo, params[:id]) }
    end
    get "/foo/12"
    assert_equal 200, status
    assert_equal 'test page', body
    get "/delete_foo/12"
    get "/foo/12"
    assert_equal 200, status
    assert_equal 'test page again', body
  end

  should 'accept allow controller-wide caching' do
    called = false
    mock_app do
      controller :cache => true do
        register Padrino::Cache
        enable :caching
        get("/foo"){ called ? halt(500) : (called = 'test') }
      end
    end
    get "/foo"
    assert_equal 200, status
    assert_equal 'test', body
    get "/foo"
    assert_equal 200, status
    assert_equal 'test', body
  end

  should 'allow cache disabling on a per route basis' do
    called = false
    mock_app do
      register Padrino::Cache
      enable :caching
      controller :cache => true do
        get("/foo", :cache => false){ called ? 'test again' : (called = 'test') }
      end
    end
    get "/foo"
    assert_equal 200, status
    assert_equal 'test', body
    get "/foo"
    assert_equal 200, status
    assert_equal 'test again', body
  end

  should 'allow expiring for pages' do
    called = false
    mock_app do
      register Padrino::Cache
      enable :caching
      controller :cache => true do
        get("/foo") {
          expires_in 1
          called ? 'test again' : (called = 'test')
        }
      end
    end
    get "/foo"
    assert_equal 200, status
    assert_equal 'test', body
    get "/foo"
    assert_equal 200, status
    assert_equal 'test', body
    sleep 2
    get "/foo"
    assert_equal 200, status
    assert_equal 'test again', body
  end

  should 'allow expiring for fragments' do
    called = false
    mock_app do
      register Padrino::Cache
      enable :caching
      controller do
        get("/foo") {
          expires_in 1
          cache(:test, :expires_in => 2) do
            called ? 'test again' : (called = 'test')
          end
        }
      end
    end
    get "/foo"
    assert_equal 200, status
    assert_equal 'test', body
    get "/foo"
    assert_equal 200, status
    assert_equal 'test', body
    sleep 2
    get "/foo"
    assert_equal 200, status
    assert_equal 'test again', body
  end

  should 'allow disabling of the cache' do
    called = false
    mock_app do
      register Padrino::Cache
      disable :caching
      controller :cache => true do
        get("/foo"){ called ? halt(500) : (called = 'test') }
      end
    end
    get "/foo"
    assert_equal 200, status
    assert_equal 'test', body
    get "/foo"
    assert_equal 500, status
  end

  should 'not cache integer statuses' do
    mock_app do
      register Padrino::Cache
      enable :caching
      get( '/404', :cache => true ) { not_found }
      get( '/503', :cache => true ) { error 503 }
      not_found { 'fancy 404' }
      error( 503 ) { 'fancy 503' }
    end
    get '/404'
    assert_equal 'fancy 404', body
    assert_equal 404, status
    assert_equal nil, @app.cache.get('/404')
    get '/404'
    assert_equal 'fancy 404', body
    assert_equal 404, status
    get '/503'
    assert_equal 'fancy 503', body
    assert_equal 503, status
    assert_equal nil, @app.cache.get('/503')
    get '/503'
    assert_equal 'fancy 503', body
    assert_equal 503, status
  end

  should 'cache should not hit with unique params' do
    call_count = 0
    mock_app do 
      register Padrino::Cache
      enable :caching
      before do 
        param = params[:test] || 'none'
        cache_key "foo?#{param}"
      end
      get '/foo/:test', :cache => true do
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

  should 'resolve block cache keys' do
    call_count = 0
    mock_app do 
      register Padrino::Cache
      enable :caching

      get '/foo', :cache => true do
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

  should 'raise an error if providing both a cache_key and block' do
    mock_app do 
      register Padrino::Cache
      enable :caching

      get '/foo', :cache => true do
        cache_key(:some_key) { "key #{params[:id]}" }
      end
    end

    assert_raises(RuntimeError) { get '/foo' }
  end

end
