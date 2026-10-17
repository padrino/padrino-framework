require_relative '../helper'
require 'open3'

describe 'AdminAppGenerator' do
  before do
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{SecureRandom.hex}"
    `mkdir -p #{@apptmp}`
  end

  after do
    `rm -rf #{@apptmp}`
  end

  describe 'the admin app generator' do
    before do
      Object.send(:remove_const, :Account) if defined?(Account)
    end

    it 'should fail outside app root' do
      out, = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:admin_app, "-r=#{@apptmp}") }.status }
      assert_match(/not at the root/, out)
      assert_no_file_exists("#{@apptmp}/admin")
    end

    it "should fail if we don't specify an orm on the project" do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-e=haml') }
      out, = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:admin_app, "-r=#{@apptmp}/sample_project") }.status }
      assert_match(/Padrino only supports/, out)
    end

    it 'should fail without writing anything when the project orm is no longer supported' do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=sequel') }
      components = "#{@apptmp}/sample_project/.components"
      File.write(components, File.read(components).sub(':orm: sequel', ':orm: ohm'))
      out, = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:admin_app, "-r=#{@apptmp}/sample_project") }.status }
      assert_match(/only supports activerecord or mongoid or sequel\. Sorry!/, out)
      assert_no_dir_exists("#{@apptmp}/sample_project/admin")
      assert_no_file_exists("#{@apptmp}/sample_project/models/account.rb")
    end

    it 'should fail with an unsupported renderer' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=activerecord', '-e=haml') }
      out, = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:admin_app, "-r=#{@apptmp}/sample_project", '-e=liquid') }.status }
      assert_match(/for admin we only support/, out)
      assert_no_file_exists("#{@apptmp}/sample_project/admin")
    end

    it 'should reuse an existing account model' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=activerecord', '-e=haml') }
      Object.const_set(:Account, Class.new)
      begin
        capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      rescue SystemExit => e
        flunk "the admin generator exited with status #{e.status}"
      end
      assert_file_exists("#{@apptmp}/sample_project/admin/app.rb")
      assert_match_in_file(/class Account < ActiveRecord::Base/, "#{@apptmp}/sample_project/models/account.rb")
      assert_no_file_exists("#{@apptmp}/sample_project/db/migrate/001_create_accounts.rb")
    ensure
      Object.send(:remove_const, :Account) if defined?(Account)
    end

    it 'should generate the account model test with the project test_config path' do
      capture_io { generate(:project, 'sample_project', '-e=haml', "--root=#{@apptmp}", '-d=activerecord', '-t=minitest') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      assert_match_in_file %r{__dir__\}/\.\./test_config\.rb}, "#{@apptmp}/sample_project/test/models/account_test.rb"
    end

    it 'should generate seeds that read the account from piped input' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=sequel', '-e=haml') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      script = <<~RUBY
        require 'thor'
        # Thor's line editor can echo or buffer piped input, so without a terminal the
        # seeds must not ask through it.
        class NoAskShell < Thor::Base.shell
          def ask(*)
            raise 'shell.ask used without a terminal'
          end
        end

        def shell
          @shell ||= NoAskShell.new
        end
        class Account
          def initialize(attributes)
            @attributes = attributes
          end

          def valid?
            true
          end

          def save
            puts "SAVED \#{@attributes[:email]} \#{@attributes[:password] == 'secret123'}"
          end
        end
        load 'db/seeds.rb'
      RUBY
      env = { 'BUNDLE_GEMFILE' => File.expand_path('../../../Gemfile', __dir__) }
      out, err, status = Open3.capture3(env, RbConfig.ruby, '-rbundler/setup', '-e', script,
                                        chdir: "#{@apptmp}/sample_project", stdin_data: "admin@example.com \nsecret123\r\n")
      assert status.success?, err
      assert_includes out.lines.map(&:strip), 'SAVED admin@example.com true'
      refute_includes out, 'secret123'
    end

    it 'should store and apply session_secret' do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=sequel', '-e=haml') }
      assert_match_in_file(/^  set :session_secret, ENV\.fetch\('SESSION_SECRET'\) \{ '\h{64}' \}$/, "#{@apptmp}/sample_project/config/apps.rb")
    end

    it 'should set SameSite=Lax and Secure in production on the admin session cookie' do
      capture_io { generate(:project, 'sample_project', '-e=haml', "--root=#{@apptmp}", '-d=activerecord') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      assert_match_in_file(/^    set :sessions, same_site: :lax, secure: Padrino\.env == :production$/, "#{@apptmp}/sample_project/admin/app.rb")
      assert_no_match_in_file(/^\s*enable\s+:sessions/, "#{@apptmp}/sample_project/admin/app.rb")
    end

    it 'should generate the admin app' do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=activerecord') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      assert_dir_exists("#{@apptmp}/sample_project")
      assert_dir_exists("#{@apptmp}/sample_project/admin")
      assert_file_exists("#{@apptmp}/sample_project/admin/app.rb")
      assert_dir_exists("#{@apptmp}/sample_project/admin/controllers")
      assert_file_exists("#{@apptmp}/sample_project/admin/controllers/accounts.rb")
      assert_file_exists("#{@apptmp}/sample_project/admin/controllers/base.rb")
      assert_file_exists("#{@apptmp}/sample_project/admin/controllers/sessions.rb")
      assert_dir_exists("#{@apptmp}/sample_project/admin/views")
      assert_dir_exists("#{@apptmp}/sample_project/public/admin")
      assert_dir_exists("#{@apptmp}/sample_project/public/admin/stylesheets")
      assert_file_exists("#{@apptmp}/sample_project/public/admin/stylesheets/application.css")
      assert_file_exists("#{@apptmp}/sample_project/public/admin/stylesheets/bootstrap.css")
      assert_file_exists("#{@apptmp}/sample_project/public/admin/javascripts/application.js")
      assert_file_exists("#{@apptmp}/sample_project/public/admin/javascripts/jquery-3.7.1.min.js")
      assert_file_exists("#{@apptmp}/sample_project/models/account.rb")
      assert_file_exists("#{@apptmp}/sample_project/db/seeds.rb")
      assert_file_exists("#{@apptmp}/sample_project/db/migrate/001_create_accounts.rb")
      assert_match_in_file %(Padrino.mount('SampleProject::Admin', app_file: Padrino.root('admin/app.rb')).to('/admin')), "#{@apptmp}/sample_project/config/apps.rb"
      assert_match_in_file 'module SampleProject', "#{@apptmp}/sample_project/admin/app.rb"
      assert_match_in_file 'class Admin < Padrino::Application', "#{@apptmp}/sample_project/admin/app.rb"
      assert_match_in_file "role.project_module :accounts, '/accounts'", "#{@apptmp}/sample_project/admin/app.rb"
    end

    it 'should generate the master app' do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=activerecord') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project", '--admin-name=master') }
      assert_file_exists("#{@apptmp}/sample_project/master/app.rb")
    end

    # users can override certain templates from a generators/templates folder in the destination_root
    it 'should use custom generator templates from the project root, if they exist' do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=activerecord') }
      custom_template_path = "#{@apptmp}/sample_project/generators/templates/slim/app/layouts/"
      `mkdir -p #{custom_template_path} && echo "h1 = 'Hello, custom generator' " > #{custom_template_path}application.slim.tt`
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      assert_match_in_file(/Hello, custom generator/, "#{@apptmp}/sample_project/admin/views/layouts/application.slim")
    end

    it 'should generate the account pages in an admin app named with a plural' do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=sequel') }
      begin
        capture_io { generate(:admin_app, '-a=admins', "--root=#{@apptmp}/sample_project") }
      rescue SystemExit => e
        flunk "the admin generator exited with status #{e.status}"
      end
      assert_file_exists("#{@apptmp}/sample_project/admins/controllers/accounts.rb")
      assert_no_dir_exists("#{@apptmp}/sample_project/admin")
    end

    it 'should generate the admin app under a different folder' do
      # TODO: FIXME Implement option --admin_root or something. See https://github.com/padrino/padrino-framework/issues/854#issuecomment-14749356
      skip
    end

    describe 'renderers' do
      it 'should correctly generate a new padrino admin application with haml renderer (default)' do
        capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=activerecord', '-e=haml') }
        capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
        assert_dir_exists("#{@apptmp}/sample_project/admin/views")
        assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/_form.haml")
        assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/edit.haml")
        assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/index.haml")
        assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/new.haml")
        assert_file_exists("#{@apptmp}/sample_project/admin/views/base/index.haml")
        assert_file_exists("#{@apptmp}/sample_project/admin/views/sessions/new.haml")
        assert_file_exists("#{@apptmp}/sample_project/admin/views/base/index.haml")
        assert_file_exists("#{@apptmp}/sample_project/admin/views/layouts/application.haml")
        assert_file_exists("#{@apptmp}/sample_project/admin/views/sessions/new.haml")
      end

      it 'should correctly generate a new padrino admin application with erb renderer' do
        capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=activerecord', '-e=erb') }
        capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
        assert_dir_exists("#{@apptmp}/sample_project/admin/views")
        assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/_form.erb")
        assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/edit.erb")
        assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/index.erb")
        assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/new.erb")
        assert_file_exists("#{@apptmp}/sample_project/admin/views/base/index.erb")
        assert_file_exists("#{@apptmp}/sample_project/admin/views/sessions/new.erb")
        assert_file_exists("#{@apptmp}/sample_project/admin/views/base/index.erb")
        assert_file_exists("#{@apptmp}/sample_project/admin/views/layouts/application.erb")
        assert_file_exists("#{@apptmp}/sample_project/admin/views/sessions/new.erb")
      end

      it 'should correctly generate a new padrino admin application with slim renderer' do
        capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=activerecord', '-e=slim') }
        capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
        assert_dir_exists("#{@apptmp}/sample_project/admin/views")
        assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/_form.slim")
        assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/edit.slim")
        assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/index.slim")
        assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/new.slim")
        assert_file_exists("#{@apptmp}/sample_project/admin/views/base/index.slim")
        assert_file_exists("#{@apptmp}/sample_project/admin/views/sessions/new.slim")
        assert_file_exists("#{@apptmp}/sample_project/admin/views/base/index.slim")
        assert_file_exists("#{@apptmp}/sample_project/admin/views/layouts/application.slim")
        assert_file_exists("#{@apptmp}/sample_project/admin/views/sessions/new.slim")
      end

      %w[haml erb slim].each do |engine|
        it "should serve every script the #{engine} admin pages include" do
          skip 'the sqlite3 gem is only bundled on MRI' if RUBY_ENGINE == 'jruby'
          capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=sequel', "-e=#{engine}") }
          capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
          script = <<~'RUBY'
            ENV['RACK_ENV'] = 'test'
            %w[sequel haml slim erubi nokogiri rack/test].each { |lib| require lib }
            Sequel.extension :migration
            Sequel.sqlite('db/sample_project_test.db') { |db| Sequel::Migrator.run(db, 'db/migrate') }
            require File.expand_path('config/boot')
            account_id = Account.dataset.insert(email: 'admin@example.com', role: 'admin', crypted_password: 'unused')

            browser = Rack::Test::Session.new(Padrino.application)
            check = lambda do |page|
              browser.get(page)
              puts "PAGE #{page} #{browser.last_response.status}"
              srcs = Nokogiri::HTML(browser.last_response.body).css('script[src]').map { |tag| tag['src'] }
              srcs.select { |src| src.start_with?('/') }.each do |src|
                puts "SCRIPT #{page} #{src} #{browser.get(src).status}"
              end
            end
            check.call('/admin/sessions/new')
            browser.env('rack.session', SampleProject::Admin.session_id => account_id)
            check.call('/admin/')
            check.call('/admin/accounts')
          RUBY
          env = { 'BUNDLE_GEMFILE' => File.expand_path('../../../Gemfile', __dir__) }
          out, err, status = Open3.capture3(env, RbConfig.ruby, '-rbundler/setup', '-e', script, chdir: "#{@apptmp}/sample_project")
          assert status.success?, err
          pages = out.lines.grep(/\APAGE /).map(&:split)
          scripts = out.lines.grep(/\ASCRIPT /).map(&:split)
          statuses = pages.map { |line| line[1, 2] }
          assert_equal [['/admin/sessions/new', '200'], ['/admin/', '200'], ['/admin/accounts', '200']], statuses
          pages.each do |(_, page)|
            refute_empty scripts.select { |line| line[1] == page }, "#{page} includes no local scripts"
          end
          scripts.each do |(_, page, src, code)|
            assert_equal '200', code, "#{page} includes #{src}, which is not served"
          end
        end
      end
    end

    it 'should correctly generate a new padrino admin application with a custom model' do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=activerecord', '-e=slim') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project", '-m=User') }
      assert_no_match_in_file(/[^_]account/i, "#{@apptmp}/sample_project/admin/controllers/users.rb")
      assert_match_in_file(/[^_]user/i, "#{@apptmp}/sample_project/admin/controllers/users.rb")
      assert_no_match_in_file(/[^_]account/i, "#{@apptmp}/sample_project/admin/views/users/_form.slim")
      assert_match_in_file(/[^_]user/i, "#{@apptmp}/sample_project/admin/views/users/_form.slim")
      assert_no_match_in_file(/[^_]account/i, "#{@apptmp}/sample_project/admin/views/users/edit.slim")
      assert_match_in_file(/[^_]user/i, "#{@apptmp}/sample_project/admin/views/users/edit.slim")
      assert_no_match_in_file(/[^_]account/i, "#{@apptmp}/sample_project/admin/views/users/index.slim")
      assert_match_in_file(/[^_]user/i, "#{@apptmp}/sample_project/admin/views/users/index.slim")
      assert_no_match_in_file(/[^_]account/i, "#{@apptmp}/sample_project/admin/views/users/new.slim")
      assert_match_in_file(/[^_]user/i, "#{@apptmp}/sample_project/admin/views/users/new.slim")
      assert_no_match_in_file(/Account/, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/User/, "#{@apptmp}/sample_project/models/user.rb")
      assert_file_exists("#{@apptmp}/sample_project/db/migrate/001_create_users.rb")
      assert_no_match_in_file(/[^_]account/i, "#{@apptmp}/sample_project/db/migrate/001_create_users.rb")
      assert_match_in_file "role.project_module :users, '/users'", "#{@apptmp}/sample_project/admin/app.rb"
    end

    it 'should correctly generate a new padrino admin application with model in non-default application path' do
      # TODO: FIXME What's the use case here? Clarify.
      # Remember that --root/-r in the admin_app generator refers to the project's location, not the admin's location
      # inside it. See https://github.com/padrino/padrino-framework/issues/854#issuecomment-14749356
      skip
      # capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=activerecord', '-e=haml') }
      # capture_io { generate(:admin_app,"-a=/admin", "--root=#{@apptmp}/sample_project") }
      # assert_dir_exists("#{@apptmp}/sample_project")
      # assert_dir_exists("#{@apptmp}/sample_project/admin")
      # assert_file_exists("#{@apptmp}/sample_project/admin/app.rb")
      # assert_file_exists("#{@apptmp}/sample_project/admin/controllers")
      # assert_file_exists("#{@apptmp}/sample_project/admin/controllers/accounts.rb")
      # assert_file_exists("#{@apptmp}/sample_project/admin/controllers/base.rb")
      # assert_file_exists("#{@apptmp}/sample_project/admin/controllers/sessions.rb")
      # assert_dir_exists("#{@apptmp}/sample_project/admin/views")
      # assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/_form.haml")
      # assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/edit.haml")
      # assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/index.haml")
      # assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/new.haml")
      # assert_file_exists("#{@apptmp}/sample_project/admin/views/base/index.haml")
      # assert_file_exists("#{@apptmp}/sample_project/admin/views/sessions/new.haml")
      # assert_file_exists("#{@apptmp}/sample_project/admin/views/base/index.haml")
      # assert_file_exists("#{@apptmp}/sample_project/admin/views/layouts/application.haml")
      # assert_file_exists("#{@apptmp}/sample_project/admin/views/sessions/new.haml")
      # assert_dir_exists("#{@apptmp}/sample_project/public/admin")
      # assert_dir_exists("#{@apptmp}/sample_project/public/admin/stylesheets")
      # assert_file_exists("#{@apptmp}/sample_project/models/account.rb")
      # assert_no_file_exists("#{@apptmp}/sample_project/models/account.rb")
      # assert_file_exists("#{@apptmp}/sample_project/db/seeds.rb")
      # assert_file_exists("#{@apptmp}/sample_project/db/migrate/001_create_accounts.rb")
      # assert_match_in_file 'role.project_module :accounts, \'/accounts\'', "#{@apptmp}/sample_project/admin/app.rb"
    end

    describe 'activerecord middleware' do
      it 'should add it for #activerecord' do
        capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=activerecord', '-e=haml') }
        capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
        assert_match_in_file(/  use ConnectionPoolManagement/m, "#{@apptmp}/sample_project/admin/app.rb")
      end
    end

    describe 'with the vite script component' do
      def assert_activesupport_listed_once(gemfile)
        Bundler.ui.expects(:warn).never
        dsl = Bundler::Dsl.new
        dsl.eval_gemfile(gemfile)
        assert_equal(1, dsl.dependencies.count { |dep| dep.name == 'activesupport' })
      end

      it 'should list activesupport once when admin is added after vite' do
        capture_io { generate(:project, 'sample_project', '-e=haml', "--root=#{@apptmp}", '-d=sequel', '--script=vite') }
        capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
        assert_activesupport_listed_once("#{@apptmp}/sample_project/Gemfile")
      end

      it 'should list activesupport once when vite is added after admin' do
        capture_io { generate(:project, 'sample_project', '-e=haml', "--root=#{@apptmp}", '-d=sequel') }
        capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
        capture_io { generate(:component, '--script=vite', "-r=#{@apptmp}/sample_project") }
        assert_activesupport_listed_once("#{@apptmp}/sample_project/Gemfile")
      end
    end

    it 'should not conflict with existing seeds file' do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=activerecord', '-e=erb') }

      # Add seeds file
      FileUtils.mkdir_p "#{@apptmp}/sample_project/db" unless File.exist?("#{@apptmp}/sample_project/db")
      File.open("#{@apptmp}/sample_project/db/seeds.rb", 'w+') do |seeds_rb|
        seeds_rb.puts '# Old Seeds Content'
      end

      out, = capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      refute_match(%r{Overwrite\s.*?/db/seeds.rb}, out)

      assert_file_exists "#{@apptmp}/sample_project/db/seeds.old"
      assert_match_in_file 'Account.new(', "#{@apptmp}/sample_project/db/seeds.rb"
    end
  end
end
