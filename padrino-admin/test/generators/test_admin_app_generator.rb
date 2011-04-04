require File.expand_path(File.dirname(__FILE__) + '/../helper')

class TestAdminAppGenerator < Test::Unit::TestCase

  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{UUID.new.generate}"
    `mkdir -p #{@apptmp}`
  end

  def teardown
    `rm -rf #{@apptmp}`
  end

  context 'the admin app generator' do

    should 'fail outside app root' do
      output = silence_logger { generate(:admin_app, "-r=#{@apptmp}") }
      assert_match(/not at the root/, output)
      assert_no_file_exists('/tmp/admin')
    end

    should 'fail if we don\'t specify an orm' do
      assert_nothing_raised { silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}") } }
      assert_raise(SystemExit) { silence_logger { generate(:admin_app, "-r=#{@apptmp}/sample_project") } }
    end

    should 'fail if we don\'t specify a valid theme' do
      assert_nothing_raised { silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=activerecord') } }
      assert_raise(SystemExit) { silence_logger { generate(:admin_app, "-r=#{@apptmp}/sample_project", '--theme=foo') } }
    end

    should 'correctly generate a new padrino admin application with default renderer' do
      assert_nothing_raised { silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=activerecord', '-e=haml') } }
      assert_nothing_raised { silence_logger { generate(:admin_app, "--root=#{@apptmp}/sample_project") } }
      assert_file_exists("#{@apptmp}/sample_project")
      assert_file_exists("#{@apptmp}/sample_project/admin")
      assert_file_exists("#{@apptmp}/sample_project/admin/app.rb")
      assert_file_exists("#{@apptmp}/sample_project/admin/controllers")
      assert_file_exists("#{@apptmp}/sample_project/admin/controllers/accounts.rb")
      assert_file_exists("#{@apptmp}/sample_project/admin/controllers/base.rb")
      assert_file_exists("#{@apptmp}/sample_project/admin/controllers/sessions.rb")
      assert_file_exists("#{@apptmp}/sample_project/admin/views")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/_form.haml")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/edit.haml")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/index.haml")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/new.haml")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/base/index.haml")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/sessions/new.haml")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/base/_sidebar.haml")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/base/index.haml")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/layouts/application.haml")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/sessions/new.haml")
      assert_file_exists("#{@apptmp}/sample_project/public/admin")
      assert_file_exists("#{@apptmp}/sample_project/public/admin/stylesheets")
      assert_file_exists("#{@apptmp}/sample_project/app/models/account.rb")
      assert_file_exists("#{@apptmp}/sample_project/db/seeds.rb")
      assert_file_exists("#{@apptmp}/sample_project/db/migrate/001_create_accounts.rb")
      assert_match_in_file 'Padrino.mount("Admin").to("/admin")', "#{@apptmp}/sample_project/config/apps.rb"
      assert_match_in_file 'class Admin < Padrino::Application', "#{@apptmp}/sample_project/admin/app.rb"
      assert_match_in_file 'role.project_module :accounts, "/accounts"', "#{@apptmp}/sample_project/admin/app.rb"
      assert_match_in_file 'set :session_secret, "', "#{@apptmp}/sample_project/admin/app.rb"
    end

    should 'correctly generate a new padrino admin application with erb renderer' do
      assert_nothing_raised { silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=activerecord', '-e=erb') } }
      assert_nothing_raised { silence_logger { generate(:admin_app, "--root=#{@apptmp}/sample_project") } }
      assert_file_exists("#{@apptmp}/sample_project")
      assert_file_exists("#{@apptmp}/sample_project/admin")
      assert_file_exists("#{@apptmp}/sample_project/admin/app.rb")
      assert_file_exists("#{@apptmp}/sample_project/admin/controllers")
      assert_file_exists("#{@apptmp}/sample_project/admin/controllers/accounts.rb")
      assert_file_exists("#{@apptmp}/sample_project/admin/controllers/base.rb")
      assert_file_exists("#{@apptmp}/sample_project/admin/controllers/sessions.rb")
      assert_file_exists("#{@apptmp}/sample_project/admin/views")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/_form.erb")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/edit.erb")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/index.erb")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/new.erb")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/base/index.erb")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/sessions/new.erb")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/base/_sidebar.erb")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/base/index.erb")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/layouts/application.erb")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/sessions/new.erb")
      assert_file_exists("#{@apptmp}/sample_project/public/admin")
      assert_file_exists("#{@apptmp}/sample_project/public/admin/stylesheets")
      assert_file_exists("#{@apptmp}/sample_project/app/models/account.rb")
      assert_file_exists("#{@apptmp}/sample_project/db/seeds.rb")
      assert_file_exists("#{@apptmp}/sample_project/db/migrate/001_create_accounts.rb")
      assert_match_in_file 'Padrino.mount("Admin").to("/admin")', "#{@apptmp}/sample_project/config/apps.rb"
      assert_match_in_file 'class Admin < Padrino::Application', "#{@apptmp}/sample_project/admin/app.rb"
      assert_match_in_file 'role.project_module :accounts, "/accounts"', "#{@apptmp}/sample_project/admin/app.rb"
      assert_match_in_file 'set :session_secret, "', "#{@apptmp}/sample_project/admin/app.rb"
    end

    should 'correctly generate a new padrino admin application with erubis renderer' do
      assert_nothing_raised { silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=activerecord', '-e=erubis') } }
      assert_nothing_raised { silence_logger { generate(:admin_app, "--root=#{@apptmp}/sample_project") } }
      assert_file_exists("#{@apptmp}/sample_project")
      assert_file_exists("#{@apptmp}/sample_project/admin")
      assert_file_exists("#{@apptmp}/sample_project/admin/app.rb")
      assert_file_exists("#{@apptmp}/sample_project/admin/controllers")
      assert_file_exists("#{@apptmp}/sample_project/admin/controllers/accounts.rb")
      assert_file_exists("#{@apptmp}/sample_project/admin/controllers/base.rb")
      assert_file_exists("#{@apptmp}/sample_project/admin/controllers/sessions.rb")
      assert_file_exists("#{@apptmp}/sample_project/admin/views")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/_form.erubis")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/edit.erubis")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/index.erubis")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/accounts/new.erubis")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/base/index.erubis")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/sessions/new.erubis")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/base/_sidebar.erubis")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/base/index.erubis")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/layouts/application.erubis")
      assert_file_exists("#{@apptmp}/sample_project/admin/views/sessions/new.erubis")
      assert_file_exists("#{@apptmp}/sample_project/public/admin")
      assert_file_exists("#{@apptmp}/sample_project/public/admin/stylesheets")
      assert_file_exists("#{@apptmp}/sample_project/admin/models/account.rb")
      assert_no_file_exists("#{@apptmp}/sample_project/app/models/account.rb")
      assert_file_exists("#{@apptmp}/sample_project/db/seeds.rb")
      assert_file_exists("#{@apptmp}/sample_project/db/migrate/001_create_accounts.rb")
      assert_match_in_file 'Padrino.mount("Admin").to("/admin")', "#{@apptmp}/sample_project/config/apps.rb"
      assert_match_in_file 'class Admin < Padrino::Application', "#{@apptmp}/sample_project/admin/app.rb"
      assert_match_in_file 'role.project_module :accounts, "/accounts"', "#{@apptmp}/sample_project/admin/app.rb"
    end

    should 'not conflict with existing seeds file' do
      assert_nothing_raised { silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=activerecord', '-e=erb') } }

      # Add seeds file
      FileUtils.mkdir_p @apptmp + '/sample_project/db' unless File.exist?(@apptmp + '/sample_project/db')
      File.open(@apptmp + '/sample_project/db/seeds.rb', 'w+') do |seeds_rb|
        seeds_rb.puts "# Old Seeds Content"
      end

      silence_logger do
        $stdout.expects(:print).with { |value| value =~ /Overwrite\s.*?\/db\/seeds.rb/ }.never
        $stdin.stubs(:gets).returns('y')
        generate(:admin_app, "--root=#{@apptmp}/sample_project")
      end

      assert_match_in_file '# Old Seeds Content', "#{@apptmp}/sample_project/db/seeds.rb"
      assert_match_in_file 'Account.create(', "#{@apptmp}/sample_project/db/seeds.rb"
    end
  end
end