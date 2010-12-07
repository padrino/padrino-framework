require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestControllerGenerator < Test::Unit::TestCase
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{UUID.new.generate}"
    `mkdir -p #{@apptmp}`
    @controller_path = "#{@apptmp}/sample_project/app/controllers/demo_items.rb"
    @controller_test_path = "#{@apptmp}/sample_project/test/controllers/demo_items_controller_test.rb"
  end

  def teardown
    `rm -rf #{@apptmp}`
  end

  context 'the controller generator' do
    should "fail outside app root" do
      output = silence_logger { generate(:controller, 'demo', "-r=#{@apptmp}") }
      assert_match(/not at the root/, output)
      assert_no_file_exists("#{@apptmp}/app/controllers/demo.rb")
    end

    should "generate controller within existing project" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      silence_logger { generate(:controller, 'DemoItems', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/SampleProject.controllers :demo_items do/m, @controller_path)
      assert_match_in_file(/SampleProject.helpers do/m, "#{@apptmp}/sample_project/app/helpers/demo_items_helper.rb")
      assert_file_exists("#{@apptmp}/sample_project/app/views/demo_items")
    end

    should "generate controller within existing project with weird name" do
      silence_logger { generate(:project, 'warepedia', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      silence_logger { generate(:controller, 'DemoItems', "-r=#{@apptmp}/warepedia") }
      assert_match_in_file(/Warepedia.controllers :demo_items do/m, "#{@apptmp}/warepedia/app/controllers/demo_items.rb")
      assert_match_in_file(/Warepedia.helpers do/m, "#{@apptmp}/warepedia/app/helpers/demo_items_helper.rb")
      assert_file_exists("#{@apptmp}/warepedia/app/views/demo_items")
    end

    should "generate controller in specified app" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      silence_logger { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      silence_logger { generate(:controller, 'DemoItems','-a=/subby', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/Subby.controllers :demo_items do/m, @controller_path.gsub('app','subby'))
      assert_match_in_file(/Subby.helpers do/m, "#{@apptmp}/sample_project/subby/helpers/demo_items_helper.rb")
      assert_file_exists("#{@apptmp}/sample_project/subby/views/demo_items")
      assert_match_in_file(/describe "DemoItemsController" do/m, @controller_test_path.gsub('app','subby'))
    end

    should 'not fail if we don\'t have test component' do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=none') }
      silence_logger { generate(:controller, 'DemoItems', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/SampleProject.controllers :demo_items do/m, @controller_path)
      assert_match_in_file(/SampleProject.helpers do/m, "#{@apptmp}/sample_project/app/helpers/demo_items_helper.rb")
      assert_file_exists("#{@apptmp}/sample_project/app/views/demo_items")
      assert_no_file_exists("#{@apptmp}/sample_project/test")
    end

    should "generate controller test for bacon" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      silence_logger { generate(:controller, 'DemoItems', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/describe "DemoItemsController" do/m, @controller_test_path)
    end

    should "generate controller test for riot" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=riot') }
      silence_logger { generate(:controller, 'DemoItems', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/context "DemoItemsController" do/m, @controller_test_path)
    end

    should "generate controller test for testspec" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=testspec') }
      silence_logger { generate(:controller, 'DemoItems', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/context "DemoItemsController" do/m, @controller_test_path)
    end

    should "generate controller test for rspec" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=rspec') }
      silence_logger { generate(:controller, 'DemoItems', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/describe "DemoItemsController" do/m, "#{@apptmp}/sample_project/spec/controllers/demo_items_controller_spec.rb")
    end

    should "generate controller test for shoulda" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=shoulda') }
      silence_logger { generate(:controller, 'DemoItems', "-r=#{@apptmp}/sample_project") }
      expected_pattern = /class DemoItemsControllerTest < Test::Unit::TestCase/m
      assert_match_in_file(expected_pattern, @controller_test_path)
      assert_file_exists("#{@apptmp}/sample_project/test/controllers/demo_items_controller_test.rb")
    end

    should "generate controller test for cucumber" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=cucumber') }
      silence_logger { generate(:controller, 'DemoItems', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/describe "DemoItemsController" do/m, "#{@apptmp}/sample_project/spec/controllers/demo_items_controller_spec.rb")
      assert_match_in_file(/Capybara.app = /, "#{@apptmp}/sample_project/features/support/env.rb")
    end

    should "correctly generate file names" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=rspec') }
      silence_logger { generate(:controller, 'DemoItems', "-r=#{@apptmp}/sample_project") }
      assert_file_exists("#{@apptmp}/sample_project/app/views/demo_items")
      assert_file_exists("#{@apptmp}/sample_project/app/controllers/demo_items.rb")
      assert_file_exists("#{@apptmp}/sample_project/app/helpers/demo_items_helper.rb")
      assert_file_exists("#{@apptmp}/sample_project/spec/controllers/demo_items_controller_spec.rb")
    end

    # Controller action generation
    should "generate actions for get:test post:yada" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=shoulda') }
      silence_logger { generate(:controller, 'demo_items', "get:test", "post:yada","-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/get :test do\n  end\n/m, @controller_path)
      assert_match_in_file(/post :yada do\n  end\n/m, @controller_path)
    end
  end

  context "the controller destroy option" do
    should "destroy controller files" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      silence_logger { generate(:controller, 'demo_items',"-r=#{@apptmp}/sample_project") }
      silence_logger { generate(:controller, 'demo_items',"-r=#{@apptmp}/sample_project",'-d') }
      assert_no_file_exists(@controller_path)
      assert_no_file_exists(@controller_test_path)
      assert_no_file_exists("#{@apptmp}/sample_project/app/helpers/demo_items_helper.rb")
    end

    should "destroy controller files with rspec" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=rspec') }
      silence_logger { generate(:controller, 'demo_items',"-r=#{@apptmp}/sample_project") }
      silence_logger { generate(:controller, 'demo_items',"-r=#{@apptmp}/sample_project",'-d') }
      assert_no_file_exists(@controller_path)
      assert_no_file_exists("#{@apptmp}/sample_project/app/helpers/demo_items_helper.rb")
      assert_no_file_exists("#{@apptmp}/sample_project/spec/controllers/demo_items_controller_spec.rb")
    end
  end
end
