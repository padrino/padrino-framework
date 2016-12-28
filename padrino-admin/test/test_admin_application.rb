require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "AdminApplication" do

  def setup
    load_fixture 'sequel'
  end

  describe "session id setting" do
    it "should provide it if it doesn't exist" do
      mock_app do
        set :app_name, 'session_id_tester'
        register Padrino::Admin::AccessControl
      end

      assert_equal "_padrino_test_session_id_tester", @app.session_id
    end

    it "should preserve it if it already existed" do
      mock_app do
        set :session_id, "foo"
        register Padrino::Admin::AccessControl
      end
      assert_equal "foo", @app.session_id
    end
  end

  it 'should require correctly login' do
    mock_app do
      register Padrino::Admin::AccessControl
      enable :sessions

      # Do a simple mapping
      access_control.roles_for :any do |role|
        role.protect  "/foo"
      end

      get "/foo", :provides => [:html, :js] do
        "foo"
      end

      get "/unauthenticated" do
        "unauthenticated"
      end

    end

    get "/foo"
    assert_equal "You don't have permission for this resource", body

    get "/unauthenticated"
    assert_equal "unauthenticated", body
  end

  it 'should set basic roles with store location and login page' do
    mock_app do
      set    :app_name, :basic_app
      register Padrino::Admin::AccessControl
      enable :store_location
      enable :sessions
      set    :login_page, "/login"

      access_control.roles_for :any do |role|
        role.protect "/foo"
      end

      # Prepare a basic page
      get "/login" do
        redirect_back_or_default("/foo") if logged_in?
        set_current_account(Account.admin)
        "login page"
      end

      get "/foo" do
        "foo"
      end
    end

    get "/foo"
    follow_redirect!
    assert_equal "login page", body

    get "/foo"
    assert_equal "foo", body

    get "/login"
    follow_redirect!
    assert_equal "foo", body
  end

  it 'should set advanced roles with store location and login page' do
    mock_app do
      register Padrino::Admin::AccessControl
      enable :sessions

      access_control.roles_for :any do |role|
        role.protect "/"
        role.allow "/login"
        role.allow "/any"
      end

      access_control.roles_for :admin do |role|
        role.project_module :settings, "/settings"
      end

      access_control.roles_for :editor do |role|
        role.project_module :posts, "/posts"
      end

      # Prepare a basic page
      get "/login(/:role)?" do
        set_current_account(Account.send(params[:role])) if params[:role]
        "logged as #{params[:role] || "any"}"
      end

      get "/any"      do; "any";      end
      get "/settings" do; "settings"; end
      get "/posts"    do; "posts";    end
    end

    assert @app.access_control.allowed?(Account.admin, "/login")
    assert @app.access_control.allowed?(Account.admin, "/any")
    assert @app.access_control.allowed?(Account.admin, "/settings")
    assert ! @app.access_control.allowed?(Account.admin, "/posts")

    assert @app.access_control.allowed?(Account.editor, "/login")
    assert @app.access_control.allowed?(Account.editor, "/any")
    assert ! @app.access_control.allowed?(Account.editor, "/settings")
    assert @app.access_control.allowed?(Account.editor, "/posts")

    get "/login"
    assert_equal "logged as any", body

    get "/any"
    assert_equal "any", body

    get "/settings"
    assert_equal "You don't have permission for this resource", body

    get "/posts"
    assert_equal "You don't have permission for this resource", body

    get "/login/admin"
    assert_equal "logged as admin", body

    get "/any"
    assert_equal "any", body

    get "/settings"
    assert_equal "settings", body

    get "/posts"
    assert_equal "You don't have permission for this resource", body

    get "/login/editor"
    assert_equal "logged as editor", body

    get "/any"
    assert_equal "any", body

    get "/settings"
    assert_equal "You don't have permission for this resource", body

    get "/posts"
    assert_equal "posts", body
  end

  it 'should emulate an ecommerce app' do
    mock_app do
      register Padrino::Admin::AccessControl
      enable :sessions

      access_control.roles_for :any do |role|
        role.protect "/cart"
        role.allow "/cart/add"
        role.allow "/cart/empty"
      end

      get "/login" do
        set_current_account(Account.admin)
        "Logged in"
      end

      get "/cart/checkout" do
        "Checkout"
      end

      get "/cart/add" do
        "Product Added"
      end

      get "/cart/empty" do
        "Cart Empty"
      end
    end

    get "/cart/checkout"
    assert_equal "You don't have permission for this resource", body

    get "/cart/add"
    assert_equal "Product Added", body

    get "/cart/empty"
    assert_equal "Cart Empty", body

    get "/login"
    assert_equal "Logged in", body

    get "/cart/checkout"
    assert_equal "Checkout", body

    get "/cart/add"
    assert_equal "Product Added", body

    get "/cart/empty"
    assert_equal "Cart Empty", body
  end

  it 'should check access control helper' do
    mock_app do
      register Padrino::Admin::AccessControl
      enable :sessions

      access_control.roles_for :any do |role|
        role.project_module :foo, "/foo"
        role.project_module :bar, "/bar"
      end

      access_control.roles_for :admin do |role|
        role.project_module :admin, "/admin"
      end

      access_control.roles_for :editor do |role|
        role.project_module :editor, "/editor"
      end

      get "/login" do
        set_current_account(Account.admin)
        "Logged in"
      end

      get "/roles" do
        access_control.roles.join(", ")
      end

      get "/modules" do
        project_modules.map { |pm| "#{pm.name} => #{pm.path}" }.join(", ")
      end

      get "/modules-prefixed" do
        project_modules.map { |pm| "#{pm.name} => #{pm.path("/admin")}" }.join(", ")
      end
    end

    get "/roles"
    assert_equal "admin, editor", body

    get "/modules"
    assert_equal "foo => /foo, bar => /bar", body

    get "/modules-prefixed"
    assert_equal "foo => /admin/foo, bar => /admin/bar", body

    get "/login"
    assert_equal "Logged in", body

    get "/modules"
    assert_equal "admin => /admin", body
  end

  it 'should use different access control for different apps' do
    app1 = Sinatra.new Padrino::Application do
      register Padrino::Admin::AccessControl
      access_control.roles_for :any do |role|
        role.project_module :foo, "/foo"
      end
    end
    app2 = Sinatra.new Padrino::Application do
      register Padrino::Admin::AccessControl
      access_control.roles_for :any do |role|
        role.project_module :bar, "/bar"
      end
    end
    assert_equal '/foo', app1.access_control.project_modules(:any).first.path
    assert_equal '/bar', app2.access_control.project_modules(:any).first.path
  end
end
