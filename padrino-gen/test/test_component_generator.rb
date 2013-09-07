require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "ComponentGenerator" do
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{UUID.new.generate}"
    `mkdir -p #{@apptmp}`
  end

  def teardown
    `rm -rf #{@apptmp}`
  end

  context 'the controller generator' do
    should "fail outside app root" do
      out, err = capture_io { generate(:component, 'demo', "-r=#{@apptmp}") }
      assert_match(/not at the root/, out)
    end
  end


  context "add components" do
    should "properly generate default" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      out, err = capture_io { generate(:component, '--orm=activerecord', "-r=#{@apptmp}/sample_project") }
      assert_match(/applying.*?activerecord.*?orm/, out)
      assert_match_in_file(/gem 'activerecord', '>= 3.1', :require => 'active_record'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'sqlite3'/, "#{@apptmp}/sample_project/Gemfile")
      assert_no_match(/Switch renderer to/, out)
      components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
      assert_equal 'activerecord', components_chosen[:orm]
    end

    should "properly generate with adapter" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      out, err = capture_io { generate(:component, '--orm=sequel', '--adapter=postgres', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/gem 'pg'/, "#{@apptmp}/sample_project/Gemfile")
      assert_no_match(/Switch renderer to/, out)
      components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
      assert_equal 'sequel', components_chosen[:orm]
    end
  end


  context "specified of same the component" do
    should "does not change" do
      capture_io { generate(:project, 'sample_project', '--script=jquery', "--root=#{@apptmp}") }
      components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
      assert_equal 'jquery', components_chosen[:script]
      out, err = capture_io { generate(:component, '--script=jquery', "-r=#{@apptmp}/sample_project") }
      assert_match(/applying.*?jquery.*?script/, out)
      assert_no_match(/Switch renderer to/, out)
      components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
      assert_equal 'jquery', components_chosen[:script]
    end
  end


  context "component changes" do
    should "when allow changes, will be applied" do
      capture_io { generate(:project, 'sample_project', '-renderer=slim', "--root=#{@apptmp}") }
      components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
      assert_equal 'slim', components_chosen[:renderer]
      $stdin.stub(:gets, 'yes') do
        out, err = capture_io { generate(:component, '--renderer=haml', "-r=#{@apptmp}/sample_project") }
        assert_match(/applying.*?haml.*?renderer/, out)
        assert_match(/Switch renderer to/, out)
        components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
        assert_equal 'haml', components_chosen[:renderer]
      end
    end
    should "when deny changes, will not be applied" do
      capture_io { generate(:project, 'sample_project', '-renderer=slim', "--root=#{@apptmp}") }
      components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
      assert_equal 'slim', components_chosen[:renderer]
      $stdin.stub(:gets, 'no') do
        out, err = capture_io { generate(:component, '--renderer=haml', "-r=#{@apptmp}/sample_project") }
        assert_no_match(/applying.*?haml.*?renderer/, out)
        assert_match(/Switch renderer to/, out)
        components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
        assert_equal 'slim', components_chosen[:renderer]
      end
    end
  end

end
