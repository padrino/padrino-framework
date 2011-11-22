require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "PadrinoCache" do

  def teardown
    tmp = File.expand_path(File.dirname(__FILE__) + "/tmp")
    `rm -rf #{tmp}`
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
