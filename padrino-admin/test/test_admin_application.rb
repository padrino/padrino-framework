require File.dirname(__FILE__) + '/helper'

class TestAdminApplication < Test::Unit::TestCase

  should 'set basic roles' do
    mock_app do
      roles_for :admin do |role|
        role.allow "/admin"
      end
      assert_equal ["/admin"], access_control.maps_for(:admin).allowed
      assert_equal [:admin], access_control.roles
      get("/"){ access_control.maps_for(:admin).allowed.first }
    end
    get "/"
    assert_equal "/admin", body
  end

end