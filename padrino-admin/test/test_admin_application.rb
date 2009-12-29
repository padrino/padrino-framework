require File.dirname(__FILE__) + '/helper'

class TestAdminApplication < Test::Unit::TestCase

  should 'set basic roles' do
    mock_app do
      enable :authentication
      set    :app_name, :test_me

      # Do a simple mapping
      access_control.roles_for :any do |role| 
        role.allow "/"
        role.deny  "/foo"
      end

      # Prepare a basic page
      get("/login") do
        set_current_account(Account.admin)
      end

      get("/foo") do
        "foo"
      end
    end

    get "/login"
    assert_equal 200, status
    
    get "/foo"
    assert_not_equal "foo", body
  end

end