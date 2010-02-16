require 'helper'

class TestAdminApplication < Test::Unit::TestCase

  def setup
    load_fixture 'data_mapper'
  end

  should 'require correctly login' do
    mock_app do
      enable :authentication
      set    :app_name, :test_me
      set    :use_orm,  :datamapper

      # Do a simple mapping
      access_control.roles_for :any do |role| 
        role.allow "/"
        role.require_login  "/foo"
      end

      get "/foo", :respond_to => [:html, :js] do
        "foo"
      end
    end

    get "/foo"
    assert_equal "You don't have permission for this resource", body

    get "/foo.js"
    assert_equal "alert('Protected resource')", body
  end

  should 'set basic roles with store location and login page' do
    mock_app do
      enable :authentication
      enable :store_location
      set    :login_page, "/login"
      set    :app_name, :test_me
      set    :use_orm,  :datamapper

      # Do a simple mapping
      access_control.roles_for :any do |role| 
        role.allow "/"
        role.require_login "/foo"
      end

      # Prepare a basic page
      get "/login" do
        assert_equal "[]", admin_menu
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

    get "/login"
    follow_redirect!
    assert_equal "foo", body
  end

  should 'use correclty flash middleware' do
    mock_app do
      use Padrino::Admin::Middleware::FlashMiddleware, :session_id

      get "/set_session_id" do
        params[:session_id]
      end

      get "/get_session_id" do
        session[:session_id]
      end
    end

    get "/set_session_id", { :session_id => 24 }, 'HTTP_USER_AGENT' => 'Adobe Flash'
    assert_equal "24", body

    # TODO: inspect why this fail on Ruby 1.9.1
    unless RUBY_VERSION >= '1.9'
      get "/get_session_id"
      assert_equal "24", body
    end
  end

end