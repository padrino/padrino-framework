require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestAppGenerator < Test::Unit::TestCase
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{UUID.new.generate}"
    `mkdir -p #{@apptmp}`
  end

  def teardown
    `rm -rf #{@apptmp}`
  end

  context 'the app generator' do
    should "fail outside app root" do
      output = silence_logger { generate(:app, 'demo_root', "-r=#{@apptmp}") }
      assert_match(/not at the root/, output)
      assert_no_file_exists("#{@apptmp}/demo_root")
    end

    should "create correctly a new padrino application" do
      assert_nothing_raised { silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}") } }
      assert_nothing_raised { silence_logger { generate(:app, 'demo', "--root=#{@apptmp}/sample_project") } }
      assert_file_exists("#{@apptmp}/sample_project")
      assert_file_exists("#{@apptmp}/sample_project/demo")
      assert_file_exists("#{@apptmp}/sample_project/demo/app.rb")
      assert_file_exists("#{@apptmp}/sample_project/demo/controllers")
      assert_file_exists("#{@apptmp}/sample_project/demo/helpers")
      assert_file_exists("#{@apptmp}/sample_project/demo/views")
      assert_file_exists("#{@apptmp}/sample_project/demo/views/layouts")
      assert_dir_exists("#{@apptmp}/sample_project/public/demo")
      assert_match_in_file 'Padrino.mount("Demo").to("/demo")', "#{@apptmp}/sample_project/config/apps.rb"
      assert_match_in_file 'class Demo < Padrino::Application', "#{@apptmp}/sample_project/demo/app.rb"
    end

    should "generate tiny app skeleton" do
      assert_nothing_raised { silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}") } }
      assert_nothing_raised { silence_logger { generate(:app, 'demo','--tiny',"--root=#{@apptmp}/sample_project") } }
      assert_file_exists("#{@apptmp}/sample_project")
      assert_file_exists("#{@apptmp}/sample_project/demo")
      assert_file_exists("#{@apptmp}/sample_project/demo/helpers.rb")
      assert_file_exists("#{@apptmp}/sample_project/demo/controllers.rb")
      assert_file_exists("#{@apptmp}/sample_project/demo/mailers.rb")
      assert_dir_exists("#{@apptmp}/sample_project/demo/views/mailers")
      assert_dir_exists("#{@apptmp}/sample_project/public/demo")
      assert_match_in_file(/:notifier/,"#{@apptmp}/sample_project/demo/mailers.rb")
      assert_no_file_exists("#{@apptmp}/sample_project/demo/helpers")
      assert_no_file_exists("#{@apptmp}/sample_project/demo/controllers")
    end

    should "correctly create a new controller inside a padrino application" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      silence_logger { generate(:app, 'demo', "--root=#{@apptmp}/sample_project") }
      silence_logger { generate(:controller, 'demo_items', "-r=#{@apptmp}/sample_project", '-a=demo') }
      assert_match_in_file(/Demo.controllers :demo_items do/m, "#{@apptmp}/sample_project/demo/controllers/demo_items.rb")
      assert_match_in_file(/Demo.helpers do/m, "#{@apptmp}/sample_project/demo/helpers/demo_items_helper.rb")
      assert_file_exists("#{@apptmp}/sample_project/demo/views/demo_items")
    end

    should "correctly create a new mailer inside a padrino application" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      silence_logger { generate(:app, 'demo_app', "--root=#{@apptmp}/sample_project") }
      silence_logger { generate(:mailer, 'demo', "-r=#{@apptmp}/sample_project", '-a=demo_app') }
      assert_match_in_file(/DemoApp.mailer :demo/m, "#{@apptmp}/sample_project/demo_app/mailers/demo.rb")
      assert_dir_exists("#{@apptmp}/sample_project/demo_app/views/mailers/demo")
    end

    # only destroys what it generated.
    # hence, the folder will still exists if other changes were made to it.
    should "destroys itself" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      silence_logger { generate(:app, 'demo', "--root=#{@apptmp}/sample_project") }
      output = silence_logger { generate(:app, 'demo', "--root=#{@apptmp}/sample_project", '-d') }
      assert_no_match(/has been mounted/, output)
      assert_no_dir_exists("#{@apptmp}/sample_project/public/demo")
      assert_no_file_exists("#{@apptmp}/sample_project/demo/app.rb")
      assert_no_dir_exists("#{@apptmp}/sample_project/demo/controllers")
      assert_no_dir_exists("#{@apptmp}/sample_project/demo/helpers")
      assert_no_dir_exists("#{@apptmp}/sample_project/demo/views")
      assert_no_match_in_file(/Padrino\.mount\("Demo"\).to\("\/demo"\)/,"#{@apptmp}/sample_project/config/apps.rb")
    end
  end
end
