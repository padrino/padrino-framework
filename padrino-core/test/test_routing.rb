require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestRouting < Test::Unit::TestCase
  should 'ignore trailing delimiters for basic route' do
    mock_app do
      get("/foo"){ "okey" }
      get(:test) { "tester" }
    end
    get "/foo"
    assert_equal "okey", body
    get "/foo/"
    assert_equal "okey", body
    get "/test"
    assert_equal "tester", body
    get "/test/"
    assert_equal "tester", body
  end

  should 'fail with unrecognized route exception when not found' do
    unrecognized_app = mock_app do
      get(:index){ "okey" }
    end
    assert_nothing_raised { get unrecognized_app.url_for(:index) }
    assert_equal "okey", body
    assert_raises(Padrino::Routing::UnrecognizedException) {
      get unrecognized_app.url_for(:fake)
    }
  end

  should "parse routes with question marks" do
    mock_app do
      get("/foo/?"){ "okey" }
      post('/unauthenticated/?') { "no access" }
    end
    get "/foo"
    assert_equal "okey", body
    get "/foo/"
    assert_equal "okey", body
    post "/unauthenticated"
    assert_equal "no access", body
    post "/unauthenticated/"
    assert_equal "no access", body
  end

  should 'match correctly similar paths' do
    mock_app do
      get("/my/:foo_id"){ params[:foo_id] }
      get("/my/:bar_id/bar"){ params[:bar_id] }
    end
    get "/my/1"
    assert_equal "1", body
    get "/my/2/bar"
    assert_equal "2", body
  end

  should "not generate overlapping head urls" do
    app = mock_app do
      get("/main"){ "hello" }
      post("/main"){ "hello" }
    end
    assert_equal 3, app.routes.size, "should generate GET, HEAD and PUT"
    assert_equal ["GET"],  app.routes[0].as_options[:conditions][:request_method]
    assert_equal ["HEAD"], app.routes[1].as_options[:conditions][:request_method]
    assert_equal ["POST"], app.routes[2].as_options[:conditions][:request_method]
  end

  should 'generate basic urls'do
    mock_app do
      get(:foo){ "/foo" }
      get(:foo, :with => :id){ |id| "/foo/#{id}" }
      get(:hash, :with => :id){ url(:hash, :id => 1) }
      get(:array, :with => :id){ url(:array, 23) }
      get(:hash_with_extra, :with => :id){ url(:hash_with_extra, :id => 1, :query => 'string') }
      get(:array_with_extra, :with => :id){ url(:array_with_extra, 23, :query => 'string') }
      get("/old-bar/:id"){ params[:id] }
      post(:mix, :map => "/mix-bar/:id"){ params[:id] }
      get(:mix, :map => "/mix-bar/:id"){ params[:id] }
    end
    get "/foo"
    assert_equal "/foo", body
    get "/foo/123"
    assert_equal "/foo/123", body
    get "/hash/2"
    assert_equal "/hash/1", body
    get "/array/23"
    assert_equal "/array/23", body
    get "/hash_with_extra/1"
    assert_equal "/hash_with_extra/1?query=string", body
    get "/array_with_extra/23"
    assert_equal "/array_with_extra/23?query=string", body
    get "/old-bar/3"
    assert_equal "3", body
    post "/mix-bar/4"
    assert_equal "4", body
    get "/mix-bar/4"
    assert_equal "4", body
  end

  should 'generate url with format' do
    mock_app do
      get(:a, :provides => :any){ url(:a, :format => :json) }
      get(:b, :provides => :js){ url(:b, :format => :js) }
      get(:c, :provides => [:js, :json]){ url(:c, :format => :json) }
      get(:d, :provides => [:html, :js]){ url(:d, :format => :js, :foo => :bar) }
    end
    get "/a.js"
    assert_equal "/a.json", body
    get "/b.js"
    assert_equal "/b.js", body
    get "/b.ru"
    assert_equal 404, status
    get "/c.js"
    assert_equal "/c.json", body
    get "/c.json"
    assert_equal "/c.json", body
    get "/c.ru"
    assert_equal 404, status
    get "/d"
    assert_equal "/d.js?foo=bar", body
    get "/d.js"
    assert_equal "/d.js?foo=bar", body
    get "/e.xml"
    assert_equal 404, status
  end

  should "not allow Accept-Headers it does not provide" do
    mock_app do
      get(:a, :provides => [:html, :js]){ content_type }
    end

    get "/a", {}, {"HTTP_ACCEPT" => "application/yaml"}
    assert_equal 404, status
  end

  should "not default to HTML if HTML is not provided and no type is given" do
    mock_app do
      get(:a, :provides => [:js]){ content_type }
    end

    get "/a", {}, {}
    assert_equal 404, status
  end

  should "not match routes if url_format and http_accept is provided but not included" do
    mock_app do
      get(:a, :provides => [:js, :html]){ content_type }
    end

    get "/a.xml", {}, {"HTTP_ACCEPT" => "text/html"}
    assert_equal 404, status
  end

  should "generate routes for format simple" do
    mock_app do
      get(:foo, :provides => [:html, :rss]) { render :haml, "Test" }
    end
    get "/foo"
    assert_equal "Test\n", body
    get "/foo.rss"
    assert_equal "Test\n", body
  end

  should "should inject the controller name into the request" do
    mock_app do
      controller :posts do
        get(:index) { request.controller.to_s }
      end
    end
    get "/posts"
    assert_equal "posts", body
  end

  should "generate routes for format with controller" do
    mock_app do
      controller :posts do
        get(:index, :provides => [:html, :rss, :atom, :js]) { render :haml, "Index.#{content_type}" }
        get(:show,  :with => :id, :provides => [:html, :rss, :atom]) { render :haml, "Show.#{content_type}" }
      end
    end
    get "/posts"
    assert_equal "Index.html\n", body
    get "/posts.rss"
    assert_equal "Index.rss\n", body
    get "/posts.atom"
    assert_equal "Index.atom\n", body
    get "/posts.js"
    assert_equal "Index.js\n", body
    get "/posts/show/5"
    assert_equal "Show.html\n", body
    get "/posts/show/5.rss"
    assert_equal "Show.rss\n", body
    get "/posts/show/10.atom"
    assert_equal "Show.atom\n", body
  end

  should 'map routes' do
    mock_app do
      get(:bar){ "bar" }
    end
    get "/bar"
    assert_equal "bar", body
    assert_equal "/bar", @app.url(:bar)
  end

  should 'remove index from path' do
    mock_app do
      get(:index){ "index" }
      get("/accounts/index"){ "accounts" }
    end
    get "/"
    assert_equal "index", body
    assert_equal "/", @app.url(:index)
    get "/accounts"
    assert_equal "accounts", body
  end

  should 'remove index from path with params' do
    mock_app do
      get(:index, :with => :name){ "index with #{params[:name]}" }
    end
    get "/bobby"
    assert_equal "index with bobby", body
    assert_equal "/john", @app.url(:index, :name => "john")
  end

  should 'parse named params' do
    mock_app do
      get(:print, :with => :id){ "Im #{params[:id]}" }
    end
    get "/print/9"
    assert_equal "Im 9", body
    assert_equal "/print/9", @app.url(:print, :id => 9)
  end

  should '405 on wrong request_method' do
    mock_app do
      post('/bar'){ "bar" }
    end
    get "/bar"
    assert_equal 405, status
  end

  should 'respond to' do
    mock_app do
      get(:a, :provides => :js){ "js" }
      get(:b, :provides => :any){ "any" }
      get(:c, :provides => [:js, :json]){ "js,json" }
      get(:d, :provides => [:html, :js]){ "html,js"}
    end
    get "/a"
    assert_equal 404, status
    get "/a.js"
    assert_equal "js", body
    get "/b"
    assert_equal "any", body
    assert_raise(RuntimeError) { get "/b.foo" }
    get "/c"
    assert_equal 404, status
    get "/c.js"
    assert_equal "js,json", body
    get "/c.json"
    assert_equal "js,json", body
    get "/d"
    assert_equal "html,js", body
    get "/d.js"
    assert_equal "html,js", body
  end

  should 'respond_to and set content_type' do
    Rack::Mime::MIME_TYPES['.foo'] = 'application/foo'
    mock_app do
      get :a, :provides => :any do
        case content_type
          when :js    then "js"
          when :json  then "json"
          when :foo   then "foo"
          when :html  then "html"
        end
      end
    end
    get "/a.js"
    assert_equal "js", body
    assert_equal 'application/javascript;charset=utf-8', response["Content-Type"]
    get "/a.json"
    assert_equal "json", body
    assert_equal 'application/json;charset=utf-8', response["Content-Type"]
    get "/a.foo"
    assert_equal "foo", body
    assert_equal 'application/foo;charset=utf-8', response["Content-Type"]
    get "/a"
    assert_equal "html", body
    assert_equal 'text/html;charset=utf-8', response["Content-Type"]
  end

  should 'use controllers' do
    mock_app do
      controller "/admin" do
        get("/"){ "index" }
        get("/show/:id"){ "show #{params[:id]}" }
      end
    end
    get "/admin"
    assert_equal "index", body
    get "/admin/show/1"
    assert_equal "show 1", body
  end

  should 'use named controllers' do
    mock_app do
      controller :admin do
        get(:index){ "index" }
        get(:show, :with => :id){ "show #{params[:id]}" }
      end
      controllers :foo, :bar do
        get(:index){ "foo_bar_index" }
      end
    end
    get "/admin"
    assert_equal "index", body
    get "/admin/show/1"
    assert_equal "show 1", body
    assert_equal "/admin", @app.url(:admin_index)
    assert_equal "/admin/show/1", @app.url(:admin_show, :id => 1)
    get "/foo/bar"
    assert_equal "foo_bar_index", body
  end

  should "ignore trailing delimiters within a named controller" do
    mock_app do
      controller :posts do
        get(:index, :provides => [:html, :js]){ "index" }
        get(:new)  { "new" }
        get(:show, :with => :id){ "show #{params[:id]}" }
      end
    end
    get "/posts"
    assert_equal "index", body
    get "/posts/"
    assert_equal "index", body
    get "/posts.js"
    assert_equal "index", body
    get "/posts.js/"
    assert_equal "index", body
    get "/posts/new"
    assert_equal "new", body
    get "/posts/new/"
    assert_equal "new", body
  end

  should "ignore trailing delimiters within a named controller for unnamed actions" do
    mock_app do
      controller :accounts do
        get("/") { "account_index" }
        get("/new") { "new" }
      end
      controller :votes do
        get("/") { "vote_index" }
      end
    end
    get "/accounts"
    assert_equal "account_index", body
    get "/accounts/"
    assert_equal "account_index", body
    get "/accounts/new"
    assert_equal "new", body
    get "/accounts/new/"
    assert_equal "new", body
    get "/votes"
    assert_equal "vote_index", body
    get "/votes/"
    assert_equal "vote_index", body
  end

  should 'use named controllers with array routes' do
    mock_app do
      controller :admin do
        get(:index){ "index" }
        get(:show, :with => :id){ "show #{params[:id]}" }
      end
      controllers :foo, :bar do
        get(:index){ "foo_bar_index" }
      end
    end
    get "/admin"
    assert_equal "index", body
    get "/admin/show/1"
    assert_equal "show 1", body
    assert_equal "/admin", @app.url(:admin, :index)
    assert_equal "/admin/show/1", @app.url(:admin, :show, :id => 1)
    get "/foo/bar"
    assert_equal "foo_bar_index", body
  end

  should 'use uri_root' do
    mock_app do
      get(:foo){ "foo" }
    end
    @app.uri_root = '/'
    assert_equal "/foo", @app.url(:foo)
    @app.uri_root = '/testing'
    assert_equal "/testing/foo", @app.url(:foo)
    @app.uri_root = '/testing/'
    assert_equal "/testing/foo", @app.url(:foo)
    @app.uri_root = 'testing/bar///'
    assert_equal "/testing/bar/foo", @app.url(:foo)
  end

  should 'use uri_root with controllers' do
    mock_app do
      controller :foo do
        get(:bar){ "bar" }
      end
    end
    @app.uri_root = '/testing'
    assert_equal "/testing/foo/bar", @app.url(:foo, :bar)
  end

  should 'use RACK_BASE_URI' do
    mock_app do
      get(:foo){ "foo" }
    end
    # Wish there was a side-effect free way to test this...
    ENV['RACK_BASE_URI'] = '/'
    assert_equal "/foo", @app.url(:foo)
    ENV['RACK_BASE_URI'] = '/testing'
    assert_equal "/testing/foo", @app.url(:foo)
    ENV['RACK_BASE_URI'] = nil
  end

  should 'reset routes' do
    mock_app do
      get("/"){ "foo" }
      router.reset!
    end
    get "/"
    assert_equal 404, status
  end

  should 'apply maps' do
    mock_app do
      controllers :admin do
        get(:index, :map => "/"){ "index" }
        get(:show, :with => :id, :map => "/show"){ "show #{params[:id]}" }
        get(:edit, :map => "/edit/:id/product"){ "edit #{params[:id]}" }
      end
    end
    get "/"
    assert_equal "index", body
    get "/show/1"
    assert_equal "show 1", body
    get "/edit/1/product"
    assert_equal "edit 1", body
  end

  should "apply parent to route" do
    mock_app do
      controllers :project do
        get(:index, :parent => :user) { "index #{params[:user_id]}" }
        get(:edit, :with => :id, :parent => :user) { "edit #{params[:id]} #{params[:user_id]}"}
        get(:show, :with => :id, :parent => [:user, :product]) { "show #{params[:id]} #{params[:user_id]} #{params[:product_id]}"}
      end
    end
    get "/user/1/project"
    assert_equal "index 1", body
    get "/user/1/project/edit/2"
    assert_equal "edit 2 1", body
    get "/user/1/product/2/project/show/3"
    assert_equal "show 3 1 2", body

  end

  should "apply parent to controller" do
    mock_app do
      controller :project, :parent => :user do
        get(:index) { "index #{params[:user_id]}"}
        get(:edit, :with => :id, :parent => :user) { "edit #{params[:id]} #{params[:user_id]}"}
        get(:show, :with => :id, :parent => :product) { "show #{params[:id]} #{params[:user_id]} #{params[:product_id]}"}
      end
    end

    user_project_url = "/user/1/project"
    get user_project_url
    assert_equal "index 1", body
    assert_equal user_project_url, @app.url(:project, :index, :user_id => 1)

    user_project_edit_url = "/user/1/project/edit/2"
    get user_project_edit_url
    assert_equal "edit 2 1", body
    assert_equal user_project_edit_url, @app.url(:project, :edit, :user_id => 1, :id => 2)

    user_product_project_url = "/user/1/product/2/project/show/3"
    get user_product_project_url
    assert_equal "show 3 1 2", body
    assert_equal user_product_project_url, @app.url(:project, :show, :user_id => 1, :product_id => 2, :id => 3)
  end

  should "use default values" do
    mock_app do
      controller :lang => :it do
        get(:index, :map => "/:lang") { "lang is #{params[:lang]}" }
      end
      assert_equal "/it", url(:index)
      # This is only for be sure that default values
      # work only for the given controller
      get(:foo, :map => "/foo") {}
      assert_equal "/foo", url(:foo)
    end
    get "/en"
    assert_equal "lang is en", body
  end

  should "transitions to the next matching route on pass" do
    mock_app do
      get '/:foo' do
        pass
        'Hello Foo'
      end
      get '/:bar' do
        'Hello World'
      end
    end

    get '/za'
    assert_equal 'Hello World', body
  end

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

    get '/foo', {}, { :accept => 'text/html' }
    assert not_found?
  end

  should "works allow global provides" do
    mock_app do
      provides :xml

      get("/foo"){ "Foo in #{content_type}" }
      get("/bar"){ "Bar in #{content_type}" }
    end

    get '/foo', {}, { 'HTTP_ACCEPT' => 'application/xml' }
    assert_equal 'Foo in xml', body
    get '/foo'
    assert not_found?

    get '/bar', {}, { 'HTTP_ACCEPT' => 'application/xml' }
    assert_equal 'Bar in html', body
  end

  should "set content_type to :html for both empty Accept as well as Accept text/html" do
    mock_app do
      provides :html

      get("/foo"){ content_type.to_s }
    end

    get '/foo', {}, {}
    assert_equal 'html', body

    get '/foo', {}, { 'HTTP_ACCEPT' => 'text/html' }
    assert_equal 'html', body
  end

  should "set content_type to :html if Accept */*" do
    mock_app do
      get("/foo", :provides => [:html, :js]) { content_type.to_s }
    end
    get '/foo', {}, {}
    assert_equal 'html', body

    get '/foo', {}, { 'HTTP_ACCEPT' => '*/*;q=0.5' }
    assert_equal 'html', body
  end

  should 'allows custom route-conditions to be set via route options' do
    protector = Module.new {
      def protect(*args)
        condition {
          unless authorize(params["user"], params["password"])
            halt 403, "go away"
          end
        }
      end
    }

    mock_app do
      register protector

      helpers do
        def authorize(username, password)
          username == "foo" && password == "bar"
        end
      end

      get "/", :protect => true do
        "hey"
      end
    end

    get "/"
    assert forbidden?
    assert_equal "go away", body

    get "/", :user => "foo", :password => "bar"
    assert ok?
    assert_equal "hey", body
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

  should 'works with optionals params' do
    mock_app do
      get("/foo(/:bar)") { params[:bar] }
    end

    get "/foo/bar"
    assert_equal "bar", body

    get "/foo"
    assert_equal "", body
  end

  should 'work with multiple dashed params' do
    mock_app do
      get "/route/:foo/:bar/:baz", :provides => :html do
        "#{params[:foo]};#{params[:bar]};#{params[:baz]}"
      end
    end

    get "/route/foo/bar/baz"
    assert_equal 'foo;bar;baz', body

    get "/route/foo/bar-whatever/baz"
    assert_equal 'foo;bar-whatever;baz', body
  end

  should 'work with arbitrary params' do
    mock_app do
      get(:testing) { params[:foo] }
    end

    url = @app.url(:testing, :foo => 'bar')
    assert_equal "/testing?foo=bar", url
    get url
    assert_equal "bar", body
  end

  should 'work with controller and arbitrary params' do
    mock_app do
      get(:testing) { params[:foo] }
      controller :test1 do
        get(:url1) { params[:foo] }
        get(:url2, :provides => [:html, :json]) { params[:foo] }
      end
    end

    url = @app.url(:test1, :url1, :foo => 'bar1')
    assert_equal "/test1/url1?foo=bar1", url
    get url
    assert_equal "bar1", body

    url = @app.url(:test1, :url2, :foo => 'bar2')
    assert_equal "/test1/url2?foo=bar2", url
    get url
    assert_equal "bar2", body
  end

  should "work with params and parent options" do
    mock_app do
      controller :test2, :parent => :parent1, :parent1_id => 1 do
        get(:url3) { params[:foo] }
        get(:url4, :with => :with1) { params[:foo] }
        get(:url5, :with => :with2, :provides => [:html]) { params[:foo] }
      end
    end

    url = @app.url(:test2, :url3, :foo => 'bar3')
    assert_equal "/parent1/1/test2/url3?foo=bar3", url
    get url
    assert_equal "bar3", body

    url = @app.url(:test2, :url4, :with1 => 'awith1', :foo => 'bar4')
    assert_equal "/parent1/1/test2/url4/awith1?foo=bar4", url
    get url
    assert_equal "bar4", body

    url = @app.url(:test2, :url5, :with2 => 'awith1', :foo => 'bar5')
    assert_equal "/parent1/1/test2/url5/awith1?foo=bar5", url
    get url
    assert_equal "bar5", body
  end

  should "parse params without explicit provides for every matching route" do
    mock_app do
      get(:index, :map => "/foos/:bar") { "get bar = #{params[:bar]}" }
      post :create, :map => "/foos/:bar", :provides => [:html, :js] do
        "post bar = #{params[:bar]}"
      end
    end

    get "/foos/hello"
    assert_equal "get bar = hello", body
    post "/foos/hello"
    assert_equal "post bar = hello", body
    post "/foos/hello.js"
    assert_equal "post bar = hello", body
  end

  should "properly route to first foo with two similar routes" do
    mock_app do
      controllers do
        get('/foo/') { "this is foo" }
        get(:show, :map => "/foo/:bar/:id") { "/foo/#{params[:bar]}/#{params[:id]}" }
      end
    end
    get "/foo"
    assert_equal "this is foo", body
    # TODO fix this in http_router, should pass
    get "/foo/"
    assert_equal "this is foo", body
    get '/foo/5/10'
    assert_equal "/foo/5/10", body
  end

  should "parse params with class level provides" do
    mock_app do
      controllers :posts, :provides => [:html, :js] do
        post(:create, :map => "/foo/:bar/:baz/:id") {
          "POST CREATE #{params[:bar]} - #{params[:baz]} - #{params[:id]}"
        }
      end
      controllers :topics, :provides => [:js, :html] do
        get(:show, :map => "/foo/:bar/:baz/:id") { render "topics/show" }
        post(:create, :map => "/foo/:bar/:baz") { "TOPICS CREATE #{params[:bar]} - #{params[:baz]}" }
      end
    end
    post "/foo/bar/baz.js"
    assert_equal "TOPICS CREATE bar - baz", body, "should parse params with explicit .js"
    post @app.url(:topics, :create, :format => :js, :bar => 'bar', :baz => 'baz')
    assert_equal "TOPICS CREATE bar - baz", body, "should parse params from generated url"
    post "/foo/bar/baz/5.js"
    assert_equal "POST CREATE bar - baz - 5", body
    post @app.url(:posts, :create, :format => :js, :bar => 'bar', :baz => 'baz', :id => 5)
    assert_equal "POST CREATE bar - baz - 5", body
  end

  should "parse params properly with inline provides" do
    mock_app do
      controllers :posts do
        post(:create, :map => "/foo/:bar/:baz/:id", :provides => [:html, :js]) {
          "POST CREATE #{params[:bar]} - #{params[:baz]} - #{params[:id]}"
        }
      end
      controllers :topics do
        get(:show, :map => "/foo/:bar/:baz/:id", :provides => [:html, :js]) { render "topics/show" }
        post(:create, :map => "/foo/:bar/:baz", :provides => [:html, :js]) { "TOPICS CREATE #{params[:bar]} - #{params[:baz]}" }
      end
    end
    post @app.url(:topics, :create, :format => :js, :bar => 'bar', :baz => 'baz')
    assert_equal "TOPICS CREATE bar - baz", body, "should properly post to topics create action"
    post @app.url(:posts, :create, :format => :js, :bar => 'bar', :baz => 'baz', :id => 5)
    assert_equal "POST CREATE bar - baz - 5", body, "should properly post to create action"
  end
end