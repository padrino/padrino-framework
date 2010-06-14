require File.expand_path(File.dirname(__FILE__) + '/../helper')

class TestAdminAppGenerator < Test::Unit::TestCase

  def setup
    `rm -rf /tmp/sample_project`
  end

  context 'the admin app generator' do

    should 'fail outside app root' do
      output = silence_logger { generate(:admin_app, '-r=/tmp/sample_project') }
      assert_match(/not at the root/, output)
      assert_no_file_exists('/tmp/admin')
    end

    should 'fail if we don\'t an orm' do
      assert_nothing_raised { silence_logger { generate(:project, 'sample_project', '--root=/tmp') } }
      assert_raise(SystemExit) { silence_logger { generate(:admin_app, '-r=/tmp/sample_project') } }
    end

    should 'fail if we don\'t a valid theme' do
      assert_nothing_raised { silence_logger { generate(:project, 'sample_project', '--root=/tmp', '-d=activerecord') } }
      assert_raise(SystemExit) { silence_logger { generate(:admin_app, '-r=/tmp/sample_project', '--theme=foo') } }
    end

    should 'correctyl generate a new padrino admin application with default renderer' do
      assert_nothing_raised { silence_logger { generate(:project, 'sample_project', '--root=/tmp', '-d=activerecord', '-e=haml') } }
      assert_nothing_raised { silence_logger { generate(:admin_app, '--root=/tmp/sample_project') } }
      assert_file_exists('/tmp/sample_project')
      assert_file_exists('/tmp/sample_project/admin')
      assert_file_exists('/tmp/sample_project/admin/app.rb')
      assert_file_exists('/tmp/sample_project/admin/controllers')
      assert_file_exists('/tmp/sample_project/admin/controllers/accounts.rb')
      assert_file_exists('/tmp/sample_project/admin/controllers/base.rb')
      assert_file_exists('/tmp/sample_project/admin/controllers/sessions.rb')
      assert_file_exists('/tmp/sample_project/admin/views')
      assert_file_exists('/tmp/sample_project/admin/views/accounts/_form.haml')
      assert_file_exists('/tmp/sample_project/admin/views/accounts/edit.haml')
      assert_file_exists('/tmp/sample_project/admin/views/accounts/index.haml')
      assert_file_exists('/tmp/sample_project/admin/views/accounts/new.haml')
      assert_file_exists('/tmp/sample_project/admin/views/base/index.haml')
      assert_file_exists('/tmp/sample_project/admin/views/sessions/new.haml')
      assert_file_exists('/tmp/sample_project/admin/views/base/_sidebar.haml')
      assert_file_exists('/tmp/sample_project/admin/views/base/index.haml')
      assert_file_exists('/tmp/sample_project/admin/views/layouts/application.haml')
      assert_file_exists('/tmp/sample_project/admin/views/sessions/new.haml')
      assert_file_exists('/tmp/sample_project/public/admin')
      assert_file_exists('/tmp/sample_project/public/admin/stylesheets')
      assert_file_exists('/tmp/sample_project/app/models/account.rb')
      assert_file_exists('/tmp/sample_project/db/seeds.rb')
      assert_match_in_file 'Padrino.mount("Admin").to("/admin")', '/tmp/sample_project/config/apps.rb'
      assert_match_in_file 'class Admin < Padrino::Application', '/tmp/sample_project/admin/app.rb'
      assert_match_in_file 'role.project_module :accounts, "/accounts"', '/tmp/sample_project/admin/app.rb'
    end

    should 'correctyl generate a new padrino admin application with erb renderer' do
      assert_nothing_raised { silence_logger { generate(:project, 'sample_project', '--root=/tmp', '-d=activerecord', '-e=erb') } }
      assert_nothing_raised { silence_logger { generate(:admin_app, '--root=/tmp/sample_project') } }
      assert_file_exists('/tmp/sample_project')
      assert_file_exists('/tmp/sample_project/admin')
      assert_file_exists('/tmp/sample_project/admin/app.rb')
      assert_file_exists('/tmp/sample_project/admin/controllers')
      assert_file_exists('/tmp/sample_project/admin/controllers/accounts.rb')
      assert_file_exists('/tmp/sample_project/admin/controllers/base.rb')
      assert_file_exists('/tmp/sample_project/admin/controllers/sessions.rb')
      assert_file_exists('/tmp/sample_project/admin/views')
      assert_file_exists('/tmp/sample_project/admin/views/accounts/_form.erb')
      assert_file_exists('/tmp/sample_project/admin/views/accounts/edit.erb')
      assert_file_exists('/tmp/sample_project/admin/views/accounts/index.erb')
      assert_file_exists('/tmp/sample_project/admin/views/accounts/new.erb')
      assert_file_exists('/tmp/sample_project/admin/views/base/index.erb')
      assert_file_exists('/tmp/sample_project/admin/views/sessions/new.erb')
      assert_file_exists('/tmp/sample_project/admin/views/base/_sidebar.erb')
      assert_file_exists('/tmp/sample_project/admin/views/base/index.erb')
      assert_file_exists('/tmp/sample_project/admin/views/layouts/application.erb')
      assert_file_exists('/tmp/sample_project/admin/views/sessions/new.erb')
      assert_file_exists('/tmp/sample_project/public/admin')
      assert_file_exists('/tmp/sample_project/public/admin/stylesheets')
      assert_file_exists('/tmp/sample_project/app/models/account.rb')
      assert_file_exists('/tmp/sample_project/db/seeds.rb')
      assert_match_in_file 'Padrino.mount("Admin").to("/admin")', '/tmp/sample_project/config/apps.rb'
      assert_match_in_file 'class Admin < Padrino::Application', '/tmp/sample_project/admin/app.rb'
      assert_match_in_file 'role.project_module :accounts, "/accounts"', '/tmp/sample_project/admin/app.rb'
    end
  end
end