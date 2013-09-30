require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "TaskGenerator" do
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{UUID.new.generate}"
    `mkdir -p #{@apptmp}`
  end

  def teardown
    `rm -rf #{@apptmp}`
  end

  context 'the task generator' do
    should "fail outside app root" do
      out, err = capture_io { generate(:task, 'foo', "-r=#{@apptmp}") }
      assert_match(/not at the root/, out)
      assert_no_file_exists('/tmp/tasks/foo.rake')
    end

    should "generate filename properly" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:task, 'DemoTask', "--namespace=Sample", "--description='This is a sample'", "-r=#{@apptmp}/sample_project") }
      assert_file_exists("#{@apptmp}/sample_project/tasks/sample_demo_task.rake")
    end

    should "generate task file with description" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:task, 'foo', "--description=This is a sample", "-r=#{@apptmp}/sample_project") }
      file_path = "#{@apptmp}/sample_project/tasks/foo.rake"
      assert_no_match_in_file(/namespace/, file_path)
      assert_match_in_file(/desc "This is a sample"/, file_path)
      assert_match_in_file(/task :foo => :environment do/, file_path)
    end

    should "generate task file with namespace" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:task, 'foo', "--namespace=Sample", "-r=#{@apptmp}/sample_project") }
      file_path = "#{@apptmp}/sample_project/tasks/sample_foo.rake"
      assert_match_in_file(/namespace :sample do/, file_path)
      assert_match_in_file(/task :foo => :environment do/, file_path)
      assert_no_match_in_file(/desc/, file_path)
    end

    should "generate task file with snake case name when using camelized name" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:task, 'DemoTask', "--namespace=Sample", "--description=This is a sample", "-r=#{@apptmp}/sample_project") }
      file_path = "#{@apptmp}/sample_project/tasks/sample_demo_task.rake"
      assert_match_in_file(/namespace :sample do/, file_path)
      assert_match_in_file(/desc "This is a sample"/, file_path)
      assert_match_in_file(/task :demo_task => :environment do/, file_path)
    end
  end
end
