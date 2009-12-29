require File.dirname(__FILE__) + '/helper'

class TestAdminApplication < Test::Unit::TestCase

  should 'set basic roles' do
    mock_app do
      enable :authentication
      set :app_name, :test_me
      # Do a simple mapping
      access_control.roles_for :admin do |role, account|
        role.allow "/admin"
      end
      # Do test!
      assert_equal ["/admin"], access_control.maps_for(Account.admin).allowed
      assert_equal [:admin], access_control.roles
      # Prepare a basic page
      get("/admin") do
        set_current_account(Account.admin)
        "logged_in:#{logged_in?}, allowed?:#{allowed?}"
      end
      get("/login") do
        "logged_in:#{logged_in?}, allowed?:#{allowed?}"
      end
    end
    get "/admin"
    assert_equal "logged_in:true, allowed?:true", body
    get "/login"
    assert_equal "logged_in:true, allowed?:false", body
  end

end