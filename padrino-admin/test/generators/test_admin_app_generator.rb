require File.dirname(__FILE__) + '/../helper'
require 'thor/group'
require 'fakeweb'
require 'padrino-gen/generators/actions'
Dir[File.dirname(__FILE__) + '/generators/{components}/**/*.rb'].each { |lib| require lib }

class TestAdminAppGenerator < Test::Unit::TestCase
  
  def setup
    `rm -rf /tmp/sample_project`
    @project = Padrino::Generators::Project.dup
    @admin   = Padrino::Generators::AdminApp.dup
  end

  context 'the admin app generator' do

    should 'fail outside app root' do
      output = silence_logger { @admin.start(['-r=/tmp/sample_project']) }
      assert_match(/not at the root/, output)
      assert_no_file_exists('/tmp/admin')
    end

    should 'fail if we don\'t an orm' do
      assert_nothing_raised { silence_logger { @project.start(['sample_project', '--root=/tmp']) } }
      assert_raise(SystemExit) { silence_logger { @admin.start(['-r=/tmp/sample_project']) } }
    end

    should 'fail if we don\'t avalid orm' do
      assert_nothing_raised { silence_logger { @project.start(['sample_project', '--root=/tmp', '-d=sequel']) } }
      assert_raise(SystemExit) { silence_logger { @admin.start(['-r=/tmp/sample_project']) } }
    end

    should 'correctyl generate a new padrino admin application' do
      assert_nothing_raised { silence_logger { @project.start(['sample_project', '--root=/tmp', '-d=activerecord']) } }
      assert_nothing_raised { silence_logger { @admin.start(['--root=/tmp/sample_project']) } }
      assert_file_exists('/tmp/sample_project')
      assert_file_exists('/tmp/sample_project/admin')
      assert_file_exists('/tmp/sample_project/admin/app.rb')
      assert_file_exists('/tmp/sample_project/admin/controllers')
      assert_file_exists('/tmp/sample_project/admin/controllers/accounts.rb')
      assert_file_exists('/tmp/sample_project/admin/controllers/base.rb')
      assert_file_exists('/tmp/sample_project/admin/controllers/javascripts.rb')
      assert_file_exists('/tmp/sample_project/admin/controllers/sessions.rb')
      assert_file_exists('/tmp/sample_project/admin/views')
      assert_file_exists('/tmp/sample_project/admin/views/accounts/_form.haml')
      assert_file_exists('/tmp/sample_project/admin/views/accounts/edit.haml')
      assert_file_exists('/tmp/sample_project/admin/views/accounts/grid.js.erb')
      assert_file_exists('/tmp/sample_project/admin/views/accounts/new.haml')
      assert_file_exists('/tmp/sample_project/admin/views/accounts/store.jml')
      assert_file_exists('/tmp/sample_project/admin/views/base/dashboard.haml')
      assert_file_exists('/tmp/sample_project/admin/views/base/index.haml')
      assert_file_exists('/tmp/sample_project/admin/views/javascripts/admin.js.erb')
      assert_file_exists('/tmp/sample_project/admin/views/javascripts/locale.js.erb')
      assert_file_exists('/tmp/sample_project/admin/views/sessions/new.haml')
      assert_file_exists('/tmp/sample_project/public/admin')
      assert_file_exists('/tmp/sample_project/public/admin/flash')
      assert_file_exists('/tmp/sample_project/public/admin/images')
      assert_file_exists('/tmp/sample_project/public/admin/javascripts')
      assert_file_exists('/tmp/sample_project/public/admin/stylesheets')
      assert_file_exists('/tmp/sample_project/app/models/account.rb')
      assert_file_exists('/tmp/sample_project/db/seeds.rb')
      assert_match_in_file "gem 'haml'", '/tmp/sample_project/Gemfile'
      assert_match_in_file 'Padrino.mount("Admin").to("/admin")', '/tmp/sample_project/config/apps.rb'
      assert_match_in_file 'class Admin < Padrino::Application', '/tmp/sample_project/admin/app.rb'
    end
  end
end
