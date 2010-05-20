require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestMounter < Test::Unit::TestCase

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
      assert_equal "Test", mounter.app_class
      assert_equal "/path/to/test.rb", mounter.app_file
      assert_equal "/test", mounter.uri_root
      assert_equal File.dirname(mounter.app_file), mounter.app_root
    end

    should 'check locate_app_file with __FILE__' do
      mounter = Padrino::Mounter.new("test")
      mounter.to("/test")
      assert_equal "test", mounter.name
      assert_equal "Test", mounter.app_class
      assert_match %r{test/app.rb}, mounter.app_file
      assert_equal "/test", mounter.uri_root
      assert_equal File.dirname(mounter.app_file), mounter.app_root
    end

    should 'mount an app' do
      class ::AnApp < Padrino::Application; end
      Padrino.mount_core("an_app")
      assert_equal AnApp, Padrino.mounted_apps.first.app_obj
      assert_equal ["core"], Padrino.mounted_apps.collect(&:name)
    end

    should 'mount a core' do
      mounter = Padrino.mount_core("test")
      assert_equal "core", mounter.name
      assert_equal "Test", mounter.app_class
      assert_equal Test, mounter.app_obj
      assert_equal Padrino.root('app/app.rb'), mounter.app_file
      assert_equal "/", mounter.uri_root
      assert_equal File.dirname(mounter.app_file), mounter.app_root
    end
    
    should 'mount a core to url' do
      mounter = Padrino.mount_core("test").to('/me')
      assert_equal "core", mounter.name
      assert_equal "Test", mounter.app_class
      assert_equal Test, mounter.app_obj
      assert_equal Padrino.root('app/app.rb'), mounter.app_file
      assert_equal "/me", mounter.uri_root
      assert_equal File.dirname(mounter.app_file), mounter.app_root
    end

    should 'mount multiple apps' do
      class ::OneApp < Padrino::Application; end
      class ::TwoApp < Padrino::Application; end

      Padrino.mount("one_app").to("/one_app")
      Padrino.mount("two_app").to("/two_app")
      # And testing no duplicates
      Padrino.mount("one_app").to("/one_app")
      Padrino.mount("two_app").to("/two_app")

      assert_equal OneApp, Padrino.mounted_apps[0].app_obj
      assert_equal TwoApp, Padrino.mounted_apps[1].app_obj
      assert_equal 2, Padrino.mounted_apps.size, "should not mount duplicate apps"
      assert_equal ["one_app", "two_app"], Padrino.mounted_apps.collect(&:name)
    end

    should 'change mounted_root' do
      Padrino.mounted_root = "fixtures"
      assert_equal Padrino.root("fixtures", "test", "app.rb"), Padrino.mounted_root("test", "app.rb")
      Padrino.mounted_root = "apps"
      assert_equal Padrino.root("apps", "test", "app.rb"), Padrino.mounted_root("test", "app.rb")
      Padrino.mounted_root = nil
      assert_equal Padrino.root("test", "app.rb"), Padrino.mounted_root("test", "app.rb")
    end

    should 'correctly instantiate a new padrino application' do
      mock_app do
        get("/demo_1"){ "Im Demo 1" }
        get("/demo_2"){ "Im Demo 2" }
      end

      get '/demo_1'
      assert_equal "Im Demo 1", body
      get '/demo_2'
      assert_equal "Im Demo 2", body
    end
  end
end