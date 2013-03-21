require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "MailerGenerator" do
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{UUID.new.generate}"
    `mkdir -p #{@apptmp}`
  end

  def teardown
    `rm -rf #{@apptmp}`
  end

  context 'the mailer generator' do
    should "fail outside app root" do
      out, err = capture_io { generate(:mailer, 'demo', "-r=#{@apptmp}") }
      assert_match(/not at the root/, out)
      assert_no_file_exists('/tmp/app/mailers/demo_mailer.rb')
    end

    should "generate mailer in specified app" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:mailer, 'demo', '-a=/subby', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/SampleProject::Subby.mailer :demo/m, "#{@apptmp}/sample_project/subby/mailers/demo.rb")
      assert_dir_exists("#{@apptmp}/sample_project/subby/views/mailers/demo")
    end

    should "generate mailer in specified app with actions" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:mailer, 'demo', 'action1', 'action2', '-a=/subby', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/SampleProject::Subby.mailer :demo/m, "#{@apptmp}/sample_project/subby/mailers/demo.rb")
      assert_match_in_file(/email :action1 do.*?end/m, "#{@apptmp}/sample_project/subby/mailers/demo.rb")
      assert_match_in_file(/email :action2 do.*?end/m, "#{@apptmp}/sample_project/subby/mailers/demo.rb")
      assert_dir_exists("#{@apptmp}/sample_project/subby/views/mailers/demo")
    end

    should "support generating a new mailer extended from base" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:mailer, 'demo', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/SampleProject::App.mailer :demo/m, "#{@apptmp}/sample_project/app/mailers/demo.rb")
      assert_dir_exists("#{@apptmp}/sample_project/app/views/mailers/demo")
    end

    should "support generating a new mailer extended from base with long name" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:mailer, 'UserNotice', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/SampleProject::App.mailer :user_notice/m, "#{@apptmp}/sample_project/app/mailers/user_notice.rb")
      assert_dir_exists("#{@apptmp}/sample_project/app/views/mailers/user_notice")
    end

    should "support generating a new mailer extended from base with capitalized name" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:mailer, 'DEMO', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/SampleProject::App.mailer :demo/m, "#{@apptmp}/sample_project/app/mailers/demo.rb")
      assert_dir_exists("#{@apptmp}/sample_project/app/views/mailers/demo")
    end
  end

  context "the mailer destroy option" do
    should "destroy mailer file" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:mailer, 'demo', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:mailer, 'demo', "-r=#{@apptmp}/sample_project",'-d') }
      assert_no_dir_exists("#{@apptmp}/sample_project/app/views/demo")
      assert_no_file_exists("#{@apptmp}/sample_project/app/mailers/demo.rb")
    end
  end
end
