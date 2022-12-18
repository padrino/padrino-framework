require File.expand_path(File.dirname(__FILE__) + '/helper')
require "rb-readline"

describe "ComponentGenerator" do
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{SecureRandom.hex}"
    `mkdir -p #{@apptmp}`
  end

  def teardown
    `rm -rf #{@apptmp}`
  end

  describe 'the controller generator' do
    it 'should fail outside app root' do
      out, err = capture_io { generate(:component, 'demo', "-r=#{@apptmp}") }
      assert_match(/not at the root/, out)
    end
  end

  describe "add components" do
    it 'should properly generate default' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      out, err = capture_io { generate(:component, '--orm=activerecord', "-r=#{@apptmp}/sample_project") }
      assert_match(/applying.*?activerecord.*?orm/, out)
      assert_match_in_file(/gem 'activerecord', '>= 3.1', :require => 'active_record'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'sqlite3'/, "#{@apptmp}/sample_project/Gemfile")
      refute_match(/Switch renderer to/, out)
      database_template_path = File.join(File.dirname(__FILE__), 'fixtures', 'database_template.rb')
      assert FileUtils.compare_file("#{@apptmp}/sample_project/config/database.rb", database_template_path)
      components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
      assert_equal 'activerecord', components_chosen[:orm]
    end

    it 'should properly generate with adapter' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      out, err = capture_io { generate(:component, '--orm=sequel', '--adapter=postgres', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/gem 'pg'/, "#{@apptmp}/sample_project/Gemfile")
      refute_match(/Switch renderer to/, out)
      components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
      assert_equal 'sequel', components_chosen[:orm]
    end

    it 'should enable @app_name value' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      out, err = capture_io { generate_with_parts(:component, '--test=cucumber', "-r=#{@apptmp}/sample_project", :apps => "app") }
      assert_match_in_file(/SampleProject::App\.tap \{ \|app\|  \}/, "#{@apptmp}/sample_project/features/support/env.rb")
    end

    it 'should generate component in specified app' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:app, 'compo', "-r=#{@apptmp}/sample_project") }
      out, err = capture_io { generate_with_parts(:component, '--test=cucumber', "--app=compo", "-r=#{@apptmp}/sample_project", :apps => "compo") }
      assert_match_in_file(/SampleProject::Compo\.tap \{ \|app\|  \}/, "#{@apptmp}/sample_project/features/support/env.rb")
    end

    it 'should not generate component in specified app if the app does not exist' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      out, err = capture_io { generate_with_parts(:component, '--test=cucumber', "--app=compo", "-r=#{@apptmp}/sample_project", :apps => "compo") }
      assert_match(/SampleProject::Compo does not exist./, out)
      assert_no_file_exists("#{@apptmp}/sample_project/features")
    end
  end

  describe "specified of same the component" do
    it 'should does not change' do
      capture_io { generate(:project, 'sample_project', '--script=jquery', "--root=#{@apptmp}") }
      components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
      assert_equal 'jquery', components_chosen[:script]
      out, err = capture_io { generate(:component, '--script=jquery', "-r=#{@apptmp}/sample_project") }
      assert_match(/applying.*?jquery.*?script/, out)
      refute_match(/Switch renderer to/, out)
      components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
      assert_equal 'jquery', components_chosen[:script]
    end
  end

  describe "component changes" do
    it 'should when allow changes, will be applied' do
      capture_io { generate(:project, 'sample_project', '--renderer=slim', "--root=#{@apptmp}") }
      components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
      assert_equal 'slim', components_chosen[:renderer]
      Readline.stubs(:readline).returns('yes').once
      out, err = capture_io { generate(:component, '--renderer=haml', "-r=#{@apptmp}/sample_project") }
      assert_match(/applying.*?haml.*?renderer/, out)
      components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
      assert_equal 'haml', components_chosen[:renderer]
    end

    it 'should when deny changes, will not be applied' do
      capture_io { generate(:project, 'sample_project', '--renderer=slim', "--root=#{@apptmp}") }
      components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
      assert_equal 'slim', components_chosen[:renderer]
      Readline.stubs(:readline).returns('no').once
      out, err = capture_io { generate(:component, '--renderer=haml', "-r=#{@apptmp}/sample_project") }
      refute_match(/applying.*?haml.*?renderer/, out)
      components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
      assert_equal 'slim', components_chosen[:renderer]
    end
  end
end
