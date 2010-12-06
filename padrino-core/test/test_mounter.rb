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
      mounter = Padrino::Mounter.new("test", :app_file => __FILE__)
      mounter.to("/test")
      assert_equal "test", mounter.name
      assert_equal "Test", mounter.app_class
      assert_equal __FILE__, mounter.app_file
      assert_equal "/test", mounter.uri_root
      assert_equal File.dirname(mounter.app_file), mounter.app_root
    end

    should 'mount an app' do
      class ::AnApp < Padrino::Application; end
      Padrino.mount("an_app").to("/")
      assert_equal AnApp, Padrino.mounted_apps.first.app_obj
      assert_equal ["an_app"], Padrino.mounted_apps.collect(&:name)
    end

    should 'mount a primary app to root uri' do
      mounter = Padrino.mount("test", :app_file => __FILE__).to("/")
      assert_equal "test", mounter.name
      assert_equal "Test", mounter.app_class
      assert_equal Test, mounter.app_obj
      assert_equal __FILE__, mounter.app_file
      assert_equal "/", mounter.uri_root
      assert_equal File.dirname(mounter.app_file), mounter.app_root
    end

    should 'mount a primary app to sub_uri' do
      mounter = Padrino.mount("test", :app_file => __FILE__).to('/me')
      assert_equal "test", mounter.name
      assert_equal "Test", mounter.app_class
      assert_equal Test, mounter.app_obj
      assert_equal __FILE__, mounter.app_file
      assert_equal "/me", mounter.uri_root
      assert_equal File.dirname(mounter.app_file), mounter.app_root
    end

    should "raise error when app has no located file" do
      assert_raise(Padrino::Mounter::MounterException) { Padrino.mount("tester_app").to('/test') }
      assert_equal 0, Padrino.mounted_apps.size
    end

    should "raise error when app has no located object" do
      assert_raise(Padrino::Mounter::MounterException) { Padrino.mount("tester_app", :app_file => "/path/to/file.rb").to('/test') }
      assert_equal 0, Padrino.mounted_apps.size
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

    should "be able to access routes data for mounted apps" do
      class ::OneApp < Padrino::Application
        get("/test") { "test" }
        get(:index, :provides => [:js, :json]) { "index" }
        controllers :posts do
          get(:index) { "index" }
          get(:new, :provides => :js) { "new" }
          get(:show, :provides => [:js, :html], :with => :id) { "show" }
          post(:create, :provides => :js, :with => :id) { "create" }
        end
      end
      class ::TwoApp < Padrino::Application
        controllers :users do
          get(:index) { "users" }
          get(:new) { "users new" }
          post(:create) { "users create" }
          put(:update) { "users update" }
          delete(:destroy) { "users delete" }
        end
      end

      Padrino.mount("one_app").to("/")
      Padrino.mount("two_app").to("/two_app")

      assert_equal 11, Padrino.mounted_apps[0].routes.size
      assert_equal 7, Padrino.mounted_apps[1].routes.size
      assert_equal 5, Padrino.mounted_apps[0].named_routes.size
      assert_equal 5, Padrino.mounted_apps[1].named_routes.size

      first_route = Padrino.mounted_apps[0].named_routes[3]
      assert_equal "posts_show", first_route.identifier.to_s
      assert_equal "(:posts, :show)", first_route.name
      assert_equal "GET", first_route.verb
      assert_equal "/posts/show/:id(.:format)", first_route.path
      another_route = Padrino.mounted_apps[1].named_routes[2]
      assert_equal "users_create", another_route.identifier.to_s
      assert_equal "(:users, :create)", another_route.name
      assert_equal "POST", another_route.verb
      assert_equal "/two_app/users/create", another_route.path
    end
    
    should 'correctly build urls for one app with different mount points' do
      class ::OneApp < Padrino::Application
        controllers do
          get(:index) { "index" }
          get(:foo) { "foo" }
          get(:bar) { url(:foo) }
        end
      end

      Padrino.mount("one_app").to("/one_app")
      Padrino.mount("one_app", :app_class => "OneApp").to("/two_app")
      
      res = Rack::MockRequest.new(Padrino.application).get("/one_app/bar")
      assert res.ok?
      assert_equal '/one_app/foo', res.body
      res = Rack::MockRequest.new(Padrino.application).get("/two_app/bar")
      assert res.ok?
      assert_equal '/two_app/foo', res.body
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

    should "not clobber the public setting when mounting an app" do
      class ::PublicApp < Padrino::Application
        set :root, "/root"
        set :public, File.expand_path(File.dirname(__FILE__))
      end

      Padrino.mount("public_app").to("/public")
      res = Rack::MockRequest.new(Padrino.application).get("/public/test_mounter.rb")
      assert res.ok?
      assert_equal File.read(__FILE__), res.body
    end
  end
end
