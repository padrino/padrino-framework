require File.dirname(__FILE__) + '/helper'

class TestPadrinoMounter < Test::Unit::TestCase

  def setup
    Padrino.mounted_apps.clear
  end

  context 'for mounter functionality' do
    
    should 'check methods' do
      mounter = Padrino::Mounter.new("test", :app_file => "/path/to/test.rb")
      mounter.to("/test")
      assert_kind_of Padrino::Mounter, mounter
      assert_respond_to Padrino::Mounter, :new
      assert_respond_to mounter, :to
      assert_respond_to mounter, :map_onto
      assert_equal "test", mounter.name
      assert_equal "/path/to/test.rb", mounter.app_file
      assert_equal "/test", mounter.uri_root
      assert_nil mounter.app_root
    end

    should 'mount an app' do
      class AnApp < Padrino::Application; end
      
      Padrino.mount_core("an_app")
      assert_equal ["core"], Padrino.mounted_apps.collect(&:name)
    end

    should 'mount multiple apps' do
      class OneApp < Padrino::Application; end
      class TwoApp < Padrino::Application; end
      
      Padrino.mount("one_app").to("/one_app")
      Padrino.mount("two_app").to("/two_app")

      assert_equal ["one_app", "two_app"], Padrino.mounted_apps.collect(&:name)
    end

    should 'correctly instantiate a new padrino application' do
      mock_app do
        get("/demo_1"){ "Im Demo 1" }
        get("/demo_2"){ "Im Demo 2" }
      end
      
      get '/demo_1'
      assert_contain "Im Demo 1"
      visit '/demo_2'
      assert_contain "Im Demo 2"
    end
  end
end