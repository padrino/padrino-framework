require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "AppGenerator" do
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{UUID.new.generate}"
    `mkdir -p #{@apptmp}`
  end

  def teardown
    `rm -rf #{@apptmp}`
  end

  context 'the app generator' do
    should "fail outside app root" do
      out, err = capture_io { generate(:app, 'demo_root', "-r=#{@apptmp}") }
      assert_match(/not at the root/, out)
      assert_no_file_exists("#{@apptmp}/demo_root")
    end

    should "create correctly a new padrino application" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:app, 'demo', "--root=#{@apptmp}/sample_project") }
      assert_file_exists("#{@apptmp}/sample_project")
      assert_file_exists("#{@apptmp}/sample_project/demo")
      assert_file_exists("#{@apptmp}/sample_project/demo/app.rb")
      assert_file_exists("#{@apptmp}/sample_project/demo/controllers")
      assert_file_exists("#{@apptmp}/sample_project/demo/helpers")
      assert_file_exists("#{@apptmp}/sample_project/demo/views")
      assert_file_exists("#{@apptmp}/sample_project/demo/views/layouts")
      assert_dir_exists("#{@apptmp}/sample_project/public/demo")
      assert_match_in_file('Padrino.mount("Demo").to("/demo")', "#{@apptmp}/sample_project/config/apps.rb")
      assert_match_in_file('class Demo < Padrino::Application', "#{@apptmp}/sample_project/demo/app.rb")
      assert_match_in_file(/Padrino.configure_apps do/, "#{@apptmp}/sample_project/config/apps.rb")
      assert_match_in_file(/set :session_secret, '[0-9A-z]*'/, "#{@apptmp}/sample_project/config/apps.rb")
    end

    should "generate tiny app skeleton" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:app, 'demo','--tiny',"--root=#{@apptmp}/sample_project") }
      assert_file_exists("#{@apptmp}/sample_project")
      assert_file_exists("#{@apptmp}/sample_project/demo")
      assert_file_exists("#{@apptmp}/sample_project/demo/helpers.rb")
      assert_file_exists("#{@apptmp}/sample_project/demo/controllers.rb")
      assert_file_exists("#{@apptmp}/sample_project/demo/mailers.rb")
      assert_dir_exists("#{@apptmp}/sample_project/public/demo")
      assert_match_in_file(/:notifier/,"#{@apptmp}/sample_project/demo/mailers.rb")
      assert_no_file_exists("#{@apptmp}/sample_project/demo/helpers")
      assert_no_file_exists("#{@apptmp}/sample_project/demo/controllers")
    end

    should "correctly create a new controller inside a padrino application" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:app, 'demo', "--root=#{@apptmp}/sample_project") }
      capture_io { generate(:controller, 'demo_items', "-r=#{@apptmp}/sample_project", '-a=demo') }
      assert_match_in_file(/Demo.controllers :demo_items do/m, "#{@apptmp}/sample_project/demo/controllers/demo_items.rb")
      assert_match_in_file(/Demo.helpers do/m, "#{@apptmp}/sample_project/demo/helpers/demo_items_helper.rb")
      assert_file_exists("#{@apptmp}/sample_project/demo/views/demo_items")
    end

    should "correctly create a new mailer inside a padrino application" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:app, 'demo_app', "--root=#{@apptmp}/sample_project") }
      capture_io { generate(:mailer, 'demo', "-r=#{@apptmp}/sample_project", '-a=demoapp') }
    end

    # only destroys what it generated.
    # hence, the folder will still exists if other changes were made to it.
    should "destroys itself" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:app, 'demo', "--root=#{@apptmp}/sample_project") }
      out, err = capture_io { generate(:app, 'demo', "--root=#{@apptmp}/sample_project", '-d') }
      assert_no_match(/has been mounted/, out)
      assert_no_dir_exists("#{@apptmp}/sample_project/public/demo")
      assert_no_file_exists("#{@apptmp}/sample_project/demo/app.rb")
      assert_no_dir_exists("#{@apptmp}/sample_project/demo/controllers")
      assert_no_dir_exists("#{@apptmp}/sample_project/demo/helpers")
      assert_no_dir_exists("#{@apptmp}/sample_project/demo/views")
      assert_no_match_in_file(/Padrino\.mount\("Demo"\).to\("\/demo"\)/,"#{@apptmp}/sample_project/config/apps.rb")
    end
  end
end
