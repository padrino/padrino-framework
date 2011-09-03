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
      output = silence_logger { generate(:mailer, 'demo', "-r=#{@apptmp}") }
      assert_match(/not at the root/, output)
      assert_no_file_exists('/tmp/app/mailers/demo_mailer.rb')
    end

    should "generate mailer in specified app" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      silence_logger { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      silence_logger { generate(:mailer, 'demo', '-a=/subby', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/Subby.mailer :demo/m, "#{@apptmp}/sample_project/subby/mailers/demo.rb")
      assert_dir_exists("#{@apptmp}/sample_project/subby/views/mailers/demo")
    end

    should "generate mailer in specified app with actions" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      silence_logger { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      silence_logger { generate(:mailer, 'demo', 'action1', 'action2', '-a=/subby', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/Subby.mailer :demo/m, "#{@apptmp}/sample_project/subby/mailers/demo.rb")
      assert_match_in_file(/email :action1 do.*?end/m, "#{@apptmp}/sample_project/subby/mailers/demo.rb")
      assert_match_in_file(/email :action2 do.*?end/m, "#{@apptmp}/sample_project/subby/mailers/demo.rb")
      assert_dir_exists("#{@apptmp}/sample_project/subby/views/mailers/demo")
    end

    should "support generating a new mailer extended from base" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      silence_logger { generate(:mailer, 'demo', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/SampleProject.mailer :demo/m, "#{@apptmp}/sample_project/app/mailers/demo.rb")
      assert_dir_exists("#{@apptmp}/sample_project/app/views/mailers/demo")
    end

    should "support generating a new mailer extended from base with long name" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      silence_logger { generate(:mailer, 'UserNotice', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/SampleProject.mailer :user_notice/m, "#{@apptmp}/sample_project/app/mailers/user_notice.rb")
      assert_dir_exists("#{@apptmp}/sample_project/app/views/mailers/user_notice")
    end

    should "support generating a new mailer extended from base with capitalized name" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      silence_logger { generate(:mailer, 'DEMO', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/SampleProject.mailer :demo/m, "#{@apptmp}/sample_project/app/mailers/demo.rb")
      assert_dir_exists("#{@apptmp}/sample_project/app/views/mailers/demo")
    end
  end

  context "the mailer destroy option" do
    should "destroy mailer file" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      silence_logger { generate(:mailer, 'demo', "-r=#{@apptmp}/sample_project") }
      silence_logger { generate(:mailer, 'demo', "-r=#{@apptmp}/sample_project",'-d') }
      assert_no_dir_exists("#{@apptmp}/sample_project/app/views/demo")
      assert_no_file_exists("#{@apptmp}/sample_project/app/mailers/demo.rb")
    end
  end
end
