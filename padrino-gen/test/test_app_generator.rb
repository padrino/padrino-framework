require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestAppGenerator < Test::Unit::TestCase
  def setup
    `rm -rf /tmp/sample_project`
  end

  context 'the app generator' do
    should "fail outside app root" do
      output = silence_logger { generate(:app, 'demo_root', '-r=/tmp') }
      assert_match(/not at the root/, output)
      assert_no_file_exists('/tmp/demo_root')
    end

    should "create correctly a new padrino application" do
      assert_nothing_raised { silence_logger { generate(:project, 'sample_project', '--root=/tmp') } }
      assert_nothing_raised { silence_logger { generate(:app, 'demo', '--root=/tmp/sample_project') } }
      assert_file_exists('/tmp/sample_project')
      assert_file_exists('/tmp/sample_project/demo')
      assert_file_exists('/tmp/sample_project/demo/app.rb')
      assert_file_exists('/tmp/sample_project/demo/controllers')
      assert_file_exists('/tmp/sample_project/demo/helpers')
      assert_file_exists('/tmp/sample_project/demo/views')
      assert_file_exists('/tmp/sample_project/demo/views/layouts')
      assert_dir_exists('/tmp/sample_project/public/demo')
      assert_match_in_file 'Padrino.mount("Demo").to("/demo")', '/tmp/sample_project/config/apps.rb'
      assert_match_in_file 'class Demo < Padrino::Application', '/tmp/sample_project/demo/app.rb'
    end

    should "generate tiny app skeleton" do
      assert_nothing_raised { silence_logger { generate(:project, 'sample_project', '--root=/tmp') } }
      assert_nothing_raised { silence_logger { generate(:app,'demo','--tiny','--root=/tmp/sample_project') } }
      assert_file_exists('/tmp/sample_project')
      assert_file_exists('/tmp/sample_project/demo')
      assert_file_exists('/tmp/sample_project/demo/helpers.rb')
      assert_file_exists('/tmp/sample_project/demo/controllers.rb')
      assert_file_exists('/tmp/sample_project/demo/mailers.rb')
      assert_dir_exists('/tmp/sample_project/demo/views/mailers')
      assert_dir_exists('/tmp/sample_project/public/demo')
      assert_match_in_file(/:notifier/,'/tmp/sample_project/demo/mailers.rb')
      assert_no_file_exists('/tmp/sample_project/demo/helpers')
      assert_no_file_exists('/tmp/sample_project/demo/controllers')
    end

    should "correctly create a new controller inside a padrino application" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp') }
      silence_logger { generate(:app, 'demo', '--root=/tmp/sample_project') }
      silence_logger { generate(:controller, 'demo_items', '-r=/tmp/sample_project', '-a=demo') }
      assert_match_in_file(/Demo.controllers :demo_items do/m, '/tmp/sample_project/demo/controllers/demo_items.rb')
      assert_match_in_file(/Demo.helpers do/m, '/tmp/sample_project/demo/helpers/demo_items_helper.rb')
      assert_file_exists('/tmp/sample_project/demo/views/demo_items')
    end

    should "correctly create a new mailer inside a padrino application" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon') }
      silence_logger { generate(:app, 'demo_app', '--root=/tmp/sample_project') }
      silence_logger { generate(:mailer, 'demo', '-r=/tmp/sample_project', '-a=demo_app') }
      assert_match_in_file(/DemoApp.mailer :demo/m, '/tmp/sample_project/demo_app/mailers/demo.rb')
      assert_dir_exists('/tmp/sample_project/demo_app/views/mailers/demo')
    end
  end
end
