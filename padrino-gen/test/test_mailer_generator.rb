require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestMailerGenerator < Test::Unit::TestCase
  def setup
    `rm -rf /tmp/sample_project`
  end

  context 'the mailer generator' do
    should "fail outside app root" do
      output = silence_logger { generate(:mailer, 'demo', '-r=/tmp') }
      assert_match(/not at the root/, output)
      assert_no_file_exists('/tmp/app/mailers/demo_mailer.rb')
    end

    should "support generating a new mailer extended from base" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon') }
      silence_logger { generate(:mailer, 'demo', '-r=/tmp/sample_project') }
      assert_match_in_file(/SampleProject.mailer :demo/m, '/tmp/sample_project/app/mailers/demo.rb')
      assert_dir_exists('/tmp/sample_project/app/views/mailers/demo')
    end

    should "support generating a new mailer extended from base with long name" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon') }
      silence_logger { generate(:mailer, 'UserNotice', '-r=/tmp/sample_project') }
      assert_match_in_file(/SampleProject.mailer :user_notice/m, '/tmp/sample_project/app/mailers/user_notice.rb')
      assert_dir_exists('/tmp/sample_project/app/views/mailers/user_notice')
    end

    should "support generating a new mailer extended from base with capitalized name" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon') }
      silence_logger { generate(:mailer, 'DEMO', '-r=/tmp/sample_project') }
      assert_match_in_file(/SampleProject.mailer :demo/m, '/tmp/sample_project/app/mailers/demo.rb')
      assert_dir_exists('/tmp/sample_project/app/views/mailers/demo')
    end
  end

  context "the mailer destroy option" do
    should "destroy mailer file" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon') }
      silence_logger { generate(:mailer, 'demo', '-r=/tmp/sample_project') }
      silence_logger { generate(:mailer, 'demo', '-r=/tmp/sample_project','-d') }
      assert_no_dir_exists('/tmp/sample_project/app/views/demo')
      assert_no_file_exists('/tmp/sample_project/app/mailers/demo.rb')
    end
  end
end