require File.expand_path('../helper', __FILE__)

describe "PadrinoCache" do
  after do
    tmp = File.expand_path("../tmp", __FILE__)
    %x[rm -rf #{tmp}]
  end

  it 'should cache a fragment' do
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
    refute_equal called, false
  end

  it 'should cache a page' do
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
    refute_equal false, called
  end

  it 'should cache HEAD verb' do
    called_times = 0
    mock_app do
      register Padrino::Cache
      enable :caching
      get('/foo', :cache => true){ called_times += 1; called_times.to_s }
    end
    head "/foo"
    head "/foo"
    assert_equal 1, called_times
  end

  it 'should not cache POST verb' do
    called_times = 0
    mock_app do
      register Padrino::Cache
      enable :caching
      post('/foo', :cache => true){ called_times += 1; called_times.to_s }
    end
    post "/foo"
    assert_equal 1, called_times
    post "/foo"
    assert_equal 2, called_times
  end

  it 'should not cache DELETE verb' do
    called_times = 0
    mock_app do
      register Padrino::Cache
      enable :caching
      delete('/foo', :cache => true){ called_times += 1; called_times.to_s }
    end
    delete "/foo"
    assert_equal 1, called_times
    delete "/foo"
    assert_equal 2, called_times
  end

  it 'should not cache PUT verb' do
    called_times = 0
    mock_app do
      register Padrino::Cache
      enable :caching
      put('/foo', :cache => true){ called_times += 1; called_times.to_s }
    end
    put "/foo"
    assert_equal 1, called_times
    put "/foo"
    assert_equal 2, called_times
  end

  it 'should delete from the cache' do
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
    refute_equal false, called
  end

  it 'should accept custom cache keys' do
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
    assert_equal 'foo', @app.cache[:foo][:body]
    get "/foo"
    assert_equal 'foo', body

    get "/bar"
    assert_equal 200, status
    assert_equal 'bar', body
    assert_equal 'bar', @app.cache[:bar][:body]
    get "/bar"
    assert_equal 'bar', body
  end

  it 'should delete based on urls' do
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

  it 'should allow controller-wide caching' do
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

  it 'should allow controller-wide expires' do
    called = false
    mock_app do
      register Padrino::Cache
      controller :cache => true do
        enable :caching
        expires 1
        get("/foo"){ called ? halt(500) : (called = 'test') }
      end
    end
    get "/foo"
    assert_equal 200, status
    assert_equal 'test', body
    get "/foo"
    assert_equal 200, status
    assert_equal 'test', body
    Time.stub(:now, Time.now + 2) { get "/foo" }
    assert_equal 500, status
  end

  it 'should allow cache disabling on a per route basis' do
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

  it 'should allow expiring for pages' do
    called = false
    mock_app do
      register Padrino::Cache
      enable :caching
      controller :cache => true do
        get("/foo") {
          expires 1
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
    Time.stub(:now, Time.now + 3) { get "/foo" }
    assert_equal 200, status
    assert_equal 'test again', body
  end

  it 'should allow expiring for fragments' do
    called = false
    mock_app do
      register Padrino::Cache
      enable :caching
      controller do
        get("/foo") {
          expires 1
          cache(:test, :expires => 2) do
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
    Time.stub(:now, Time.now + 3) { get "/foo" }
    assert_equal 200, status
    assert_equal 'test again', body
  end

  it 'should allow disabling of the cache' do
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

  it 'should not cache integer statuses' do
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

  it 'should resolve block cache keys' do
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

  it 'should raise an error if providing both a cache_key and block' do
    mock_app do
      register Padrino::Cache
      enable :caching

      get '/foo', :cache => true do
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
      get '/foo', :cache => true do
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
    get "/foo"
    assert_equal 200, status
    assert_equal '{"foo":"bar"}', body
    assert_equal '{"foo":"bar"}', @app.cache[:foo][:body]
    get "/foo"
    assert_equal '{"foo":"bar"}', body
    assert_match /json/, last_response.content_type
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
            { :foo => 'bar' }
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
      controller :cache => true do
        get("/foo") do
          expires 1
          called_times_a += 1
          called_times_b.to_s
        end
        get("/bar") do
          expires 3
          called_times_b += 1
          called_times_b.to_s
        end
      end
    end
    Time.stub(:now, Time.now) { get "/foo"; get "/bar" }
    assert_equal 1, called_times_a
    assert_equal 1, called_times_b
    Time.stub(:now, Time.now + 0.5) { get "/foo"; get "/bar" }
    assert_equal 1, called_times_a
    assert_equal 1, called_times_b
    Time.stub(:now, Time.now + 2) { get "/foo"; get "/bar" }
    assert_equal 2, called_times_a
    assert_equal 1, called_times_b
    Time.stub(:now, Time.now + 2.5) { get "/foo"; get "/bar" }
    assert_equal 2, called_times_a
    assert_equal 1, called_times_b
    Time.stub(:now, Time.now + 4) { get "/foo"; get "/bar" }
    assert_equal 3, called_times_a
    assert_equal 2, called_times_b
    Time.stub(:now, Time.now + 5.5) { get "/foo"; get "/bar" }
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
    while adapter.respond_to? :adapter
      adapter = adapter.adapter
    end
    assert_kind_of Moneta::Adapters::Memory, adapter
  end

  it "should check key existence" do
    count1, count2 = 0, 0
    mock_app do
      register Padrino::Cache
      enable :caching
      get "/" do
        cache(:foo) do
          count1 += 1
          nil
        end
        count1.inspect
      end

      get "/object" do
        cache_object(:bar) do
          count2 += 1
          nil
        end
        count2.inspect
      end
    end
    2.times { get "/" }
    assert_equal "1", body
    2.times { get "/object" }
    assert_equal "1", body
  end

  it 'should cache full mime type of content_type' do
    mock_app do
      register Padrino::Cache
      enable :caching
      get '/foo', :cache => true do
        content_type :json, :charset => 'utf-8'
        '{}'
      end
    end
    get "/foo"
    assert_equal 'application/json;charset=utf-8', last_response.content_type
    get "/foo"
    assert_equal 'application/json;charset=utf-8', last_response.content_type
  end
end
