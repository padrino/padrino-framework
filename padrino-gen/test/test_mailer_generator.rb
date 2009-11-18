require File.dirname(__FILE__) + '/helper'
require 'thor'

class TestMailerGenerator < Test::Unit::TestCase
  def setup
    @skeleton = Padrino::Generators::Skeleton.dup
    @mailgen = Padrino::Generators::Mailer.dup
    `rm -rf /tmp/sample_app`
  end
  
  context 'the mailer generator' do
    should "fail outside app root" do
      output = silence_logger { @mailgen.start(['demo', '-r=/tmp']) }
      assert_match(/not at the root/, output)
      assert !File.exist?('/tmp/app/mailers/demo_mailer.rb')
    end
    
    should "support generating a new mailer extended from base" do
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=bacon']) }
      silence_logger { @mailgen.start(['demo', '-r=/tmp/sample_app']) }
      assert_match_in_file(/class DemoMailer < Padrino::Mailer::Base/m, '/tmp/sample_app/app/mailers/demo_mailer.rb')
      assert_match_in_file(/Padrino::Mailer::Base.smtp_settings/m, '/tmp/sample_app/config/initializers/mailer.rb')
    end
    
    should "support generating a new mailer extended from base with long name" do
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=bacon']) }
      silence_logger { @mailgen.start(['user_notice', '-r=/tmp/sample_app']) }
      assert_match_in_file(/class UserNoticeMailer/m, '/tmp/sample_app/app/mailers/user_notice_mailer.rb')
      assert_match_in_file(/Padrino::Mailer::Base.smtp_settings/m, '/tmp/sample_app/config/initializers/mailer.rb')
    end
    
    should "support generating a new mailer extended from base with capitalized name" do
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=bacon']) }
      silence_logger { @mailgen.start(['DEMO', '-r=/tmp/sample_app']) }
      assert_match_in_file(/class DemoMailer < Padrino::Mailer::Base/m, '/tmp/sample_app/app/mailers/demo_mailer.rb')
      assert_match_in_file(/Padrino::Mailer::Base.smtp_settings/m, '/tmp/sample_app/config/initializers/mailer.rb')
    end
  end
  
end