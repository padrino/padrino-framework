require File.dirname(__FILE__) + '/helper'
require 'thor/group'
require 'fakeweb'

class TestAppGenerator < Test::Unit::TestCase
  def setup
    FakeWeb.allow_net_connect = false
    `rm -rf /tmp/sample_project`
    @project = Padrino::Generators::Project.dup
    @app     = Padrino::Generators::App.dup
    @cont_gen = Padrino::Generators::Controller.dup
    @mail_gen = Padrino::Generators::Mailer.dup
  end

  context 'the app generator' do
    should "fail outside app root" do
      output = silence_logger { @app.start(['demo', '-r=/tmp']) }
      assert_match(/not at the root/, output)
      assert_no_file_exists('/tmp/demo')
    end

    should "create correctly a new padrino application" do
      assert_nothing_raised { silence_logger { @project.start(['sample_project', '--root=/tmp']) } }
      assert_nothing_raised { silence_logger { @app.start(['demo', '--root=/tmp/sample_project']) } }
      assert_file_exists('/tmp/sample_project')
      assert_file_exists('/tmp/sample_project/demo')
      assert_file_exists('/tmp/sample_project/demo/app.rb')
      assert_file_exists('/tmp/sample_project/demo/controllers')
      assert_file_exists('/tmp/sample_project/demo/helpers')
      assert_file_exists('/tmp/sample_project/demo/views')
      assert_match_in_file 'Padrino.mount("Demo").to("/demo")', '/tmp/sample_project/config/apps.rb'
      assert_match_in_file 'class Demo < Padrino::Application', '/tmp/sample_project/demo/app.rb'
    end

    should "correctly create a new controller inside a padrino application" do
      silence_logger { @project.start(['sample_project', '--root=/tmp']) }
      silence_logger { @app.start(['demo', '--root=/tmp/sample_project']) }
      silence_logger { @cont_gen.start(['demo_items', '-r=/tmp/sample_project', '-a=demo']) }
      assert_match_in_file(/Demo.controllers :demo_items do/m, '/tmp/sample_project/demo/controllers/demo_items.rb')
      assert_match_in_file(/Demo.helpers do/m, '/tmp/sample_project/demo/helpers/demo_items_helper.rb')
      assert_file_exists('/tmp/sample_project/demo/views/demo_items')
    end

    should "correctly create a new mailer inside a padrino application" do
      silence_logger { @project.start(['sample_project', '--root=/tmp', '--script=none', '-t=bacon']) }
      silence_logger { @app.start(['demo', '--root=/tmp/sample_project']) }
      silence_logger { @mail_gen.start(['demo', '-r=/tmp/sample_project', '-a=demo']) }
      assert_match_in_file(/class DemoMailer < Padrino::Mailer::Base/m, '/tmp/sample_project/demo/mailers/demo_mailer.rb')
      assert_match_in_file(/Padrino::Mailer::Base.smtp_settings/m, '/tmp/sample_project/lib/mailer.rb')
      assert_file_exists('/tmp/sample_project/demo/views/demo_mailer')
    end

  end
end
