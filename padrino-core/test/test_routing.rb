require File.dirname(__FILE__) + '/helper'

class TestRouting < Test::Unit::TestCase

  should 'ignore trailing delimiters' do
    mock_app do
      get("/foo"){ "okey" }
    end
    get "/foo"
    assert_equal "okey", body
    get "/foo/"
    assert_equal "okey", body
  end

  should 'match correcly similar paths' do
    mock_app do
      get("/my/:foo_id"){ params[:foo_id] }
      get("/my/:bar_id/bar"){ params[:bar_id] }
    end
    get "/my/1"
    assert_equal "1", body
    get "/my/2/bar"
    assert_equal "2", body
  end

  should 'generate basic urls'do
    mock_app do
      get(:foo){ url(:foo) }
      get(:bar, :with => :id){ url(:bar, :id => 1) }
      get("/old-bar/:id"){ params[:id] }
      post(:mix, :map => "/mix-bar/:id"){ params[:id] }
      get(:mix, :map => "/mix-bar/:id"){ params[:id] }
    end
    get "/foo"
    assert_equal "/foo", body
    get "/bar/2"
    assert_equal "/bar/1", body
    get "/old-bar/3"
    assert_equal "3", body
    post "/mix-bar/4"
    assert_equal "4", body
    get "/mix-bar/4"
    assert_equal "4", body
  end

  should 'generate url with format' do
    mock_app do
      get(:a, :respond_to => :any){ url(:a, :format => :json) }
      get(:b, :respond_to => :js){ url(:b, :format => :js) }
      get(:c, :respond_to => [:js, :json]){ url(:c, :format => :json) }
      get(:d, :respond_to => [:html, :js]){ url(:d, :format => :js, :foo => :bar) }
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
    get "/d.json"
    assert 404, status
    get "/d"
    assert_equal "/d.js?foo=bar", body
    get "/d.js"
    assert_equal "/d.js?foo=bar", body
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

  should 'parse named params' do
    mock_app do
      get(:print, :with => :id){ "Im #{params[:id]}" }
    end
    get "/print/9"
    assert_equal "Im 9", body
    assert_equal "/print/9", @app.url(:print, :id => 9)
  end

  should 'respond to' do
    mock_app do
      get(:a, :respond_to => :js){ "js" }
      get(:b, :respond_to => :any){ "any" }
      get(:c, :respond_to => [:js, :json]){ "js,json" }
      get(:d, :respond_to => [:html, :js]){ "html,js"}
    end
    get "/a"
    assert_equal 404, status
    get "/a.js"
    assert_equal "js", body
    get "/b"
    assert_equal "any", body
    get "/b.foo"
    assert_equal "any", body
    get "/c"
    assert_equal 404, status
    get "/c.fo"
    assert_equal 404, status
    get "/c.js"
    assert_equal "js,json", body
    get "/c.json"
    assert_equal "js,json", body
    get "/d"
    assert_equal "html,js", body
    get "/d.fo"
    assert_equal 404, status
    get "/d.js"
    assert_equal "html,js", body
  end

  should 'respond_to and set content_type' do
    mock_app do
      get :a, :respond_to => :any do
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
    assert_equal 'application/octet-stream', response["Content-Type"]
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

end