require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "HelperGenerator" do
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{SecureRandom.hex}"
    `mkdir -p #{@apptmp}`
    @helper_path = "#{@apptmp}/sample_project/app/helpers/demo_items_helper.rb"
    @helper_test_path = "#{@apptmp}/sample_project/test/app/helpers/demo_items_helper_test.rb"
  end

  def teardown
    `rm -rf #{@apptmp}`
  end

  describe 'the helper generator' do
    it 'should fail outside app root' do
      out, err = capture_io { generate(:helper, 'demo', "-r=#{@apptmp}") }
      assert_match(/not at the root/, out)
      assert_no_file_exists("#{@apptmp}/app/helpers/demo_helper.rb")
    end

    it 'should fail with NameError if given invalid namespace names' do
      capture_io { generate(:project, "sample", "--root=#{@apptmp}") }
      assert_raises(::NameError) { capture_io { generate(:helper, "wrong/name", "--root=#{@apptmp}/sample") } }
    end

    it 'should generate helper within existing project' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:helper, 'DemoItems', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/module SampleProject/, @helper_path)
      assert_match_in_file(/class App/, @helper_path)
      assert_match_in_file(/module DemoItemsHelper/, @helper_path)
      assert_match_in_file(/helpers DemoItemsHelper/, @helper_path)
      assert_file_exists(@helper_path)
      assert_file_exists(@helper_test_path)
    end

    it 'should generate helper within existing project with weird name' do
      capture_io { generate(:project, 'warepedia', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:helper, 'DemoItems', "-r=#{@apptmp}/warepedia") }
      assert_match_in_file(/helpers DemoItemsHelper/, "#{@apptmp}/warepedia/app/helpers/demo_items_helper.rb")
    end

    it 'should generate helper in specified app' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:helper, 'DemoItems','-a=/subby', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/helpers DemoItemsHelper/m, "#{@apptmp}/sample_project/subby/helpers/demo_items_helper.rb")
    end

    it 'should not fail if we do not have test component' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=none') }
      capture_io { generate(:helper, 'DemoItems', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/helpers DemoItemsHelper/m, "#{@apptmp}/sample_project/app/helpers/demo_items_helper.rb")
      assert_no_file_exists("#{@apptmp}/sample_project/test")
    end

    it 'should generate helper test for bacon' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:helper, 'DemoItems','-a=/subby', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/describe "SampleProject::Subby::DemoItemsHelper" do/m, @helper_test_path.gsub('app','subby'))
    end

    it 'should generate helper test for minitest' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=minitest') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:helper, 'DemoItems','-a=/subby', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/describe "SampleProject::Subby::DemoItemsHelper" do/m, @helper_test_path.gsub('app','subby'))
    end

    it 'should generate helper test for rspec' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=rspec') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:helper, 'DemoItems','-a=/subby', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/describe "SampleProject::Subby::DemoItemsHelper" do/m, "#{@apptmp}/sample_project/spec/subby/helpers/demo_items_helper_spec.rb")
    end

    it 'should generate helper test for shoulda' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=shoulda') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:helper, 'DemoItems','-a=/subby', "-r=#{@apptmp}/sample_project") }
      expected_pattern = /class DemoItemsHelperTest < Test::Unit::TestCase/m
      assert_match_in_file(/context "SampleProject::Subby::DemoItemsHelper" do/m, @helper_test_path.gsub('app','subby'))
      assert_file_exists(@helper_test_path.gsub('app','subby'))
      assert_file_exists("#{@apptmp}/sample_project/test/subby/helpers/demo_items_helper_test.rb")
    end

    it "should generate helper test for testunit" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=testunit', '--script=none') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:helper, 'DemoItems','-a=/subby', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class DemoItemsHelperTest < Test::Unit::TestCase/m, "#{@apptmp}/sample_project/test/subby/helpers/demo_items_helper_test.rb")
      assert_match_in_file(/@helpers\.extend SampleProject::Subby::DemoItemsHelper/m, "#{@apptmp}/sample_project/test/subby/helpers/demo_items_helper_test.rb")
    end

    it 'should correctly generate file names' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=rspec') }
      capture_io { generate(:helper, 'DemoItems', "-r=#{@apptmp}/sample_project") }
      assert_file_exists("#{@apptmp}/sample_project/app/helpers/demo_items_helper.rb")
      assert_file_exists("#{@apptmp}/sample_project/spec/app/helpers/demo_items_helper_spec.rb")
    end
  end

  describe "the helper destroy option" do
    it 'should destroy helper files' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:helper, 'demo_items',"-r=#{@apptmp}/sample_project") }
      capture_io { generate(:helper, 'demo_items',"-r=#{@apptmp}/sample_project",'-d') }
      assert_no_file_exists(@helper_path)
      assert_no_file_exists(@helper_test_path)
      assert_no_file_exists("#{@apptmp}/sample_project/app/helpers/demo_items_helper.rb")
    end

    it 'should destroy helper files with rspec' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=rspec') }
      capture_io { generate(:helper, 'demo_items',"-r=#{@apptmp}/sample_project") }
      capture_io { generate(:helper, 'demo_items',"-r=#{@apptmp}/sample_project",'-d') }
      assert_no_file_exists(@helper_path)
      assert_no_file_exists("#{@apptmp}/sample_project/app/helpers/demo_items_helper.rb")
      assert_no_file_exists("#{@apptmp}/sample_project/spec/app/helpers/demo_items_helper_spec.rb")
    end

    it 'should destroy helper files in sub apps' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:helper, 'demo_items',"-a=/subby","-r=#{@apptmp}/sample_project") }
      capture_io { generate(:helper, 'demo_items',"-a=/subby","-r=#{@apptmp}/sample_project",'-d') }
      assert_no_file_exists("#{@apptmp}/sample_project/app/helpers/demo_items_helper.rb")
    end
  end
end
