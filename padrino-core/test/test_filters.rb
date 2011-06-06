require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestFilters < Test::Unit::TestCase
  should "filters by accept header" do
    mock_app do
      get '/foo', :provides => [:xml, :js] do
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

    get '/foo', {}, { 'HTTP_ACCEPT' => 'application/javascript' }
    assert ok?
    assert_equal 'application/javascript', body
    assert_equal 'application/javascript;charset=utf-8', response.headers['Content-Type']

    get '/foo.js'
    assert ok?
    assert_equal 'application/javascript;charset=utf-8', response.headers['Content-Type']

    get '/foo', {}, { "HTTP_ACCEPT" => 'text/html' }
    assert_equal 406, status
  end
  
  should "allow passing & halting in before filters" do
    mock_app do
      controller do
        before { env['QUERY_STRING'] == 'secret' or pass }
        get :index do
          "secret index"
        end
      end

      controller do
        before { env['QUERY_STRING'] == 'halt' and halt 401, 'go away!' }
        get :index do
          "index"
        end
      end
    end

    get "/?secret"
    assert_equal "secret index", body

    get "/?halt"
    assert_equal "go away!", body
    assert_equal 401, status

    get "/"
    assert_equal "index", body
  end

  should 'scope filters in the given controller' do
    mock_app do
      before { @global = 'global' }
      after { @global = nil }

      controller :foo do
        before { @foo = :foo }
        after { @foo = nil }
        get("/") { [@foo, @bar, @global].compact.join(" ") }
      end

      get("/") { [@foo, @bar, @global].compact.join(" ") }

      controller :bar do
        before { @bar = :bar }
        after { @bar = nil }
        get("/") { [@foo, @bar, @global].compact.join(" ") }
      end
    end

    get "/bar"
    assert_equal "bar global", body

    get "/foo"
    assert_equal "foo global", body

    get "/"
    assert_equal "global", body
  end

  should 'be able to access params in a before filter' do
    username_from_before_filter = nil

    mock_app do
      before do
        username_from_before_filter = params[:username]
      end

      get :users, :with => :username do
      end
    end
    get '/users/josh'
    assert_equal 'josh', username_from_before_filter
  end

  should "be able to access params normally when a before filter is specified" do
    mock_app do
      before { }
      get :index do
        params.inspect
      end
    end
    get '/?test=what'
    assert_equal '{"test"=>"what"}', body
  end

  should "be able to filter based on a path" do
    mock_app do
      before('/') { @test = "#{@test}before"}
      get :index do
        @test
      end
      get :main do
        @test
      end
    end
    get '/'
    assert_equal 'before', body
    #get '/main'
    #assert_equal '', body
  end

#  should "be able to filter based on a symbol" do
#    mock_app do
#      before(:index) { @test = 'before'}
#      get :index do
#        @test
#      end
#      get :main do
#        @test
#      end
#    end
#    get '/'
#    assert_equal 'before', body
#    get '/main'
#    assert_equal '', body
#  end

  #should "be able to filter based on a symbol" do
  #  mock_app do
  #    before(:index) { @test = 'before'}
  #    get :index do
  #      @test
  #    end
  #    get :main do
  #      @test
  #    end
  #  end
  #  get '/'
  #  assert_equal 'before', body
  #  get '/main'
  #  assert_equal '', body
  #end
end
