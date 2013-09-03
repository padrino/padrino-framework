require File.expand_path(File.dirname(__FILE__) + '/../helper')

describe "AdminAppGenerator" do
  before do
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{UUID.new.generate}"
    `mkdir -p #{@apptmp}`
  end

  after do
    `rm -rf #{@apptmp}`
  end

  describe 'the admin app generator' do
    it 'should fail outside app root' do
      out, err = capture_io { generate(:admin_app, "-r=#{@apptmp}") }
      assert_match(/not at the root/, out)
      assert_no_file_exists("#{@apptmp}/admin")
    end

    it "should fail if we don't specify an orm on the project" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-e=haml') }
      assert_raises(SystemExit) { @out, @err = capture_io { generate(:admin_app, "-r=#{@apptmp}/sample_project") } }
    end

    it "should store and apply session_secret" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=datamapper','-e=haml') }
      assert_match_in_file(/set :session_secret, '[0-9A-z]*'/, "#{@apptmp}/sample_project/config/apps.rb")
    end

    it "should generate the admin app" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=activerecord') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      assert_file_exists("#{@apptmp}/sample_project")
      assert_file_exists("#{@apptmp}/sample_project/admin")
      assert_file_exists("#{@apptmp}/sample_project/admin/app.rb")
      assert_file_exists("#{@apptmp}/sample_project/admin/controllers")
      assert_file_exists("#{@apptmp}/sample_project/admin/controllers/accounts.rb")
      assert_file_exists("#{@apptmp}/sample_project/admin/controllers/base.rb")
      assert_file_exists("#{@apptmp}/sample_project/admin/controllers/sessions.rb")
      assert_file_exists("#{@apptmp}/sample_project/admin/views")
      assert_file_exists("#{@apptmp}/sample_project/public/admin")
      assert_file_exists("#{@apptmp}/sample_project/public/admin/stylesheets")
      assert_file_exists("#{@apptmp}/sample_project/public/admin/stylesheets/application.css")
      assert_file_exists("#{@apptmp}/sample_project/public/admin/stylesheets/bootstrap.css")
      assert_file_exists("#{@apptmp}/sample_project/public/admin/javascripts/application.js")
      assert_file_exists("#{@apptmp}/sample_project/public/admin/javascripts/jquery-1.9.0.min.js")
      assert_file_exists("#{@apptmp}/sample_project/models/account.rb")
      assert_file_exists("#{@apptmp}/sample_project/db/seeds.rb")
      assert_file_exists("#{@apptmp}/sample_project/db/migrate/001_create_accounts.rb")
      assert_match_in_file 'Padrino.mount("SampleProject::Admin", :app_file => File.expand_path(\'../../admin/app.rb\', __FILE__)).to("/admin")', "#{@apptmp}/sample_project/config/apps.rb"
      assert_match_in_file 'module SampleProject', "#{@apptmp}/sample_project/admin/app.rb"
      assert_match_in_file 'class Admin < Padrino::Application', "#{@apptmp}/sample_project/admin/app.rb"
      assert_match_in_file 'role.project_module :accounts, \'/accounts\'', "#{@apptmp}/sample_project/admin/app.rb"
    end

    # users can override certain templates from a generators/templates folder in the destination_root
    it "should use custom generator templates from the project root, if they exist" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=activerecord') }
      custom_template_path = "#{@apptmp}/sample_project/generators/templates/slim/app/layouts/"
      `mkdir -p #{custom_template_path} && echo "h1 = 'Hello, custom generator' " > #{custom_template_path}application.slim.tt`
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      assert_match_in_file(/Hello, custom generator/, "#{@apptmp}/sample_project/admin/views/layouts/application.slim")
    end

    it "should generate the admin app under a different folder" do
      # TODO FIXME Implement option --admin_root or something. See https://github.com/padrino/padrino-framework/issues/854#issuecomment-14749356
      skip
    end

    describe "renderers" do
      it 'should correctly generate a new padrino admin application with haml renderer (default)' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=activerecord', '-e=haml') }
        capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
        assert_file_exists("#{@apptmp}/sample_project/admin/views")
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
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=activerecord', '-e=erb') }
        capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
        assert_file_exists("#{@apptmp}/sample_project/admin/views")
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
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=activerecord', '-e=slim') }
        capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
        assert_file_exists("#{@apptmp}/sample_project/admin/views")
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
    end

    it 'should correctly generate a new padrino admin application with a custom model' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=activerecord', '-e=slim') }
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
      assert_match_in_file 'role.project_module :users, \'/users\'', "#{@apptmp}/sample_project/admin/app.rb"
    end

    it 'should correctly generate a new padrino admin application with model in non-default application path' do
      # TODO FIXME What's the use case here? Clarify.
      # Remember that --root/-r in the admin_app generator refers to the project's location, not the admin's location
      # inside it. See https://github.com/padrino/padrino-framework/issues/854#issuecomment-14749356
      skip
      # capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=activerecord', '-e=haml') }
      # capture_io { generate(:admin_app,"-a=/admin", "--root=#{@apptmp}/sample_project") }
      # assert_file_exists("#{@apptmp}/sample_project")
      # assert_file_exists("#{@apptmp}/sample_project/admin")
      # assert_file_exists("#{@apptmp}/sample_project/admin/app.rb")
      # assert_file_exists("#{@apptmp}/sample_project/admin/controllers")
      # assert_file_exists("#{@apptmp}/sample_project/admin/controllers/accounts.rb")
      # assert_file_exists("#{@apptmp}/sample_project/admin/controllers/base.rb")
      # assert_file_exists("#{@apptmp}/sample_project/admin/controllers/sessions.rb")
      # assert_file_exists("#{@apptmp}/sample_project/admin/views")
      # assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/_form.haml")
      # assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/edit.haml")
      # assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/index.haml")
      # assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/new.haml")
      # assert_file_exists("#{@apptmp}/sample_project/admin/views/base/index.haml")
      # assert_file_exists("#{@apptmp}/sample_project/admin/views/sessions/new.haml")
      # assert_file_exists("#{@apptmp}/sample_project/admin/views/base/index.haml")
      # assert_file_exists("#{@apptmp}/sample_project/admin/views/layouts/application.haml")
      # assert_file_exists("#{@apptmp}/sample_project/admin/views/sessions/new.haml")
      # assert_file_exists("#{@apptmp}/sample_project/public/admin")
      # assert_file_exists("#{@apptmp}/sample_project/public/admin/stylesheets")
      # assert_file_exists("#{@apptmp}/sample_project/models/account.rb")
      # assert_no_file_exists("#{@apptmp}/sample_project/models/account.rb")
      # assert_file_exists("#{@apptmp}/sample_project/db/seeds.rb")
      # assert_file_exists("#{@apptmp}/sample_project/db/migrate/001_create_accounts.rb")
      # assert_match_in_file 'role.project_module :accounts, \'/accounts\'', "#{@apptmp}/sample_project/admin/app.rb"
    end

    describe "activerecord middleware" do
      it 'should add it for #activerecord' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=activerecord', '-e=haml') }
        capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
        assert_match_in_file(/  use ActiveRecord::ConnectionAdapters::ConnectionManagemen/m, "#{@apptmp}/sample_project/admin/app.rb")
      end

      it 'should add it #minirecord' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=minirecord', '-e=haml') }
        capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
        assert_match_in_file(/  use ActiveRecord::ConnectionAdapters::ConnectionManagemen/m, "#{@apptmp}/sample_project/admin/app.rb")
      end

      it 'should not add it for #datamapper' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=datamapper', '-e=haml') }
        capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
        assert_no_match_in_file(/  use ActiveRecord::ConnectionAdapters::ConnectionManagemen/m, "#{@apptmp}/sample_project/admin/app.rb")
      end
    end

    it 'should not conflict with existing seeds file' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=activerecord', '-e=erb') }

      # Add seeds file
      FileUtils.mkdir_p @apptmp + '/sample_project/db' unless File.exist?(@apptmp + '/sample_project/db')
      File.open(@apptmp + '/sample_project/db/seeds.rb', 'w+') do |seeds_rb|
        seeds_rb.puts "# Old Seeds Content"
      end

      capture_io do
        $stdout.expects(:print).with { |value| value =~ /Overwrite\s.*?\/db\/seeds.rb/ }.never
        $stdin.stubs(:gets).returns('y')
        generate(:admin_app, "--root=#{@apptmp}/sample_project")
      end

      assert_file_exists "#{@apptmp}/sample_project/db/seeds.old"
      assert_match_in_file 'Account.create(', "#{@apptmp}/sample_project/db/seeds.rb"
    end
  end
end
