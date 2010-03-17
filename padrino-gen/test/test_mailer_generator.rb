require File.dirname(__FILE__) + '/helper'
require 'thor/group'

class TestMailerGenerator < Test::Unit::TestCase
  def setup
    @project = Padrino::Generators::Project.dup
    @mail_gen = Padrino::Generators::Mailer.dup
    `rm -rf /tmp/sample_project`
  end

  context 'the mailer generator' do
    should "fail outside app root" do
      output = silence_logger { @mail_gen.start(['demo', '-r=/tmp']) }
      assert_match(/not at the root/, output)
      assert_no_file_exists('/tmp/app/mailers/demo_mailer.rb')
    end

    should "support generating a new mailer extended from base" do
      silence_logger { @project.start(['sample_project', '--root=/tmp', '--script=none', '-t=bacon']) }
      silence_logger { @mail_gen.start(['demo', '-r=/tmp/sample_project']) }
      assert_match_in_file(/class DemoMailer < Padrino::Mailer::Base/m, '/tmp/sample_project/app/mailers/demo_mailer.rb')
      assert_match_in_file(/Padrino::Mailer::Base.smtp_settings/m, '/tmp/sample_project/lib/mailer.rb')
      assert_match_in_file(/register MailerInitializer/m, '/tmp/sample_project/app/app.rb')
      assert_file_exists('/tmp/sample_project/app/views/demo_mailer')
    end

    should "support generating a new mailer extended from base with long name" do
      silence_logger { @project.start(['sample_project', '--root=/tmp', '--script=none', '-t=bacon']) }
      silence_logger { @mail_gen.start(['user_notice', '-r=/tmp/sample_project']) }
      assert_match_in_file(/class UserNoticeMailer/m, '/tmp/sample_project/app/mailers/user_notice_mailer.rb')
      assert_match_in_file(/Padrino::Mailer::Base.smtp_settings/m, '/tmp/sample_project/lib/mailer.rb')
      assert_file_exists('/tmp/sample_project/app/views/user_notice_mailer')
    end

    should "support generating a new mailer extended from base with capitalized name" do
      silence_logger { @project.start(['sample_project', '--root=/tmp', '--script=none', '-t=bacon']) }
      silence_logger { @mail_gen.start(['DEMO', '-r=/tmp/sample_project']) }
      assert_match_in_file(/class DemoMailer < Padrino::Mailer::Base/m, '/tmp/sample_project/app/mailers/demo_mailer.rb')
      assert_match_in_file(/Padrino::Mailer::Base.smtp_settings/m, '/tmp/sample_project/lib/mailer.rb')
      assert_file_exists('/tmp/sample_project/app/views/demo_mailer')
    end

  end

  context "the mailer destroy option" do
    
    should "destroy mailer file" do
      silence_logger { @project.start(['sample_project', '--root=/tmp', '--script=none', '-t=bacon']) }
      silence_logger { @mail_gen.start(['demo', '-r=/tmp/sample_project']) }
      silence_logger { @mail_gen.start(['demo', '-r=/tmp/sample_project','-d']) }
      assert_no_dir_exists('/tmp/sample_project/app/views/demo_mailer')
      assert_no_file_exists('/tmp/sample_project/app/mailers/demo_mailer.rb')
      assert_no_file_exists('/tmp/sample_project/lib/mailer.rb')
    end
  end

end
