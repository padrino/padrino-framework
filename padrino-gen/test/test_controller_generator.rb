require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "ControllerGenerator" do
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{SecureRandom.hex}"
    `mkdir -p #{@apptmp}`
    @controller_path = "#{@apptmp}/sample_project/app/controllers/demo_items.rb"
    @controller_test_path = "#{@apptmp}/sample_project/test/app/controllers/demo_items_controller_test.rb"
    @controller_with_parent_test_path = "#{@apptmp}/sample_project/test/app/controllers/user_items_controller_test.rb"
    @helper_path = "#{@apptmp}/sample_project/app/helpers/demo_items_helper.rb"
    @helper_test_path = "#{@apptmp}/sample_project/test/app/helpers/demo_items_helper_test.rb"
  end

  def teardown
    `rm -rf #{@apptmp}`
  end

  describe 'the controller generator' do
    it 'should fail outside app root' do
      out, err = capture_io { generate(:controller, 'demo', "-r=#{@apptmp}") }
      assert_match(/not at the root/, out)
      assert_no_file_exists("#{@apptmp}/app/controllers/demo.rb")
    end

    it 'should fail with NameError if given invalid namespace names' do
      capture_io { generate(:project, "sample", "--root=#{@apptmp}") }
      assert_raises(::NameError) { capture_io { generate(:controller, "wrong/name", "--root=#{@apptmp}/sample") } }
    end

    it 'should generate controller within existing project' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:controller, 'DemoItems', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/SampleProject::App.controllers :demo_items do/m, @controller_path)
      assert_match_in_file(/helpers DemoItemsHelper/, @helper_path)
      assert_dir_exists("#{@apptmp}/sample_project/app/views/demo_items")
      assert_file_exists(@controller_test_path)
    end

    it 'should generate helper within existing project' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:controller, 'DemoItems', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/module SampleProject/, @helper_path)
      assert_match_in_file(/class App/, @helper_path)
      assert_match_in_file(/module DemoItemsHelper/, @helper_path)
      assert_match_in_file(/helpers DemoItemsHelper/, @helper_path)
      assert_file_exists(@helper_path)
      assert_file_exists(@helper_test_path)
    end

    it 'should generate controller within existing project with weird name' do
      capture_io { generate(:project, 'warepedia', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:controller, 'DemoItems', "-r=#{@apptmp}/warepedia") }
      assert_match_in_file(/Warepedia::App.controllers :demo_items do/m, "#{@apptmp}/warepedia/app/controllers/demo_items.rb")
      assert_match_in_file(/helpers DemoItemsHelper/, "#{@apptmp}/warepedia/app/helpers/demo_items_helper.rb")
      assert_dir_exists("#{@apptmp}/warepedia/app/views/demo_items")
    end

    it 'should generate controller in specified app' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:controller, 'DemoItems','-a=/subby', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/SampleProject::Subby.controllers :demo_items do/m, @controller_path.gsub('app','subby'))
      assert_match_in_file(/helpers DemoItemsHelper/m, "#{@apptmp}/sample_project/subby/helpers/demo_items_helper.rb")
      assert_dir_exists("#{@apptmp}/sample_project/subby/views/demo_items")
      assert_match_in_file(/describe "\/demo_items" do/m, @controller_test_path.gsub('app','subby'))
      assert_match_in_file(/get "\/demo_items"/m, @controller_test_path.gsub('app','subby'))
    end

    it 'should generate controller with specified layout' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:controller, 'DemoItems', "-r=#{@apptmp}/sample_project", '-l=xyzlayout') }
      assert_match_in_file(/layout :xyzlayout/m, @controller_path)
    end

    it 'should generate controller without specified layout if empty' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:controller, 'DemoItems', "-r=#{@apptmp}/sample_project", '-l=') }
      assert_no_match_in_file(/layout/m, @controller_path)
    end

    it 'should generate controller with specified parent' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:controller, 'DemoItems', "-r=#{@apptmp}/sample_project", '-p=user') }
      assert_match_in_file(/SampleProject::App.controllers :demo_items, :parent => :user do/m, @controller_path)
      assert_match_in_file(/describe "\/user\/:user_id\/demo_items" do/, @controller_test_path)
      assert_match_in_file(/get "\/user\/1\/demo_items"/, @controller_test_path)
    end

    it 'should generate controller without specified parent' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:controller, 'DemoItems', "-r=#{@apptmp}/sample_project", '-p=') }
      assert_match_in_file(/SampleProject::App.controllers :demo_items do/m, @controller_path)
    end

    it 'should generate controller with specified providers' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:controller, 'DemoItems', "-r=#{@apptmp}/sample_project", '-f=:html, :js') }
      assert_match_in_file(/SampleProject::App.controllers :demo_items, :provides => \[:html, :js\] do/m, @controller_path)
    end

    it 'should generate controller without specified providers' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:controller, 'DemoItems', "-r=#{@apptmp}/sample_project", '-f=') }
      assert_match_in_file(/SampleProject::App.controllers :demo_items do/m, @controller_path)
    end

    it 'should not fail if we do not have test component' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=none') }
      capture_io { generate(:controller, 'DemoItems', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/SampleProject::App.controllers :demo_items do/m, @controller_path)
      assert_match_in_file(/helpers DemoItemsHelper/m, "#{@apptmp}/sample_project/app/helpers/demo_items_helper.rb")
      assert_dir_exists("#{@apptmp}/sample_project/app/views/demo_items")
      assert_no_file_exists("#{@apptmp}/sample_project/test")
    end

    it 'should generate controller test for bacon' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:controller, 'DemoItems','-a=/subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:controller, 'UserItems','-a=/subby', "-r=#{@apptmp}/sample_project", "-p=user") }
      assert_match_in_file(/(\/\.\.){2}/m, @controller_test_path.gsub('app','subby'))
      assert_match_in_file(/describe "\/demo_items" do/m, @controller_test_path.gsub('app','subby'))
      assert_match_in_file(/describe "\/user\/:user_id\/user_items"/, @controller_with_parent_test_path.gsub('app','subby'))
      assert_match_in_file(/get "\/demo_items"/m, @controller_test_path.gsub('app','subby'))
      assert_match_in_file(/get "\/user\/1\/user_items"/m, @controller_with_parent_test_path.gsub('app','subby'))
      assert_match_in_file(/describe "SampleProject::Subby::DemoItemsHelper" do/m, @helper_test_path.gsub('app','subby'))
    end

    it 'should generate controller test for minitest' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=minitest') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:controller, 'DemoItems','-a=/subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:controller, 'UserItems','-a=/subby', "-r=#{@apptmp}/sample_project", "-p=user") }
      assert_match_in_file(/(\/\.\.){2}/m, @controller_test_path.gsub('app', 'subby'))
      assert_match_in_file(/describe "\/demo_items" do/m, @controller_test_path.gsub('app', 'subby'))
      assert_match_in_file(/describe "\/user\/:user_id\/user_items"/, @controller_with_parent_test_path.gsub('app','subby'))
      assert_match_in_file(/get "\/demo_items"/m, @controller_test_path.gsub('app','subby'))
      assert_match_in_file(/get "\/user\/1\/user_items"/m, @controller_with_parent_test_path.gsub('app','subby'))
      assert_match_in_file(/describe "SampleProject::Subby::DemoItemsHelper" do/m, @helper_test_path.gsub('app','subby'))
    end

    it 'should generate controller test for rspec' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=rspec') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:controller, 'DemoItems','-a=/subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:controller, 'UserItems','-a=/subby', "-r=#{@apptmp}/sample_project", "-p=user") }
      assert_match_in_file(/describe "\/demo_items" do/m, "#{@apptmp}/sample_project/spec/subby/controllers/demo_items_controller_spec.rb")
      assert_match_in_file(/describe "\/user\/:user_id\/user_items"/,"#{@apptmp}/sample_project/spec/subby/controllers/user_items_controller_spec.rb")
      assert_match_in_file(/get "\/demo_items"/m, "#{@apptmp}/sample_project/spec/subby/controllers/demo_items_controller_spec.rb")
      assert_match_in_file(/get "\/user\/1\/user_items"/m, "#{@apptmp}/sample_project/spec/subby/controllers/user_items_controller_spec.rb")
      assert_match_in_file(/describe "SampleProject::Subby::DemoItemsHelper" do/m, "#{@apptmp}/sample_project/spec/subby/helpers/demo_items_helper_spec.rb")
    end

    it 'should generate controller test for shoulda' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=shoulda') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:controller, 'DemoItems','-a=/subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:controller, 'UserItems','-a=/subby', "-r=#{@apptmp}/sample_project", "-p=user") }
      expected_pattern = /class DemoItemsControllerTest < Test::Unit::TestCase/m
      expected_pattern2 = /class UserItemsControllerTest < Test::Unit::TestCase/m
      assert_match_in_file(expected_pattern, @controller_test_path.gsub('app','subby'))
      assert_match_in_file(/(\/\.\.){2}/m, @controller_test_path.gsub('app','subby'))
      assert_match_in_file(expected_pattern2, @controller_with_parent_test_path.gsub('app','subby'))
      assert_match_in_file(/context "SampleProject::Subby::DemoItemsHelper" do/m, @helper_test_path.gsub('app','subby'))
      assert_file_exists(@helper_test_path.gsub('app','subby'))
      assert_file_exists("#{@apptmp}/sample_project/test/subby/helpers/demo_items_helper_test.rb")
    end

    it 'should generate controller test for cucumber' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=cucumber') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:controller, 'DemoItems','-a=/subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:controller, 'UserItems','-a=/subby', "-r=#{@apptmp}/sample_project", "-p=user") }
      assert_match_in_file(/describe "\/demo_items" do/m, "#{@apptmp}/sample_project/spec/subby/controllers/demo_items_controller_spec.rb")
      assert_match_in_file(/describe "\/user\/:user_id\/user_items"/, "#{@apptmp}/sample_project/spec/subby/controllers/user_items_controller_spec.rb")
      assert_match_in_file(/get "\/demo_items"/m, "#{@apptmp}/sample_project/spec/subby/controllers/demo_items_controller_spec.rb")
      assert_match_in_file(/get "\/user\/1\/user_items"/m, "#{@apptmp}/sample_project/spec/subby/controllers/user_items_controller_spec.rb")
      assert_match_in_file(/Capybara.app = /, "#{@apptmp}/sample_project/features/support/env.rb")
    end

    it "should generate controller test for testunit" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=testunit') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:controller, 'DemoItems','-a=/subby', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class DemoItemsControllerTest < Test::Unit::TestCase/m, "#{@apptmp}/sample_project/test/subby/controllers/demo_items_controller_test.rb")
    end


    it 'should correctly generate file names' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=rspec') }
      capture_io { generate(:controller, 'DemoItems', "-r=#{@apptmp}/sample_project") }
      assert_dir_exists("#{@apptmp}/sample_project/app/views/demo_items")
      assert_file_exists("#{@apptmp}/sample_project/app/controllers/demo_items.rb")
      assert_file_exists("#{@apptmp}/sample_project/app/helpers/demo_items_helper.rb")
      assert_file_exists("#{@apptmp}/sample_project/spec/app/controllers/demo_items_controller_spec.rb")
      assert_file_exists("#{@apptmp}/sample_project/spec/app/helpers/demo_items_helper_spec.rb")
    end

    # Controller action generation
    it 'should generate actions for get:test post:yada' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=shoulda') }
      capture_io { generate(:controller, 'demo_items', "get:test", "post:yada","-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/get :test do\n\n  end\n/m, @controller_path)
      assert_match_in_file(/post :yada do\n\n  end\n/m, @controller_path)
    end

    describe "with 'no-helper' option" do
      it 'should not generate helper within existing project' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=rspec') }
        capture_io { generate(:controller, 'DemoItems', "-r=#{@apptmp}/sample_project", '--no-helper') }
        assert_dir_exists("#{@apptmp}/sample_project/app/views/demo_items")
        assert_file_exists("#{@apptmp}/sample_project/app/controllers/demo_items.rb")
        assert_file_exists("#{@apptmp}/sample_project/spec/app/controllers/demo_items_controller_spec.rb")
        assert_no_file_exists("#{@apptmp}/sample_project/app/helpers/demo_items_helper.rb")
        assert_no_file_exists("#{@apptmp}/sample_project/spec/app/helpers/demo_items_helper_spec.rb")
      end
    end
  end

  describe "the controller destroy option" do
    it 'should destroy controller files' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:controller, 'demo_items',"-r=#{@apptmp}/sample_project") }
      capture_io { generate(:controller, 'demo_items',"-r=#{@apptmp}/sample_project",'-d') }
      assert_no_file_exists(@controller_path)
      assert_no_file_exists(@controller_test_path)
      assert_no_file_exists("#{@apptmp}/sample_project/app/helpers/demo_items_helper.rb")
    end

    it 'should destroy controller files with rspec' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=rspec') }
      capture_io { generate(:controller, 'demo_items',"-r=#{@apptmp}/sample_project") }
      capture_io { generate(:controller, 'demo_items',"-r=#{@apptmp}/sample_project",'-d') }
      assert_no_file_exists(@controller_path)
      assert_no_file_exists("#{@apptmp}/sample_project/app/helpers/demo_items_helper.rb")
      assert_no_file_exists("#{@apptmp}/sample_project/spec/app/controllers/demo_items_controller_spec.rb")
    end

    it 'should destroy helper files with rspec' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=rspec') }
      capture_io { generate(:controller, 'demo_items',"-r=#{@apptmp}/sample_project") }
      capture_io { generate(:controller, 'demo_items',"-r=#{@apptmp}/sample_project",'-d') }
      assert_no_file_exists(@controller_path)
      assert_no_file_exists("#{@apptmp}/sample_project/app/helpers/demo_items_helper.rb")
      assert_no_file_exists("#{@apptmp}/sample_project/spec/app/helpers/demo_items_helper_spec.rb")
    end

    it 'should destroy controller files in sub apps' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:controller, 'demo_items',"-a=/subby","-r=#{@apptmp}/sample_project") }
      capture_io { generate(:controller, 'demo_items',"-a=/subby","-r=#{@apptmp}/sample_project",'-d') }
      assert_no_file_exists(@controller_path.gsub('app','subby'))
      assert_no_file_exists(@controller_test_path.gsub('app','subby'))
      assert_no_file_exists("#{@apptmp}/sample_project/app/helpers/demo_items_helper.rb")
    end
  end
end
