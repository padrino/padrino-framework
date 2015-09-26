require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "AppGenerator" do
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{SecureRandom.hex}"
    `mkdir -p #{@apptmp}`
  end

  def teardown
    `rm -rf #{@apptmp}`
  end

  describe 'the app generator' do
    it 'should fail outside app root' do
      out, err = capture_io { generate(:app, 'demo_root', "-r=#{@apptmp}") }
      assert_match(/not at the root/, out)
      assert_no_file_exists("#{@apptmp}/demo_root")
    end

    it 'should create correctly a new padrino application' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:app, 'demo', "--root=#{@apptmp}/sample_project") }
      assert_dir_exists("#{@apptmp}/sample_project")
      assert_dir_exists("#{@apptmp}/sample_project/demo")
      assert_file_exists("#{@apptmp}/sample_project/demo/app.rb")
      assert_dir_exists("#{@apptmp}/sample_project/demo/controllers")
      assert_dir_exists("#{@apptmp}/sample_project/demo/helpers")
      assert_dir_exists("#{@apptmp}/sample_project/demo/views")
      assert_dir_exists("#{@apptmp}/sample_project/demo/views/layouts")
      assert_dir_exists("#{@apptmp}/sample_project/public/demo")
      assert_match_in_file("Padrino.mount('SampleProject::Demo', :app_file => Padrino.root('demo/app.rb')).to('/demo')", "#{@apptmp}/sample_project/config/apps.rb")
      assert_match_in_file('module SampleProject', "#{@apptmp}/sample_project/demo/app.rb")
      assert_match_in_file('class Demo < Padrino::Application', "#{@apptmp}/sample_project/demo/app.rb")
      assert_match_in_file(/Padrino.configure_apps do/, "#{@apptmp}/sample_project/config/apps.rb")
      assert_match_in_file(/set :session_secret, '[0-9A-z]*'/, "#{@apptmp}/sample_project/config/apps.rb")
    end

    it 'should create correctly a new padrino application with an underscore name' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:app, 'demo_app', "--root=#{@apptmp}/sample_project") }
      assert_dir_exists("#{@apptmp}/sample_project")
      assert_dir_exists("#{@apptmp}/sample_project/demo_app")
      assert_file_exists("#{@apptmp}/sample_project/demo_app/app.rb")
      assert_dir_exists("#{@apptmp}/sample_project/demo_app/controllers")
      assert_dir_exists("#{@apptmp}/sample_project/demo_app/helpers")
      assert_dir_exists("#{@apptmp}/sample_project/demo_app/views")
      assert_dir_exists("#{@apptmp}/sample_project/demo_app/views/layouts")
      assert_dir_exists("#{@apptmp}/sample_project/public/demo_app")
      assert_match_in_file("Padrino.mount('SampleProject::DemoApp', :app_file => Padrino.root('demo_app/app.rb')).to('/demo_app')", "#{@apptmp}/sample_project/config/apps.rb")
      assert_match_in_file('module SampleProject', "#{@apptmp}/sample_project/demo_app/app.rb")
      assert_match_in_file('class DemoApp < Padrino::Application', "#{@apptmp}/sample_project/demo_app/app.rb")
      assert_match_in_file(/Padrino.configure_apps do/, "#{@apptmp}/sample_project/config/apps.rb")
      assert_match_in_file(/set :session_secret, '[0-9A-z]*'/, "#{@apptmp}/sample_project/config/apps.rb")
    end

    it 'should generate tiny app skeleton' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:app, 'demo','--tiny',"--root=#{@apptmp}/sample_project") }
      assert_dir_exists("#{@apptmp}/sample_project")
      assert_dir_exists("#{@apptmp}/sample_project/demo")
      assert_file_exists("#{@apptmp}/sample_project/demo/helpers.rb")
      assert_file_exists("#{@apptmp}/sample_project/demo/controllers.rb")
      assert_file_exists("#{@apptmp}/sample_project/demo/mailers.rb")
      assert_dir_exists("#{@apptmp}/sample_project/public/demo")
      assert_match_in_file(/:notifier/,"#{@apptmp}/sample_project/demo/mailers.rb")
      assert_match_in_file(/module Helper/, "#{@apptmp}/sample_project/demo/helpers.rb")
      assert_match_in_file(/helpers Helper/, "#{@apptmp}/sample_project/demo/helpers.rb")
      assert_no_file_exists("#{@apptmp}/sample_project/demo/helpers")
      assert_no_file_exists("#{@apptmp}/sample_project/demo/controllers")
    end

    it 'should correctly create a new controller inside a padrino application' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:app, 'demo', "--root=#{@apptmp}/sample_project") }
      capture_io { generate(:controller, 'demo_items', "-r=#{@apptmp}/sample_project", '-a=demo') }
      assert_match_in_file(/SampleProject::Demo.controllers :demo_items do/m, "#{@apptmp}/sample_project/demo/controllers/demo_items.rb")
      assert_match_in_file(/helpers DemoItemsHelper/m, "#{@apptmp}/sample_project/demo/helpers/demo_items_helper.rb")
      assert_dir_exists("#{@apptmp}/sample_project/demo/views/demo_items")
    end

    it 'should correctly create a new mailer inside a padrino application' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:app, 'demo_app', "--root=#{@apptmp}/sample_project") }
      capture_io { generate(:mailer, 'demo', "-r=#{@apptmp}/sample_project", '-a=demo_app') }
    end

    # only destroys what it generated.
    # hence, the folder will still exists if other changes were made to it.
    it 'should destroys itself' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:app, 'demo', "--root=#{@apptmp}/sample_project") }
      out, err = capture_io { generate_with_parts(:app, 'demo', "--root=#{@apptmp}/sample_project", '-d', :apps => "demo") }
      refute_match(/has been mounted/, out)
      assert_no_dir_exists("#{@apptmp}/sample_project/public/demo")
      assert_no_file_exists("#{@apptmp}/sample_project/demo/app.rb")
      assert_no_dir_exists("#{@apptmp}/sample_project/demo/controllers")
      assert_no_dir_exists("#{@apptmp}/sample_project/demo/helpers")
      assert_no_dir_exists("#{@apptmp}/sample_project/demo/views")
      assert_no_match_in_file(/Padrino\.mount\("Demo"\).to\("\/demo"\)/,"#{@apptmp}/sample_project/config/apps.rb")
    end

    it 'should abort if app name already exists' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      out, err = capture_io { generate(:app, 'kernel', "--root=#{@apptmp}/sample_project") }
      assert_match(/Kernel already exists/, out)
      assert_no_dir_exists("#{@apptmp}/sample_project/public/kernel")
      assert_no_dir_exists("#{@apptmp}/sample_project/kernel/controllers")
      assert_no_dir_exists("#{@apptmp}/sample_project/kernel/helpers")
      assert_no_file_exists("#{@apptmp}/sample_project/kernel/app.rb")
    end

    it 'should abort if app name already exists in root' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:app, 'subapp', "--root=#{@apptmp}/sample_project") }
      out, err = capture_io { generate_with_parts(:app, 'subapp', "--root=#{@apptmp}/sample_project", :apps => "subapp") }
      assert_dir_exists("#{@apptmp}/sample_project/public/subapp")
      assert_dir_exists("#{@apptmp}/sample_project/subapp/controllers")
      assert_dir_exists("#{@apptmp}/sample_project/subapp/helpers")
      assert_file_exists("#{@apptmp}/sample_project/subapp/app.rb")
      assert_match(/Subapp already exists/, out)
    end

    it 'should generate app files if :force option is specified' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      out, err = capture_io { generate(:app, 'kernel', "--root=#{@apptmp}/sample_project", "--force") }
      assert_dir_exists("#{@apptmp}/sample_project/public/kernel")
      assert_dir_exists("#{@apptmp}/sample_project/kernel/controllers")
      assert_dir_exists("#{@apptmp}/sample_project/kernel/helpers")
      assert_file_exists("#{@apptmp}/sample_project/kernel/app.rb")
    end

    it 'should allow to pass upcased name as the app name' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      out, err = capture_io { generate(:app, 'API', "--root=#{@apptmp}/sample_project", "--force") }
      assert_dir_exists("#{@apptmp}/sample_project/public/api")
      assert_dir_exists("#{@apptmp}/sample_project/api/controllers")
      assert_dir_exists("#{@apptmp}/sample_project/api/helpers")
      assert_file_exists("#{@apptmp}/sample_project/api/app.rb")
      assert_match_in_file(/class API < Padrino::Application/, "#{@apptmp}/sample_project/api/app.rb")
    end
  end
end
