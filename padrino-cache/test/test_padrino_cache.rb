require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "PadrinoCache" do

  def teardown
    tmp = File.expand_path(File.dirname(__FILE__) + "/tmp")
    `rm -rf #{tmp}`
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
end
