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
      get('/foo', :cache => true){ called ? halt(500) : (called = 'test fragment') }
    end
    get "/foo"
    assert_equal 200, status
    assert_equal 'test fragment', body
    get "/foo"
    assert_equal 200, status
    assert_equal 'test fragment', body
    assert_not_equal false, called
  end

  should 'delete from the cache' do
    called = false
    mock_app do
      register Padrino::Cache
      get('/foo', :cache => true){ called ? 'test fragment again' : (called = 'test fragment') }
      get('/delete_foo'){ expire('/foo') }
    end
    get "/foo"
    assert_equal 200, status
    assert_equal 'test fragment', body
    get "/delete_foo"
    get "/foo"
    assert_equal 200, status
    assert_equal 'test fragment again', body
    assert_not_equal false, called
  end
end
