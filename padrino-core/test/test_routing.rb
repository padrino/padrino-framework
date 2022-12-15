#encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/helper')

class FooError < RuntimeError; end

class RegexpLookAlike
  # RegexpLookAlike#to_s, RegexpLookAlike#names and MatchData#names must be defined.
  class MatchData
    def captures
      ["this", "is", "a", "test"]
    end

    def names
      ["one", "two", "three", "four"]
    end
  end

  def names
    ["one", "two", "three", "four"]
  end

  def to_s
    "/this/is/a/test/"
  end

  def match(string)
    ::RegexpLookAlike::MatchData.new if string == "/this/is/a/test/"
  end
end

describe "Routing" do
  before do
    Padrino.clear!
    ENV['RACK_BASE_URI'] = nil
  end

  it 'should serve static files with simple cache control' do
    mock_app do
      set :static_cache_control, :public
      set :public_folder, File.dirname(__FILE__)
    end
    get "/#{File.basename(__FILE__)}"
    assert headers.has_key?('Cache-Control')
    assert_equal headers['Cache-Control'], 'public'
  end # static simple

  it 'should serve static files with cache control and max_age' do
    mock_app do
      set :static_cache_control, [:public, :must_revalidate, {:max_age => 300}]
      set :public_folder, File.dirname(__FILE__)
    end
    get "/#{File.basename(__FILE__)}"
    assert headers.has_key?('Cache-Control')
    assert_equal headers['Cache-Control'], 'public, must-revalidate, max-age=300'
  end # static max_age

  it 'should render static files with custom status via options' do
    mock_app do
      set :static, true
      set :public_folder, File.dirname(__FILE__)

      post '/*' do
        static!(:status => params[:status])
      end
    end

    post "/#{File.basename(__FILE__)}?status=422"
    assert_equal response.status, 422
    assert_equal File.size(__FILE__).to_s, response['Content-Length']
    assert response.headers.include?('Last-Modified')
  end

  it 'should ignore trailing delimiters for basic route' do
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

  it 'should recognize route even if paths are duplicated' do
    mock_app do
      get(:index) {}
      get(:index, :with => :id) {}
      get(:index, :with => :id, :provides => :json) {}
    end
    assert_equal "/", @app.url_for(:index)
    assert_equal "/1234", @app.url_for(:index, :id => "1234")
    assert_equal "/1234.json?baz=baz", @app.url_for(:index, :id => "1234", :format => "json", :baz => "baz")
  end

  it 'should recognize route even if paths are duplicated, in reverse order' do
    mock_app do
      get(:index, :with => :id, :provides => :json) {}
      get(:index, :with => :id) {}
      get(:index) {}
    end
    assert_equal "/", @app.url_for(:index)
    assert_equal "/1234", @app.url_for(:index, :id => "1234")
    assert_equal "/1234.json?baz=baz", @app.url_for(:index, :id => "1234", :format => "json", :baz => "baz")
  end

  it 'should fail with unrecognized route exception when not found' do
    mock_app do
      get(:index){ "okey" }
    end
    get @app.url_for(:index)
    assert_equal "okey", body
    assert_raises(Padrino::Routing::UnrecognizedException) {
      get @app.url_for(:fake)
    }
  end

  it 'should fail with unrecognized route exception when namespace is invalid' do
    mock_app do
      controller :foo_bar do
        get(:index){ "okey" }
        get(:test_baz){ "okey" }
      end
    end
    assert_equal "/foo_bar", @app.url_for(:foo_bar, :index)
    assert_raises(Padrino::Routing::UnrecognizedException) {
      get @app.url_for(:foo, :bar, :index)
    }
    assert_raises(Padrino::Routing::UnrecognizedException) {
      get @app.url_for(:foo, :bar_index)
    }
    assert_equal "/foo_bar/test_baz", @app.url_for(:foo_bar, :test_baz)
    assert_raises(Padrino::Routing::UnrecognizedException) {
      get @app.url_for(:foo_bar, :test, :baz)
    }
    assert_raises(Padrino::Routing::UnrecognizedException) {
      get @app.url_for(:foo, :bar_test, :baz)
    }
    assert_raises(Padrino::Routing::UnrecognizedException) {
      get @app.url_for(:foo, :bar_test_baz)
    }
  end

  it 'should accept regexp routes' do
    mock_app do
      get(%r./fob|/baz.) { "regexp" }
      get("/foo")        { "str" }
      get %r./([0-9]+)/. do |num|
        "Your lucky number: #{num} #{params[:captures].first}"
      end
      get %r./page/([0-9]+)|/. do |num|
        "My lucky number: #{num} #{params[:captures].first}"
      end
    end
    get "/foo"
    assert_equal "str", body
    get "/fob"
    assert_equal "regexp", body
    get "/baz"
    assert_equal "regexp", body
    get "/321/"
    assert_equal "Your lucky number: 321 321", body
    get "/page/99"
    assert_equal "My lucky number: 99 99", body
  end

  it 'should ignore trailing slashes' do
    mock_app do
      get(%r./trailing.) { "slash" }
    end
    get "/trailing"
    assert_equal "slash", body
    get "/trailing/"
    assert_equal "slash", body
  end

  it 'should accept regexp routes with generate with :generate_with' do
    mock_app do
      get(%r{/fob|/baz}, :name => :foo, :generate_with => '/fob') { "regexp" }
    end
    assert_equal "/fob", @app.url(:foo)
  end

  it 'should parse routes with question marks' do
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

  it 'should parse routes that are encoded' do
    mock_app do
      get('/щч') { 'success!' }
    end
    get('/' + CGI.escape('щч'))
    assert_equal 'success!', body
  end

  it 'should parse routes that include encoded slash' do
    mock_app do
      get('/:drive_alias/:path', :path => /.*/){
        "Show #{params[:drive_alias]} and #{params[:path]}"
      }
    end
    get("/drive%2Ffoo/some/path")
    assert_equal "Show drive/foo and some/path", body
  end

  it 'should encode params using UTF-8' do
    mock_app do
      get('/:foo') { params[:foo].encoding.name }
    end
    get '/bar'
    assert_equal 'UTF-8', body
  end

  it 'should match correctly similar paths' do
    mock_app do
      get("/my/:foo_id"){ params[:foo_id] }
      get("/my/:bar_id/bar"){ params[:bar_id] }
    end
    get "/my/1"
    assert_equal "1", body
    get "/my/2/bar"
    assert_equal "2", body
  end

  it 'should match user agents' do
    app = mock_app do
      get("/main", :agent => /IE/){ "hello IE" }
      get("/main"){ "hello" }
    end
    get "/main"
    assert_equal "hello", body
    get "/main", {}, {'HTTP_USER_AGENT' => 'This is IE'}
    assert_equal "hello IE", body
  end

  it 'should use regex for parts of a route' do
    app = mock_app do
      get("/main/:id", :id => /\d+/){ "hello #{params[:id]}" }
    end
    get "/main/123"
    assert_equal "hello 123", body
    get "/main/asd"
    assert_equal 404, status
  end

  it 'should parse params when use regex for parts of a route' do
    mock_app do
      post :index, :with => [:foo, :bar], :bar => /.+/ do
        "show #{params[:foo]}"
      end

      get :index, :map => '/mystuff/:a_id/boing/:boing_id' do
        "show #{params[:a_id]} and #{params[:boing_id]}"
      end
    end
    get "/mystuff/5/boing/2"
    assert_equal "show 5 and 2", body
  end

  it 'should not generate overlapping head urls' do
    app = mock_app do
      get("/main"){ "hello" }
      post("/main"){ "hello" }
    end
    assert_equal 3, app.routes.size, "should generate GET, HEAD and PUT"
    assert_equal "GET",  app.routes[0].request_methods.first
    assert_equal "HEAD", app.routes[1].request_methods.first
    assert_equal "POST", app.routes[2].request_methods.first
  end

  it 'should generate basic urls' do
    mock_app do
      get(:foo){ "/foo" }
      get(:foo, :with => :id){ |id| "/foo/#{id}" }
      get([:foo, :id]){ |id| "/foo/#{id}" }
      get(:hash, :with => :id){ url(:hash, :id => 1) }
      get(:anchor) { url(:anchor, :anchor => 'comments') }
      get(:fragment) { url(:anchor, :fragment => 'comments') }
      get(:fragment2) { url(:anchor, :fragment => :comments) }
      get(:gangsta) { url(:gangsta, :foo => { :bar => :baz }, :hoge => :fuga) }
      get([:hash, :id]){ url(:hash, :id => 1) }
      get(:array, :with => :id){ url(:array, 23) }
      get([:array, :id]){ url(:array, 23) }
      get(:hash_with_extra, :with => :id){ url(:hash_with_extra, :id => 1, :query => 'string') }
      get([:hash_with_extra, :id]){ url(:hash_with_extra, :id => 1, :query => 'string') }
      get(:array_with_extra, :with => :id){ url(:array_with_extra, 23, :query => 'string') }
      get([:array_with_extra, :id]){ url(:array_with_extra, 23, :query => 'string') }
      get("/old-bar/:id"){ params[:id] }
      post(:mix, :map => "/mix-bar/:id"){ params[:id] }
      get(:mix, :map => "/mix-bar/:id"){ params[:id] }
      get(:foo, '', :with => :id){ |id| "/#{id}" }
      post(:foo, '', :with => :id){ |id| "/#{id}" }
      delete(:drugs, :with => [:id, 'destroy']){ |id| "/drugs/#{id}/destroy" }
      delete(:drugs, '', :with => [:id, 'destroy']){ |id| "/#{id}/destroy" }
      get(:splatter, "/splatter/*/*"){ |a, b| url(:splatter, :splat => ["123", "456"])  }
    end
    get "/foo"
    assert_equal "/foo", body
    get "/foo/123"
    assert_equal "/foo/123", body
    get "/hash/2"
    assert_equal "/hash/1", body
    get "/anchor"
    assert_equal "/anchor#comments", body
    get "/fragment"
    assert_equal "/anchor#comments", body
    get "/fragment2"
    assert_equal "/anchor#comments", body
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
    get "/123"
    assert_equal "/123", body
    post "/123"
    assert_equal "/123", body
    delete "/drugs/123/destroy"
    assert_equal "/drugs/123/destroy", body
    delete "/123/destroy"
    assert_equal "/123/destroy", body
    get "/gangsta"
    assert_equal "/gangsta?foo%5Bbar%5D=baz&hoge=fuga", body
    get "/splatter/123/456"
    assert_equal "/splatter/123/456", body
  end

  it 'should generate url with format' do
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

  it 'should generate absolute urls' do
    mock_app do
      get(:hash, :with => :id){ absolute_url(:hash, :id => 1) }
    end
    get "/hash/2"
    assert_equal "http://example.org/hash/1", body
    get "https://example.org/hash/2"
    assert_equal "https://example.org/hash/1", body
  end

  it 'should generate absolute urls from stringified keys' do
    mock_app do
      get(:hash, with: :id) { absolute_url(:hash, "id" => 1) }
    end
    get "/hash/2"
    assert_equal "http://example.org/hash/1", body
  end

  it 'should generate proper absolute urls for mounted apps' do
    class Test < Padrino::Application
      get :foo do
        absolute_url(:foo, :id => 1)
      end
    end
    Padrino.mount("Test").to("/test")
    @app = Padrino.application
    get('/test/foo')
    assert_equal 'http://example.org/test/foo?id=1', body
  end

  it 'should rebase simple string urls to app uri_root' do
    mock_app do
      set :uri_root, '/app'
      get(:a){ url('/foo') }
      get(:b){ url('bar') }
      get(:c){ absolute_url('/foo') }
      get(:d, :map => '/d/e/f'){ absolute_url('bar') }
    end
    get "/a"
    assert_equal "/app/foo", body
    get "/b"
    assert_equal "bar", body
    get "/c"
    assert_equal "http://example.org/app/foo", body
    get "/d/e/f"
    assert_equal "http://example.org/app/d/e/bar", body
  end

  it 'should allow regex url with format' do
    mock_app do
      get(/.*/, :provides => :any) { "regexp" }
    end
    get "/anything"
    assert_equal "regexp", body
  end

  it 'should use padrino url method' do
    mock_app do
    end

    assert_equal @app.method(:url).owner, Padrino::Routing::ClassMethods
  end

  it 'should work correctly with sinatra redirects' do
    mock_app do
      get(:index)  { redirect url(:index) }
      get(:google) { redirect "http://google.com" }
      get("/foo")  { redirect "/bar" }
      get("/bar")  { "Bar" }
    end

    get "/"
    assert_equal "http://example.org/", headers['Location']
    get "/google"
    assert_equal "http://google.com", headers['Location']
    get "/foo"
    assert_equal "http://example.org/bar", headers['Location']
  end

  it 'should return 406 on Accept-Headers it does not provide' do
    mock_app do
      get(:a, :provides => [:html, :js]){ content_type }
    end

    get "/a", {}, {"HTTP_ACCEPT" => "application/yaml"}
    assert_equal 406, status
  end

  it 'should return 406 on file extensions it does not provide and flag is set' do
    mock_app do
      enable :treat_format_as_accept
      get(:a, :provides => [:html, :js]){ content_type }
    end

    get "/a.xml", {}, {}
    assert_equal 406, status
  end

  it 'should provide proper content when :provides is specified and Accept: `*/*` requested' do
    mock_app do
      get(:text, :provides => :text) { "text" }
    end
    header 'Accept', '*/*'
    get "/text"
    assert_equal 200, status
    assert_equal "text", body
  end

  it 'should return 404 on file extensions it does not provide and flag is not set' do
    mock_app do
      get(:a, :provides => [:html, :js]){ content_type }
    end

    get "/a.xml", {}, {}
    assert_equal 404, status
  end

  it 'should not set content_type to :html if Accept */* and html not in provides' do
    mock_app do
      get("/foo", :provides => [:json, :xml]) { content_type.to_s }
    end

    get '/foo', {}, { 'HTTP_ACCEPT' => '*/*;q=0.5' }
    assert_equal 'json', body
  end

  it 'should set content_type to :json if Accept contains */*' do
    mock_app do
      get("/foo", :provides => [:json]) { content_type.to_s }
    end

    get '/foo', {}, { 'HTTP_ACCEPT' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' }
    assert_equal 'json', body
  end

  it 'should set and get content_type' do
    mock_app do
      get("/foo"){ content_type(:json); content_type.to_s }
    end
    get "/foo"
    assert_equal 'application/json', content_type
    assert_equal 'json', body
  end

  it 'should send the appropriate number of params' do
    mock_app do
      get('/id/:user_id', :provides => [:json]) { |user_id, format| user_id}
    end
    get '/id/5.json'
    assert_equal '5', body
  end

  it 'should allow "." in param values' do
    mock_app do
      get('/id/:email', :provides => [:json]) { |email, format| [email, format] * '/' }
    end
    get '/id/foo@bar.com.json'
    assert_equal 'foo@bar.com/json', body
  end

  it 'should set correct content_type for Accept not equal to */* even if */* also provided' do
    mock_app do
      get("/foo", :provides => [:html, :js, :xml]) { content_type.to_s }
    end

    get '/foo', {}, { 'HTTP_ACCEPT' => 'application/javascript, */*;q=0.5' }
    assert_equal 'js', body
  end

  it 'should return the first content type in provides if accept header is empty' do
    mock_app do
      get(:a, :provides => [:js]){ content_type.to_s }
    end

    get "/a", {}, {}
    assert_equal "js", body
  end

  it 'should not default to HTML if HTML is not provided and no type is given' do
    mock_app do
      get(:a, :provides => [:js]){ content_type }
    end

    get "/a", {}, {}
    assert_equal "application/javascript;charset=utf-8", content_type
  end

  it 'should not match routes if url_format and http_accept is provided but not included' do
    mock_app do
      get(:a, :provides => [:js, :html]){ content_type }
    end

    get "/a.xml", {}, {"HTTP_ACCEPT" => "text/html"}
    assert_equal 404, status
  end

  it 'should generate routes for format simple' do
    mock_app do
      get(:foo, :provides => [:html, :rss]) { "Test\n" }
    end
    get "/foo"
    assert_equal "Test\n", body
    get "/foo.rss"
    assert_equal "Test\n", body
  end

  it 'should inject the controller name into the request' do
    mock_app do
      controller :posts do
        get(:index) { request.controller }
        controller :mini do
          get(:index) { request.controller }
        end
      end
    end
    get "/posts"
    assert_equal "posts", body
    get "/mini"
    assert_equal "mini", body
  end

  it 'should inject the action name into the request' do
    mock_app do
      controller :posts do
        get('/omnomnom(/:id)?') { request.action.inspect }
        controller :mini do
          get([:a, :b, :c]) { request.action.inspect }
        end
      end
    end
    get "/posts/omnomnom"
    assert_equal "\"/omnomnom(/:id)?\"", body
    get "/mini/a/b/c"
    assert_equal ":a", body
  end

  it 'should support not_found' do
    mock_app do
      not_found { 'whatever' }

      get :index, :map => "/" do
        'index'
      end
    end
    get '/wrong'
    assert_equal 404, status
    assert_equal 'whatever', body
    get '/'
    assert_equal 'index', body
    assert_equal 200, status
  end

  it 'should inject the route into the request' do
    mock_app do
      controller :posts do
        get(:index) { request.route_obj.name.to_s }
      end
    end
    get "/posts"
    assert_equal "posts index", body
  end

  it 'should preserve the format if you set it manually' do
    mock_app do
      before do
        params[:format] = "json"
      end

      get "test", :provides => [:html, :json] do
        content_type.inspect
      end
    end
    get "/test"
    assert_equal ":json", body
    get "/test.html"
    assert_equal ":json", body
    get "/test.php"
    assert_equal ":json", body
  end

  it 'should correctly accept "." in the route' do
    mock_app do
      get "test.php", :provides => [:html, :json] do
        content_type.inspect
      end
    end
    get "/test.php"
    assert_equal ":html", body
    get "/test.php.json"
    assert_equal ":json", body
  end

  it 'should correctly accept priority of format' do
    mock_app do
      get "test.php", :provides => [:html, :json, :xml] do
        content_type.inspect
      end
    end

    get "/test.php"
    assert_equal ":html", body
    get "/test.php", {}, { 'HTTP_ACCEPT' => 'application/xml' }
    assert_equal ":xml", body
    get "/test.php?format=json", { 'HTTP_ACCEPT' => 'application/xml' }
    assert_equal ":json", body
    get "/test.php.json?format=html", { 'HTTP_ACCEPT' => 'application/xml' }
    assert_equal ":json", body
  end

  it 'should generate routes for format with controller' do
    mock_app do
      controller :posts do
        get(:index, :provides => [:html, :rss, :atom, :js]) { "Index.#{content_type}\n" }
        get(:show,  :with => :id, :provides => [:html, :rss, :atom]) { "Show.#{content_type}\n" }
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

  it 'should map routes' do
    mock_app do
      get(:bar){ "bar" }
    end
    get "/bar"
    assert_equal "bar", body
    assert_equal "/bar", @app.url(:bar)
  end

  it 'should remove index from path' do
    mock_app do
      get(:index){ "index" }
      get("/accounts/index"){ "accounts" }
    end
    get "/"
    assert_equal "index", body
    assert_equal "/", @app.url(:index)
    get "/accounts/index"
    assert_equal "accounts", body
  end

  it 'should remove index from path with params' do
    mock_app do
      get(:index, :with => :name){ "index with #{params[:name]}" }
    end
    get "/bobby"
    assert_equal "index with bobby", body
    assert_equal "/john", @app.url(:index, :name => "john")
  end

  it 'should parse named params' do
    mock_app do
      get(:print, :with => :id){ "Im #{params[:id]}" }
    end
    get "/print/9"
    assert_equal "Im 9", body
    assert_equal "/print/9", @app.url(:print, :id => 9)
  end

  it 'should 405 on wrong request_method' do
    mock_app do
      post('/bar'){ "bar" }
    end
    get "/bar"
    assert_equal 405, status
  end

  it 'should respond to' do
    mock_app do
      get(:a, :provides => :js){ "js" }
      get(:b, :provides => :any){ "any" }
      get(:c, :provides => [:js, :json]){ "js,json" }
      get(:d, :provides => [:html, :js]){ "html,js"}
    end
    get "/a"
    assert_equal 200, status
    assert_equal "js", body
    get "/a.js"
    assert_equal "js", body
    get "/b"
    assert_equal "any", body
    # TODO randomly fails in minitest :(
    # assert_raises(RuntimeError) { get "/b.foo" }
    get "/c"
    assert_equal 200, status
    assert_equal "js,json", body
    get "/c.js"
    assert_equal "js,json", body
    get "/c.json"
    assert_equal "js,json", body
    get "/d"
    assert_equal "html,js", body
    get "/d.js"
    assert_equal "html,js", body
  end

  it 'should respond_to and set content_type' do
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
    assert_equal 'application/json', response["Content-Type"]
    get "/a.foo"
    assert_equal "foo", body
    assert_equal 'application/foo', response["Content-Type"]
    get "/a"
    assert_equal "html", body
    assert_equal 'text/html;charset=utf-8', response["Content-Type"]
  end

  it 'should not drop json charset' do
    mock_app do
      get '/' do
        content_type :json, :charset => 'utf-16'
      end
      get '/a' do
        content_type :json, 'charset' => 'utf-16'
      end
    end
    get '/'
    assert_equal 'application/json;charset=utf-16', response["Content-Type"]
    get '/a'
    assert_equal 'application/json;charset=utf-16', response["Content-Type"]
  end

  it 'should use controllers' do
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

  it 'should use named controllers' do
    mock_app do
      controller :admin do
        get(:index, :with => :id){ params[:id] }
        get(:show, :with => :id){ "show #{params[:id]}" }
      end
      controllers :foo, :bar do
        get(:index){ "foo_bar_index" }
      end
    end
    get "/admin/1"
    assert_equal "1", body
    get "/admin/show/1"
    assert_equal "show 1", body
    assert_equal "/admin/1", @app.url(:admin, :index, :id => 1)
    assert_equal "/admin/show/1", @app.url(:admin, :show, :id => 1)
    get "/foo/bar"
    assert_equal "foo_bar_index", body
  end

  it 'should use map and with' do
    mock_app do
      get :index, :map => '/bugs', :with => :id do
        params[:id]
      end
    end
    get '/bugs/4'
    assert_equal '4', body
    assert_equal "/bugs/4", @app.url(:index, :id => 4)
  end

  it 'should ignore trailing delimiters within a named controller' do
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

  it 'should ignore trailing delimiters within a named controller for unnamed actions' do
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

  it 'should use named controllers with array routes' do
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

  it 'should support a reindex action and remove index inside controller' do
    mock_app do
      controller :posts do
        get(:index){ "index" }
        get(:reindex){ "reindex" }
      end
    end
    get "/posts"
    assert_equal "index", body
    get "/posts/reindex"
    assert_equal "/posts/reindex", @app.url(:posts, :reindex)
    assert_equal "reindex", body
  end

  it 'should use uri_root' do
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

  it 'should use uri_root with controllers' do
    mock_app do
      controller :foo do
        get(:bar){ "bar" }
      end
    end
    @app.uri_root = '/testing'
    assert_equal "/testing/foo/bar", @app.url(:foo, :bar)
  end

  it 'should use RACK_BASE_URI' do
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

  it 'should use uri_root and RACK_BASE_URI' do
    mock_app do
      controller :foo do
        get(:bar){ "bar" }
      end
    end
    ENV['RACK_BASE_URI'] = '/base'
    @app.uri_root = 'testing'
    assert_equal '/base/testing/foo/bar', @app.url(:foo, :bar)
    ENV['RACK_BASE_URI'] = nil
  end

  it 'should reset routes' do
    mock_app do
      get("/"){ "foo" }
      reset_router!
    end
    get "/"
    assert_equal 404, status
  end

  it 'should match params and format' do
    app = mock_app do
      get '/:id', :provides => [:json, :html] do |id, _|
        id
      end

      get 'format/:id', :provides => [:json, :html] do |id, format|
        format
      end
    end

    get '/123.html'
    assert_equal '123', body

    get 'format/123.html'
    assert_equal 'html', body
  end


  it 'should respect priorities' do
    route_order = []
    mock_app do
      get(:index, :priority => :normal) { route_order << :normal; pass }
      get(:index, :priority => :low)  { route_order << :low; "hello" }
      get(:index, :priority => :high)  { route_order << :high; pass }
    end
    get '/'
    assert_equal [:high, :normal, :low], route_order
    assert_equal "hello", body
  end

  it 'should set the params correctly even if using prioritized routes' do
    mock_app do
      get("*__sinatra__/:image.png"){}
      get "/:primary/:secondary", :priority => :low do
        "#{params[:primary]} #{params[:secondary]}"
      end
    end
    get "/abc/def"
    assert_equal "abc def", body
  end

  it 'should catch all after controllers' do
    mock_app do
      get(:index, :with => :slug, :priority => :low) { "catch all" }
      controllers :contact do
        get(:index) { "contact"}
      end
    end
    get "/contact"
    assert_equal "contact", body
    get "/foo"
    assert_equal "catch all", body
  end

  it 'should allow optionals' do
    mock_app do
      get(:show, :map => "/stories/:type(/:category)?") do
        "#{params[:type]}/#{params[:category]}"
      end
    end
    get "/stories/foo"
    assert_equal "foo/", body
    get "/stories/foo/bar"
    assert_equal "foo/bar", body
  end

  it 'should apply maps' do
    mock_app do
      controllers :admin do
        get(:index, :map => "/"){ "index" }
        get(:show, :with => :id, :map => "/show"){ "show #{params[:id]}" }
        get(:edit, :map => "/edit/:id/product"){ "edit #{params[:id]}" }
        get(:wacky, :map => "/wacky-:id-:product_id"){ "wacky #{params[:id]}-#{params[:product_id]}" }
      end
    end
    get "/"
    assert_equal "index", body
    get @app.url(:admin, :index)
    assert_equal "index", body
    get "/show/1"
    assert_equal "show 1", body
    get "/edit/1/product"
    assert_equal "edit 1", body
    get "/wacky-1-2"
    assert_equal "wacky 1-2", body
  end

  it 'should apply maps when given path is kind of hash' do
    mock_app do
      controllers :admin do
        get(:foobar, "/foo/bar"){ "foobar" }
      end
    end
    get "/foo/bar"
    assert_equal "foobar", body
  end

  it 'should apply parent to route' do
    mock_app do
      controllers :project do
        get(:index, :parent => :user) { "index #{params[:user_id]}" }
        get(:index, :parent => [:user, :section]) { "index #{params[:user_id]} #{params[:section_id]}" }
        get(:edit, :with => :id, :parent => :user) { "edit #{params[:id]} #{params[:user_id]}"}
        get(:show, :with => :id, :parent => [:user, :product]) { "show #{params[:id]} #{params[:user_id]} #{params[:product_id]}"}
      end
    end
    get "/user/1/project"
    assert_equal "index 1", body
    get "/user/1/section/3/project"
    assert_equal "index 1 3", body
    get "/user/1/project/edit/2"
    assert_equal "edit 2 1", body
    get "/user/1/product/2/project/show/3"
    assert_equal "show 3 1 2", body
  end

  it 'should respect parent precedence: controllers parents go before route parents' do
    mock_app do
      controllers :project do
        get(:index, :parent => :user) { "index #{params[:user_id]}" }
      end

      controllers :bar, :parent => :foo do
        get(:index) { "index on foo #{params[:foo_id]} @ bar" }
        get(:index, :parent => :baz) { "index on foo #{params[:foo_id]} @ baz #{params[:baz_id]} @ bar" }
      end
    end

    get "/user/1/project"
    assert_equal "index 1", body
    get "/foo/1/bar"
    assert_equal "index on foo 1 @ bar", body
    get "/foo/1/baz/2/bar"
    assert_equal "index on foo 1 @ baz 2 @ bar", body
  end

  it 'should keep a reference to the parent on the route' do
    mock_app do
      controllers :project do
        get(:index, :parent => :user) { "index #{params[:user_id]}" }
        get(:index, :parent => [:user, :section]) { "index #{params[:user_id]} #{params[:section_id]}" }
        get(:edit, :with => :id, :parent => :user) { "edit #{params[:id]} #{params[:user_id]}"}
        get(:show, :with => :id, :parent => [:user, :product]) { "show #{params[:id]} #{params[:user_id]} #{params[:product_id]}"}
      end

      controllers :bar, :parent => :foo do
        get(:index) { "index on foo/bar" }
        get(:index, :parent => :baz) { "index on foo/baz/bar" }
      end
    end

    # get "/user/1/project"
    assert_equal :user, @app.routes[0].parent
    # get "/user/1/section/3/project"
    assert_equal [:user, :section], @app.routes[2].parent
    # get "/user/1/project/edit/2"
    assert_equal :user, @app.routes[4].parent
    # get "/user/1/product/2/project/show/3"
    assert_equal [:user, :product], @app.routes[6].parent
    # get "/foo/1/bar"
    assert_equal :foo, @app.routes[8].parent
    # get "/foo/1/baz/2/bar"
    assert_equal [:foo, :baz], @app.routes[10].parent
  end

  it 'should apply parent to controller' do
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

  it 'should apply parent with shallowing to controller' do
    mock_app do
      controller :project do
        parent :user
        parent :shop, :optional => true
        get(:index) { "index #{params[:user_id]} #{params[:shop_id]}" }
        get(:edit, :with => :id) { "edit #{params[:id]} #{params[:user_id]} #{params[:shop_id]}" }
        get(:show, :with => :id, :parent => :product) { "show #{params[:id]} #{params[:user_id]} #{params[:product_id]} #{params[:shop_id]}" }
      end
    end

    assert_equal "/user/1/project", @app.url(:project, :index, :user_id => 1, :shop_id => nil)
    assert_equal "/user/1/shop/23/project", @app.url(:project, :index, :user_id => 1, :shop_id => 23)

    user_project_url = "/user/1/project"
    get user_project_url
    assert_equal "index 1 ", body
    assert_equal user_project_url, @app.url(:project, :index, :user_id => 1)

    user_project_edit_url = "/user/1/project/edit/2"
    get user_project_edit_url
    assert_equal "edit 2 1 ", body
    assert_equal user_project_edit_url, @app.url(:project, :edit, :user_id => 1, :id => 2)

    user_product_project_url = "/user/1/product/2/project/show/3"
    get user_product_project_url
    assert_equal "show 3 1 2 ", body
    assert_equal user_product_project_url, @app.url(:project, :show, :user_id => 1, :product_id => 2, :id => 3)

    user_project_url = "/user/1/shop/1/project"
    get user_project_url
    assert_equal "index 1 1", body
    assert_equal user_project_url, @app.url(:project, :index, :user_id => 1, :shop_id => 1)

    user_project_edit_url = "/user/1/shop/1/project/edit/2"
    get user_project_edit_url
    assert_equal "edit 2 1 1", body
    assert_equal user_project_edit_url, @app.url(:project, :edit, :user_id => 1, :id => 2, :shop_id => 1)

    user_product_project_url = "/user/1/shop/1/product/2/project/show/3"
    get user_product_project_url
    assert_equal "show 3 1 2 1", body
    assert_equal user_product_project_url, @app.url(:project, :show, :user_id => 1, :product_id => 2, :id => 3, :shop_id => 1)
  end

  it 'should respect map in parents with shallowing' do
    mock_app do
      controller :project do
        parent :shop, :map => "/foo/bar"
        get(:index) { "index #{params[:shop_id]}" }
      end
    end

    shop_project_url = "/foo/bar/1/project"
    get shop_project_url
    assert_equal "index 1", body
    assert_equal shop_project_url, @app.url(:project, :index, :shop_id => 1)
  end

  it 'should use default values' do
    mock_app do
      controller :lang => :it do
        get(:index, :map => "/:lang") { "lang is #{params[:lang]}" }
      end
      # This is only for be sure that default values
      # work only for the given controller
      get(:foo, :map => "/foo") {}
    end
    assert_equal "/it",  @app.url(:index)
    assert_equal "/foo", @app.url(:foo)
    get "/en"
    assert_equal "lang is en", body
  end

  it 'should override default values when parameters are passed' do
    mock_app do
      controller lang: :it do
        get(:index, map: '/:lang') { "lang is #{params[:lang]}" }
      end
    end
    assert_equal '/pt', @app.url(:index, lang: 'pt')
    get '/pt'
    assert_equal 'lang is pt', body
  end

  it 'should transitions to the next matching route on pass' do
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

  it 'should filters by media type' do
    mock_app do
      get '/foo', :accepts => [:xml, :json] do
        request.env['CONTENT_TYPE']
      end
    end

    get '/foo', {}, { 'CONTENT_TYPE' => 'application/xml' }
    assert ok?
    assert_equal 'application/xml', body
    assert_equal 'application/xml;charset=utf-8', response.headers['Content-Type']
    get '/foo'
    assert_equal 406, status
    get '/foo.xml'
    assert_equal 404, status

    get '/foo', {}, { 'CONTENT_TYPE' => 'application/json' }
    assert ok?
    assert_equal 'application/json', body
    assert_equal 'application/json', response.headers['Content-Type']
  end

  it 'should filters by media type when using :accepts as controller option' do
    mock_app do
      controller accepts: [:xml, :js] do
        get '/foo' do
          request.env['CONTENT_TYPE']
        end
      end
    end

    get '/foo', {}, { 'CONTENT_TYPE' => 'application/javascript' }
    assert ok?
    assert_equal 'application/javascript', body
  end

  it 'should filters by accept header' do
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

  it 'should does not allow global provides' do
    mock_app do
      provides :xml

      get("/foo"){ "Foo in #{content_type.inspect}" }
      get("/bar"){ "Bar in #{content_type.inspect}" }
    end

    get '/foo', {}, { 'HTTP_ACCEPT' => 'application/xml' }
    assert_equal 'Foo in :xml', body
    get '/foo'
    assert_equal 'Foo in :xml', body

    get '/bar', {}, { 'HTTP_ACCEPT' => 'application/xml' }
    assert_equal 'Bar in nil', body
  end

  it 'should does not allow global provides in controller' do
    mock_app do
      controller :base do
        provides :xml

        get(:foo, "/foo"){ "Foo in #{content_type.inspect}" }
        get(:bar, "/bar"){ "Bar in #{content_type.inspect}" }
      end
    end

    get '/foo', {}, { 'HTTP_ACCEPT' => 'application/xml' }
    assert_equal 'Foo in :xml', body
    get '/foo'
    assert_equal 'Foo in :xml', body

    get '/bar', {}, { 'HTTP_ACCEPT' => 'application/xml' }
    assert_equal 'Bar in nil', body
  end

  it 'should map non named routes in controllers' do
    mock_app do
      controller :base do
        get("/foo") { "ok" }
        get("/bar") { "ok" }
      end
    end

    get "/base/foo"
    assert ok?
    get "/base/bar"
    assert ok?
  end

  it 'should set content_type to :html for both empty Accept as well as Accept text/html' do
    mock_app do
      provides :html

      get("/foo"){ content_type.to_s }
    end

    get '/foo', {}, {}
    assert_equal 'html', body

    get '/foo', {}, { 'HTTP_ACCEPT' => 'text/html' }
    assert_equal 'html', body
  end

  it 'should set content_type to :html if Accept */*' do
    mock_app do
      get("/foo", :provides => [:html, :js]) { content_type.to_s }
    end
    get '/foo', {}, {}
    assert_equal 'html', body

    get '/foo', {}, { 'HTTP_ACCEPT' => '*/*;q=0.5' }
    assert_equal 'html', body
  end

  it 'should set content_type to :js if Accept includes both application/javascript and */*;q=0.5' do
    mock_app do
      get("/foo", :provides => [:html, :js]) { content_type.to_s }
    end
    get '/foo', {}, { 'HTTP_ACCEPT' => 'application/javascript, */*;q=0.5' }
    assert_equal 'js', body
  end

  it 'should set content_type to :html if Accept */* and provides of :any' do
    mock_app do
      get("/foo", :provides => :any) { content_type.to_s }
    end

    get '/foo', {}, { 'HTTP_ACCEPT' => '*/*' }
    assert_equal 'html', body
  end

  it 'should set content_type to :js if Accept includes both application/javascript, */*;q=0.5 and provides of :any' do
    mock_app do
      get("/foo", :provides => :any) { content_type.to_s }
    end

    get '/foo', {}, { 'HTTP_ACCEPT' => 'application/javascript, */*;q=0.5' }
    assert_equal 'js', body
  end

  it 'should allows custom route-conditions to be set via route options and halt' do
    protector = Module.new do
      def protect(*args)
        condition {
          unless authorize(params["user"], params["password"])
            halt 403, "go away"
          end
        }
      end
    end

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

  it 'should allows custom route-conditions to be set via route options using two routes' do
    protector = Module.new do
      def protect(*args)
        condition { authorize(params["user"], params["password"]) }
      end
    end

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

      get "/" do
        "go away"
      end
    end

    get "/"
    assert_equal "go away", body

    get "/", :user => "foo", :password => "bar"
    assert ok?
    assert_equal "hey", body
  end

  it 'should allow concise routing' do
    mock_app do
      get :index, ":id" do
        params[:id]
      end

      get :map, "route/:id" do
        params[:id]
      end
    end

    get "/123"
    assert_equal "123", body

    get "/route/123"
    assert_equal "123", body
  end

  it 'should support halting with 404 and message' do
    mock_app do
      controller do
        get :index do
          halt 404, "not found"
        end
      end
    end

    get "/"
    assert_equal 404, status
    assert_equal "not found", body
  end

  it 'should allow passing & halting in before filters' do
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

  it 'should scope filters in the given controller' do
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

  it 'should works with optionals params' do
    mock_app do
      get("/foo(/:bar)?") { params[:bar] }
    end

    get "/foo/bar"
    assert_equal "bar", body

    get "/foo"
    assert_equal "", body
  end

  it 'should work with multiple dashed params' do
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

  it 'should work with arbitrary params' do
    mock_app do
      get(:testing) { params[:foo] }
    end

    url = @app.url(:testing, :foo => 'bar')
    assert_equal "/testing?foo=bar", url
    get url
    assert_equal "bar", body
  end

  it 'should ignore nil params' do
    mock_app do
      get(:testing, :provides => [:html, :json]) do
      end
    end
    assert_equal '/testing.html', @app.url(:testing, :format => :html)
    assert_equal '/testing', @app.url(:testing, :format => nil)
  end

  it 'should be able to access params in a before filter' do
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

  it 'should be able to access params normally when a before filter is specified' do
    mock_app do
      before { }
      get :index do
        params.inspect
      end
    end
    get '/?test=what'
    assert_equal '{"test"=>"what"}', body
  end

  it 'should work only for the given controller and route when using before-filter with route name' do
    mock_app do
      controller :foo do
        before(:index) { @a = "only to :index" }
        get(:index) { @a }
        get(:main) { @a }
      end
    end
    get '/foo/'
    assert_equal 'only to :index', body
    get '/foo/main'
    assert_equal '', body
  end

  it 'should work only for the given controller and route when using after-filter with route name' do
    mock_app do
      controller :after_controller do
        global = "global variable"
        get(:index) { global }
        get(:main) { global }
        after(:index) { global = nil }
      end
    end
    get '/after_controller'
    assert_equal 'global variable', body
    get '/after_controller'
    assert_equal '', body
  end

  it 'should execute the before/after filters when they are inserted after the target route' do
    mock_app do
      controller :after_test do
        global = "global variable"
        get(:index) { global }
        get(:foo) { global }
        before(:index) { global.delete!(" ") }
        after(:index) { global = "after" }
      end
    end
    get '/after_test'
    assert_equal 'globalvariable', body
    get '/after_test/foo'
    assert_equal 'after', body
  end

  it 'should work with controller and arbitrary params' do
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

  it 'should parse two routes with the same path but different http verbs' do
    mock_app do
      get(:index) { "This is the get index" }
      post(:index) { "This is the post index" }
    end
    get "/"
    assert_equal "This is the get index", body
    post "/"
    assert_equal "This is the post index", body
  end

  it 'should use optionals params' do
    mock_app do
      get(:index, :map => "/:foo(/:bar)?") { "#{params[:foo]}-#{params[:bar]}" }
    end
    get "/foo"
    assert_equal "foo-", body
    get "/foo/bar"
    assert_equal "foo-bar", body
  end

  it 'should parse two routes with the same path but different http verbs and provides' do
    mock_app do
      get(:index, :provides => [:html, :json]) { "This is the get index.#{content_type}" }
      post(:index, :provides => [:html, :json]) { "This is the post index.#{content_type}" }
    end
    get "/"
    assert_equal "This is the get index.html", body
    post "/"
    assert_equal "This is the post index.html", body
    get "/.json"
    assert_equal "This is the get index.json", body
    get "/.js"
    assert_equal 404, status
    post "/.json"
    assert_equal "This is the post index.json", body
    post "/.js"
    assert_equal 404, status
  end

  it 'should allow controller level mapping' do
    mock_app do
      controller :map => "controller-:id" do
        get(:url3) { "#{params[:id]}" }
        get(:url4, :map => 'test-:id2') { "#{params[:id]}, #{params[:id2]}" }
      end
    end

    url = @app.url(:url3, :id => 1)
    assert_equal "/controller-1/url3", url
    get url
    assert_equal "1", body

    url = @app.url(:url4, 1, 2)
    assert_equal "/controller-1/test-2", url
    get url
    assert_equal "1, 2", body
  end

  it 'should replace name of named controller with mapping path' do
    mock_app do
      controller :ugly, :map => "/pretty/:id" do
        get(:url3) { "#{params[:id]}" }
        get(:url4, :map => 'test-:id2') { "#{params[:id]}, #{params[:id2]}" }
      end
      controller :voldemort, :map => "" do
        get(:url5) { "okay" }
      end
    end

    url = @app.url(:ugly, :url3, :id => 1)
    assert_equal "/pretty/1/url3", url
    get url
    assert_equal "1", body

    url = @app.url(:ugly, :url4, 3, 5)
    assert_equal "/pretty/3/test-5", url
    get url
    assert_equal "3, 5", body

    url = @app.url(:voldemort, :url5)
    assert_equal "/url5", url
    get url
    assert_equal 'okay', body
  end

  it 'should use absolute and relative maps' do
    mock_app do
      controller :one do
        parent :three
        get :index, :map => 'one' do; end
        get :index2, :map => '/one' do; end
      end

      controller :two, :map => 'two' do
        parent :three
        get :index, :map => 'two' do; end
        get :index2, :map => '/two', :with => :id do; end
      end
    end
    assert_equal "/three/three_id/one", @app.url(:one, :index, 'three_id')
    assert_equal "/one", @app.url(:one, :index2)
    assert_equal "/two/three/three_id/two", @app.url(:two, :index, 'three_id')
    assert_equal "/two/four_id", @app.url(:two, :index2, 'four_id')
  end

  it 'should work with params and parent options' do
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

  it 'should parse params without explicit provides for every matching route' do
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

  it 'should properly route to first foo with two similar routes' do
    mock_app do
      controllers do
        get('/foo/') { "this is foo" }
        get(:show, :map => "/foo/:bar/:id") { "/foo/#{params[:bar]}/#{params[:id]}" }
      end
    end
    get "/foo"
    assert_equal "this is foo", body
    get "/foo/"
    assert_equal "this is foo", body
    get '/foo/5/10'
    assert_equal "/foo/5/10", body
  end

  it 'should index routes should be optional when nested' do
    mock_app do
      controller '/users', :provides => [:json] do
        get '/' do
          "foo"
        end
      end
    end
    get "/users.json"
    assert_equal "foo", body
  end

  it 'should use provides as conditional' do
    mock_app do
      provides :json
      get "/" do
        "foo"
      end
    end
    get "/.json"
    assert_equal "foo", body
  end

  it 'should reset provides for routes that did not use it' do
    mock_app do
      get('/foo', :provides => :js){}
      get('/bar'){}
    end
    get '/foo'
    assert ok?
    get '/foo.js'
    assert ok?
    get '/bar'
    assert ok?
    get '/bar.js'
    assert_equal 404, status
  end

  it 'should pass controller conditions to each route' do
    counter = 0

    mock_app do
      self.class.send(:define_method, :increment!) do |*args|
        condition { counter += 1 }
      end

      controller :posts, :conditions => {:increment! => true} do
        get("/foo") { "foo" }
        get("/bar") { "bar" }
      end

    end

    get "/posts/foo"
    get "/posts/bar"
    assert_equal 2, counter
  end

  it 'should allow controller conditions to be overridden' do
    counter = 0

    mock_app do
      self.class.send(:define_method, :increment!) do |increment|
        condition { counter += 1 } if increment
      end

      controller :posts, :conditions => {:increment! => true} do
        get("/foo") { "foo" }
        get("/bar", :increment! => false) { "bar" }
      end

    end

    get "/posts/foo"
    get "/posts/bar"
    assert_equal 1, counter
  end

  it 'should parse params with class level provides' do
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

  it 'should parse params properly with inline provides' do
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

  it 'should have overideable format' do
    ::Rack::Mime::MIME_TYPES[".other"] = "text/html"
    mock_app do
      before do
        params[:format] ||= :other
      end
      get("/format_test", :provides => [:html, :other]){ content_type.to_s }
    end
    get "/format_test"
    assert_equal "other", body
    ::Rack::Mime::MIME_TYPES.delete('.other')
  end

  it 'should invokes handlers registered with ::error when raised' do
    mock_app do
      set :raise_errors, false
      error(FooError) { 'Foo!' }
      get '/' do
        raise FooError
      end
    end
    get '/'
    assert_equal 500, status
    assert_equal 'Foo!', body
  end

  it 'should have MethodOverride middleware' do
    mock_app do
      put('/') { 'okay' }
    end
    assert @app.method_override?
    post '/', {'_method'=>'PUT'}, {}
    assert_equal 200, status
    assert_equal 'okay', body
  end

  it 'should return value from params' do
    mock_app do
      get("/foo/:bar"){ raise "'bar' should be a string" unless params[:bar].kind_of? String}
    end
    get "/foo/50"
    assert ok?
  end

  it 'should return params as a HashWithIndifferentAccess object via GET' do
    mock_app do
      get('/foo/:bar') { "#{params["bar"]} #{params[:bar]}" }
      get(:foo, :map => '/prefix/:var') { "#{params["var"]} #{params[:var]}" }
    end

    get('/foo/some_text')
    assert_equal "some_text some_text", body

    get('/prefix/var')
    assert_equal "var var", body
  end

  it 'should return params as a HashWithIndifferentAccess object via POST' do
    mock_app do
      post('/user') do
        "#{params["user"]["full_name"]} #{params[:user][:full_name]}"
      end
    end

    post '/user', {:user => {:full_name => 'example user'}}
    assert_equal "example user example user", body

    post '/user', {"user" => {"full_name" => 'example user'}}
    assert_equal "example user example user", body
  end

  it 'should have MethodOverride middleware with more options' do
    mock_app do
      put('/hi', :provides => [:json]) { 'hi' }
    end
    post '/hi', {'_method'=>'PUT'}
    assert_equal 200, status
    assert_equal 'hi', body
    post '/hi.json', {'_method'=>'PUT'}
    assert_equal 200, status
    assert_equal 'hi', body
    post '/hi.json'
    assert_equal 405, status
  end

  it 'should parse nested params' do
    mock_app do
      get(:index) { "%s %s" % [params[:account][:name], params[:account][:surname]] }
    end
    get "/?" + Padrino::Utils.build_uri_query(:account => { :name => 'foo', :surname => 'bar' })
    assert_equal 'foo bar', body
    get @app.url(:index, "account[name]" => "foo", "account[surname]" => "bar")
    assert_equal 'foo bar', body
  end

  it 'should render sinatra NotFound page' do
    mock_app { set :environment, :development }
    get "/"
    assert_equal 404, status
    assert_match %r{Not Found}, body
  end

  it 'should render a custom NotFound page' do
    mock_app do
      error(Sinatra::NotFound) { "not found" }
    end
    get "/"
    assert_equal 404, status
    assert_match /not found/, body
  end

  it 'should render a custom 404 page using not_found' do
    mock_app do
      not_found { "custom 404 not found" }
    end
    get "/"
    assert_equal 404, status
    assert_equal "custom 404 not found", body
  end

  it 'should render a custom error page using error method' do
    mock_app do
      error(404) { "custom 404 error" }
    end
    get "/"
    assert_equal 404, status
    assert_equal "custom 404 error", body
  end

  it 'should render a custom 403 page' do
    mock_app do
      error(403) { "custom 403 not found" }
      get("/") { status 403 }
    end
    get "/"
    assert_equal 403, status
    assert_equal "custom 403 not found", body
  end

  it 'should recognize paths' do
    mock_app do
      controller :foo do
        get(:bar, :map => "/my/:id/custom-route") { }
      end
      get(:simple, :map => "/simple/:id") { }
      get(:with_format, :with => :id, :provides => :js) { }
    end
    assert_equal [:"foo bar", { "id" => "fantastic" }], @app.recognize_path(@app.url(:foo, :bar, :id => :fantastic))
    assert_equal [:"foo bar", { "id" => "18" }], @app.recognize_path(@app.url(:foo, :bar, :id => 18))
    assert_equal [:simple, { "id" => "bar" }], @app.recognize_path(@app.url(:simple, :id => "bar"))
    assert_equal [:simple, { "id" => "true" }], @app.recognize_path(@app.url(:simple, :id => true))
    assert_equal [:simple, { "id" => "9" }], @app.recognize_path(@app.url(:simple, :id => 9))
    assert_equal [:with_format, { "id" => "bar", "format" => "js" }], @app.recognize_path(@app.url(:with_format, :id => "bar", :format => :js))
    assert_equal [:with_format, { "id" => "true", "format" => "js" }], @app.recognize_path(@app.url(:with_format, :id => true, :format => "js"))
    assert_equal [:with_format, { "id" => "9", "format" => "js" }], @app.recognize_path(@app.url(:with_format, :id => 9, :format => :js))
  end

  it 'should have current_path' do
    mock_app do
      controller :foo do
        get(:index) { current_path }
        get :bar, :map => "/paginate/:page" do
          current_path
        end
        get(:after) { current_path }
      end
    end
    get "/paginate/10"
    assert_equal "/paginate/10", body
    get "/foo/after"
    assert_equal "/foo/after", body
    get "/foo"
    assert_equal "/foo", body
  end

  it 'should accept :map and :parent' do
    mock_app do
      controller :posts do
        get :show, :parent => :users, :map => "posts/:id" do
          "#{params[:user_id]}-#{params[:id]}"
        end
      end
    end
    get '/users/123/posts/321'
    assert_equal "123-321", body
  end

  it 'should change params in current_path' do
    mock_app do
      get :index, :map => "/paginate/:page" do
        current_path(:page => 66)
      end
    end
    get @app.url(:index, :page => 10)
    assert_equal "/paginate/66", body
  end

  it 'should not route get :users, :with => :id to /users//' do
    mock_app do
      get(:users, :with => :id) { 'boo' }
    end
    get '/users//'
    assert_equal 404, status
  end

  it "should support splat params" do
    mock_app do
      get "/say/*/to/*" do
        params[:splat].inspect
      end
    end
    get "/say/hello/to/world"
    assert_equal %Q[["hello", "world"]], body
  end

  it "should recognize the route containing splat params if path is ended with slash" do
    mock_app do
      get "/splat/*" do
        "slash!"
      end
    end
    get "/splat"
    assert_equal 404, status
    get "/splat/"
    assert_equal "slash!", body
  end

  it "should match correctly paths even if the free regex route exists" do
    mock_app do
      get %r{/b/(?<aa>\w+)/(?<bb>\w+)} do
        "free regex"
      end

      put '/b/:b/:c', :csrf_protection => false do
        params.inspect
      end
    end
    put "/b/x/y"
    assert_equal '{"b"=>"x", "c"=>"y"}', body
  end

  it "should support named captures like %r{/hello/(?<person>[^/?#]+)} on Ruby >= 1.9" do
    mock_app do
      get Regexp.new('/hello/(?<person>[^/?#]+)') do
        "Hello #{params['person']}"
      end
    end
    get '/hello/Frank'
    assert_equal 'Hello Frank', body
  end

  it 'supports regular expression look-alike routes' do
    mock_app do
      get(RegexpLookAlike.new) do
        [params[:one], params[:two], params[:three], params[:four]].join(" ")
      end
    end

    get '/this/is/a/test/'
    assert ok?
    assert_equal 'this is a test', body
  end

  it "uses optional block passed to pass as route block if no other route is found" do
    mock_app do
      get "/" do
        pass do
          "this"
        end
        "not this"
      end
    end

    get "/"
    assert ok?
    assert_equal "this", body
  end

  it "supports mixing multiple splat params like /*/foo/*/* as block parameters" do
    mock_app do
      get '/*/foo/*/*' do |foo, bar, baz|
        "#{foo}, #{bar}, #{baz}"
      end
    end

    get '/bar/foo/bling/baz/boom'
    assert ok?
    assert_equal 'bar, bling, baz/boom', body
  end

  it "should be able to use PathRouter#recognize to recognize routes" do
    mock_app do
      get(:sample){}
    end
    env = Rack::MockRequest.env_for("/sample")
    request = Rack::Request.new(env)
    assert_equal :sample, @app.router.recognize(request).first.name
  end

  it "should be able to use PathRouter#recognize to recognize routes by using Rack::MockRequest" do
    mock_app do
      get(:mock_sample){}
    end
    env = Rack::MockRequest.env_for("/mock_sample")
    assert_equal :mock_sample, @app.router.recognize(env).first.name
    env = Rack::MockRequest.env_for("/invalid")
    assert_equal [], @app.router.recognize(env)
  end

  it "should be able to use params after sending request" do
    last_app = mock_app do
      get("/foo/:id"){ params.inspect }
    end
    get "/foo/123"
    assert_equal({"id"=>"123"}, Thread.current['padrino.instance'].instance_variable_get(:@params))
  end

  it "should raise an exception if block arity is not same with captured params size" do
    assert_raises(Padrino::Routing::BlockArityError) do
      mock_app do
        get("/sample/:a/:b") { |a| }
      end
    end
  end

  it "should pass format value as a block parameter" do
    mock_app do
      get "/sample/:a/:b", :provides => :xml do |a, b, format|
        "#{a}, #{b}, #{format}"
      end
    end
    get "/sample/foo/bar"
    assert_equal "foo, bar, ", body
    get "/sample/foo/bar.xml"
    assert_equal "foo, bar, xml", body
  end

  it "should allow negative arity in route block" do
    mock_app do
      get("/:a/sample/*/*") { |*all| }
    end
  end

  it "should be able to use splat and named captues" do
    mock_app do
      get("/:a/:b/*/*/*") { |a, b, *splats| "#{a}, #{b}, (#{splats * ","})" }
    end
    get "/123/456/a/b/c"
    assert_equal "123, 456, (a,b,c)", body
  end

  it "can modify the request" do
    mock_app do
      get('/foo') { request.path_info = '/bar'; pass }
      get('/bar') { 'bar' }
    end

    get '/foo'
    assert ok?
    assert_equal 'bar', body
  end

  it 'should generate urls and absolute urls' do
    mock_app do
      get(:index) { settings.url(:index) }
      get(:absolute) { settings.absolute_url(:absolute) }
    end
    get '/'
    assert_equal '/', body
    get '/absolute'
    assert_equal 'http://localhost/absolute', body
    @app.set :base_url, 'http://example.com'
    get '/absolute'
    assert_equal 'http://example.com/absolute', body
  end

  it 'should not match if route regexps matches with incorrect_path[0..2]' do
    mock_app do
      get(:index) { "bork" }
      get("/foo") { "foo" }
    end
    get "/"
    assert_equal 200, status
    get "/a"
    assert_equal 404, status
    get "/foo"
    assert_equal 200, status
    get "/fo"
    assert_equal 404, status
  end

  it "should maintain Sinatra's params indifference" do
    mock_app do
      get '/update', :with => :id do
        "#{params[:product]['title']}==#{params[:product][:title]}"
      end
    end
    get '/update/1?product[title]=test'
    assert_equal 'test==test', body
  end

  it "prevent overwriting params by given query" do
    mock_app do
      get '/prohibit/:id' do
        params[:id]
      end
    end
    get '/prohibit/123?id=456'
    assert_equal '123', body
  end

  it "functions in a standalone app" do
    mock_app(Sinatra::Application) do
      register Padrino::Routing
      get(:index) { 'Standalone' }
    end
    get '/'
    assert_equal 200, status
  end
end
