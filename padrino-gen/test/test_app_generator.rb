require_relative 'helper'
require 'open3'

describe 'AppGenerator' do
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{SecureRandom.hex}"
    `mkdir -p #{@apptmp}`
  end

  def teardown
    `rm -rf #{@apptmp}`
  end

  describe 'the app generator' do
    it 'should fail outside app root' do
      out, = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:app, 'demo_root', "-r=#{@apptmp}") }.status }
      assert_match(/not at the root/, out)
      assert_no_file_exists("#{@apptmp}/demo_root")
    end

    it 'should fail with a message if the app name is not a valid constant' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      _, err = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:app, '4y', "--root=#{@apptmp}/sample_project") }.status }
      assert_match(/4y is not a valid constant name/, err)
      assert_no_dir_exists("#{@apptmp}/sample_project/4y")
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
      assert_match_in_file("Padrino.mount('SampleProject::Demo', app_file: Padrino.root('demo/app.rb')).to('/demo')", "#{@apptmp}/sample_project/config/apps.rb")
      assert_match_in_file('module SampleProject', "#{@apptmp}/sample_project/demo/app.rb")
      assert_match_in_file('class Demo < Padrino::Application', "#{@apptmp}/sample_project/demo/app.rb")
      assert_match_in_file(/Padrino.configure_apps do/, "#{@apptmp}/sample_project/config/apps.rb")
      assert_match_in_file(/^  set :session_secret, ENV\.fetch\('SESSION_SECRET'\) \{ '\h{64}' \}$/, "#{@apptmp}/sample_project/config/apps.rb")
    end

    it 'should set SameSite=Lax and Secure in production on the session cookie' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:app, 'demo', "--root=#{@apptmp}/sample_project") }
      assert_match_in_file(/^    set :sessions, same_site: :lax, secure: Padrino\.env == :production$/, "#{@apptmp}/sample_project/demo/app.rb")
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
      assert_match_in_file("Padrino.mount('SampleProject::DemoApp', app_file: Padrino.root('demo_app/app.rb')).to('/demo_app')", "#{@apptmp}/sample_project/config/apps.rb")
      assert_match_in_file('module SampleProject', "#{@apptmp}/sample_project/demo_app/app.rb")
      assert_match_in_file('class DemoApp < Padrino::Application', "#{@apptmp}/sample_project/demo_app/app.rb")
      assert_match_in_file(/Padrino.configure_apps do/, "#{@apptmp}/sample_project/config/apps.rb")
      assert_match_in_file(/^  set :session_secret, ENV\.fetch\('SESSION_SECRET'\) \{ '\h{64}' \}$/, "#{@apptmp}/sample_project/config/apps.rb")
    end

    it 'should write an app without mailer, helpers, sessions or CSRF in an api project' do
      capture_io { generate(:project, 'sample_project', '--api', "--root=#{@apptmp}") }
      capture_io { generate(:app, 'demo', "--root=#{@apptmp}/sample_project") }
      app_file = "#{@apptmp}/sample_project/demo/app.rb"
      assert_no_match_in_file(/Padrino::(Mailer|Helpers)/, app_file)
      assert_no_match_in_file(/set :sessions/, app_file)
      # An older api project turns CSRF on for every app, so the app settles it itself.
      assert_match_in_file(/^\s*set :protect_from_csrf, proc \{ sessions\? && Padrino\.env != :test \}$/, app_file)
    end

    it 'should write a tiny app without mailers in an api project' do
      capture_io { generate(:project, 'sample_project', '--api', '--lean', "--root=#{@apptmp}") }
      capture_io { generate(:app, 'demo', '--tiny', "--root=#{@apptmp}/sample_project") }
      assert_no_match_in_file(/Padrino::(Mailer|Helpers)/, "#{@apptmp}/sample_project/demo/app.rb")
      assert_no_file_exists("#{@apptmp}/sample_project/demo/mailers.rb")
    end

    it 'should keep mailer, helpers and sessions in a project with the padrino gem' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:app, 'demo', '--tiny', "--root=#{@apptmp}/sample_project") }
      app_file = "#{@apptmp}/sample_project/demo/app.rb"
      assert_match_in_file(/register Padrino::Mailer/, app_file)
      assert_match_in_file(/register Padrino::Helpers/, app_file)
      assert_match_in_file(/set :sessions/, app_file)
      assert_no_match_in_file(/protect_from_csrf/, app_file)
      assert_file_exists("#{@apptmp}/sample_project/demo/mailers.rb")
    end

    it 'should keep the default app in a project without a Gemfile' do
      capture_io { generate(:project, 'sample_project', '--api', "--root=#{@apptmp}") }
      File.delete("#{@apptmp}/sample_project/Gemfile")
      capture_io { generate(:app, 'demo', "--root=#{@apptmp}/sample_project") }
      app_file = "#{@apptmp}/sample_project/demo/app.rb"
      assert_match_in_file(/register Padrino::Mailer/, app_file)
      assert_match_in_file(/register Padrino::Helpers/, app_file)
      assert_match_in_file(/set :sessions/, app_file)
    end

    it 'should keep the default app in a --dev project, whose Gemfile lists padrino in a loop' do
      capture_io { generate(:project, 'sample_project', '--dev', "--root=#{@apptmp}") }
      capture_io { generate(:app, 'demo', '--tiny', "--root=#{@apptmp}/sample_project") }
      app_file = "#{@apptmp}/sample_project/demo/app.rb"
      assert_match_in_file(/register Padrino::Mailer/, app_file)
      assert_match_in_file(/register Padrino::Helpers/, app_file)
      assert_match_in_file(/set :sessions/, app_file)
      assert_file_exists("#{@apptmp}/sample_project/demo/mailers.rb")
    end

    it 'should keep the default app in a project that lists every padrino gem by name' do
      capture_io { generate(:project, 'sample_project', '--api', "--root=#{@apptmp}") }
      File.write("#{@apptmp}/sample_project/Gemfile", "gem 'padrino-helpers'\ngem 'padrino-mailer'\n", mode: 'a')
      capture_io { generate(:app, 'demo', "--root=#{@apptmp}/sample_project") }
      assert_match_in_file(/set :sessions/, "#{@apptmp}/sample_project/demo/app.rb")
    end

    # Boots the generated project in a process that loads only the gems its Gemfile names, as
    # config/boot.rb would. Returns the output, ending in the status of a POST without a token.
    def boot_project(project, *gems, env: 'development', path: '/demo/missing')
      script = <<~RUBY
        PADRINO_ROOT = #{project.inspect}
        RACK_ENV = #{env.inspect}
        require 'padrino-core'
        #{gems.map { |gem| "require '#{gem}'" }.join("\n")}
        require 'rack/mock'
        require File.join(PADRINO_ROOT, 'config/apps.rb')
        Padrino.load!
        puts "status=\#{Rack::MockRequest.new(Padrino.application).post(#{path.inspect}).status}"
      RUBY
      out, = Open3.capture2e({ 'RACK_ENV' => env }, RbConfig.ruby, '-rbundler/setup', '-e', script)
      out
    end

    { 'nothing' => [], 'padrino-helpers' => %w[padrino-helpers], 'padrino-mailer' => %w[padrino-mailer] }.each do |added, gems|
      [false, true].each do |tiny|
        it "should boot #{tiny ? 'a tiny' : 'an'} app in an api project with #{added} added to its Gemfile" do
          project = "#{@apptmp}/sample_project"
          capture_io { generate(:project, 'sample_project', '--api', "--root=#{@apptmp}") }
          File.write("#{project}/Gemfile", gems.map { |gem| "gem '#{gem}'\n" }.join, mode: 'a')
          capture_io { generate(:app, 'demo', *(tiny ? ['--tiny'] : []), "--root=#{project}") }
          assert_match(/status=404$/, boot_project(project, *gems))
        end
      end
    end

    describe 'CSRF protection in an api project' do
      def setup
        super
        @project = "#{@apptmp}/sample_project"
        capture_io { generate(:project, 'sample_project', '--api', "--root=#{@apptmp}") }
      end

      def generate_app_with_route(name = 'demo')
        capture_io { generate(:app, name, "--root=#{@project}") }
        File.write("#{@project}/#{name}/controllers/ping.rb", "SampleProject::#{name.capitalize}.controllers { post('/ping') { 'posted' } }\n")
      end

      def edit(file, pattern, replacement)
        File.write(file, File.read(file).sub(pattern, replacement))
      end

      it 'should accept a POST without a token while sessions are off' do
        generate_app_with_route
        assert_match(/status=200$/, boot_project(@project, path: '/demo/ping'))
      end

      it 'should reject a POST without a token after enabling sessions in the app' do
        generate_app_with_route
        edit("#{@project}/demo/app.rb", /^.*set :protect_from_csrf.*$/, "\\0\n    enable :sessions")
        assert_match(/status=403$/, boot_project(@project, path: '/demo/ping'))
      end

      it 'should reject a POST without a token after enabling sessions in config/apps.rb' do
        generate_app_with_route
        edit("#{@project}/config/apps.rb", '# enable :sessions', 'enable :sessions')
        assert_match(/status=403$/, boot_project(@project, path: '/demo/ping'))
      end

      it 'should keep the test environment exemption with sessions enabled' do
        generate_app_with_route
        edit("#{@project}/config/apps.rb", '# enable :sessions', 'enable :sessions')
        assert_match(/status=200$/, boot_project(@project, env: 'test', path: '/demo/ping'))
      end

      { "gem 'padrino'" => %w[padrino], "gem 'padrino-helpers'\ngem 'padrino-mailer'" => %w[padrino-helpers padrino-mailer] }.each do |lines, gems|
        it "should protect an app with sessions after adding #{gems.join(' and ')} to the Gemfile" do
          generate_app_with_route
          File.write("#{@project}/Gemfile", "#{lines}\n", mode: 'a')
          generate_app_with_route('web')
          assert_match_in_file(/set :sessions/, "#{@project}/web/app.rb")
          assert_match(/status=403$/, boot_project(@project, *gems, path: '/web/ping'))
          assert_match(/status=200$/, boot_project(@project, *gems, path: '/demo/ping'))
        end
      end

      it 'should accept a POST to a new app in an older project, which turns CSRF on for every app' do
        edit("#{@project}/config/apps.rb", /^.*set :protect_from_csrf.*$/, '  set :protect_from_csrf, Padrino.env != :test')
        generate_app_with_route
        assert_match(/status=200$/, boot_project(@project, path: '/demo/ping'))
      end
    end

    describe 'reading the Gemfile of an api project' do
      def setup
        super
        @project = "#{@apptmp}/sample_project"
        capture_io { generate(:project, 'sample_project', '--api', "--root=#{@apptmp}") }
      end

      def assert_api_app
        app_file = "#{@project}/demo/app.rb"
        assert_no_match_in_file(/Padrino::(Mailer|Helpers)/, app_file)
        assert_no_match_in_file(/set :sessions/, app_file)
      end

      def prepend_to_gemfile(bytes)
        gemfile = "#{@project}/Gemfile"
        File.binwrite(gemfile, bytes.b + File.binread(gemfile))
      end

      it 'should read a Latin-1 Gemfile' do
        prepend_to_gemfile("# Maintainer: Jos\xE9\n")
        capture_io { generate(:app, 'demo', "--root=#{@project}") }
        assert_api_app
      end

      it 'should read a UTF-8 Gemfile under an ASCII locale' do
        prepend_to_gemfile("# Maintainer: Jos\u00E9\n")
        external = Encoding.default_external
        begin
          capture_io do
            Encoding.default_external = Encoding::US_ASCII
            generate(:app, 'demo', "--root=#{@project}")
          end
        ensure
          Encoding.default_external = external
        end
        assert_api_app
      end

      it 'should read a parenthesised gem declaration' do
        gemfile = "#{@project}/Gemfile"
        File.write(gemfile, File.read(gemfile).gsub(/^gem 'padrino-(\w+)'(.*)$/, "gem('padrino-\\1'\\2)"))
        assert_match_in_file(/^gem\('padrino-core'/, gemfile)
        capture_io { generate(:app, 'demo', "--root=#{@project}") }
        assert_api_app
        assert_match(/status=404$/, boot_project(@project))
      end
    end

    it 'should generate tiny app skeleton' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:app, 'demo', '--tiny', "--root=#{@apptmp}/sample_project") }
      assert_dir_exists("#{@apptmp}/sample_project")
      assert_dir_exists("#{@apptmp}/sample_project/demo")
      assert_file_exists("#{@apptmp}/sample_project/demo/helpers.rb")
      assert_file_exists("#{@apptmp}/sample_project/demo/controllers.rb")
      assert_file_exists("#{@apptmp}/sample_project/demo/mailers.rb")
      assert_dir_exists("#{@apptmp}/sample_project/public/demo")
      assert_match_in_file(/:notifier/, "#{@apptmp}/sample_project/demo/mailers.rb")
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
      out, = capture_io { generate_with_parts(:app, 'demo', "--root=#{@apptmp}/sample_project", '-d', apps: 'demo') }
      refute_match(/has been mounted/, out)
      assert_no_dir_exists("#{@apptmp}/sample_project/public/demo")
      assert_no_file_exists("#{@apptmp}/sample_project/demo/app.rb")
      assert_no_dir_exists("#{@apptmp}/sample_project/demo/controllers")
      assert_no_dir_exists("#{@apptmp}/sample_project/demo/helpers")
      assert_no_dir_exists("#{@apptmp}/sample_project/demo/views")
      assert_no_match_in_file(%r{Padrino\.mount\("Demo"\).to\("/demo"\)}, "#{@apptmp}/sample_project/config/apps.rb")
    end

    it 'should abort if app name already exists' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      out, = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:app, 'kernel', "--root=#{@apptmp}/sample_project") }.status }
      assert_match(/Kernel already exists/, out)
      assert_no_dir_exists("#{@apptmp}/sample_project/public/kernel")
      assert_no_dir_exists("#{@apptmp}/sample_project/kernel/controllers")
      assert_no_dir_exists("#{@apptmp}/sample_project/kernel/helpers")
      assert_no_file_exists("#{@apptmp}/sample_project/kernel/app.rb")
    end

    it 'should abort if app name already exists in root' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:app, 'subapp', "--root=#{@apptmp}/sample_project") }
      out, = capture_io { assert_equal 1, assert_raises(SystemExit) { generate_with_parts(:app, 'subapp', "--root=#{@apptmp}/sample_project", apps: 'subapp') }.status }
      assert_dir_exists("#{@apptmp}/sample_project/public/subapp")
      assert_dir_exists("#{@apptmp}/sample_project/subapp/controllers")
      assert_dir_exists("#{@apptmp}/sample_project/subapp/helpers")
      assert_file_exists("#{@apptmp}/sample_project/subapp/app.rb")
      assert_match(/Subapp already exists/, out)
    end

    it 'should generate app files if :force option is specified' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:app, 'kernel', "--root=#{@apptmp}/sample_project", '--force') }
      assert_dir_exists("#{@apptmp}/sample_project/public/kernel")
      assert_dir_exists("#{@apptmp}/sample_project/kernel/controllers")
      assert_dir_exists("#{@apptmp}/sample_project/kernel/helpers")
      assert_file_exists("#{@apptmp}/sample_project/kernel/app.rb")
    end

    it 'should allow to pass upcased name as the app name' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:app, 'API', "--root=#{@apptmp}/sample_project", '--force') }
      assert_dir_exists("#{@apptmp}/sample_project/public/api")
      assert_dir_exists("#{@apptmp}/sample_project/api/controllers")
      assert_dir_exists("#{@apptmp}/sample_project/api/helpers")
      assert_file_exists("#{@apptmp}/sample_project/api/app.rb")
      assert_match_in_file(/class API < Padrino::Application/, "#{@apptmp}/sample_project/api/app.rb")
    end
  end
end
