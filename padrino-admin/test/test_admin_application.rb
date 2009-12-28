require File.dirname(__FILE__) + '/helper'

class TestAdminApplication < Test::Unit::TestCase

  should 'set basic roles' do
    mock_app do
      set :app_name, :test_me
      # Do a simple mapping
      roles_for :admin do |role, account|
        role.allow "/admin"
      end
      # Do test!
      assert_equal ["/admin"], access_control.maps_for(AdminAccount).allowed
      assert_equal [:admin], access_control.roles
      # Prepare a basic page
      get("/login"){ set_current_account(AdminAccount); "logged_in:#{logged_in?}, allowed?:#{allowed?}" }
    end
    get "/login"
    assert_equal "logged_in:true, allowed?:false", body
  end

end