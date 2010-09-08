require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestPadrinoCache < Test::Unit::TestCase
  should 'cache a fragment' do
    called = false
    mock_app do
      register Padrino::Cache
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
    mock_app do
      register Padrino::Cache
      get('/foo', :cache => proc{|env| "cached"}){ 'test' }
      get('/bar', :cache => proc{|env| "cached"}){ halt 500 }
    end
    get "/foo"
    assert_equal 200, status
    assert_equal 'test', body
    get "/bar"
    assert_equal 200, status
    assert_equal 'test', body
  end

  should 'accept allow controller-wide caching' do
    called = false
    mock_app do
      controller :cache => true do
        register Padrino::Cache
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
      controller :cache => true do
        register Padrino::Cache
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
      controller :cache => true do
        register Padrino::Cache
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
      controller do
        register Padrino::Cache
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
end