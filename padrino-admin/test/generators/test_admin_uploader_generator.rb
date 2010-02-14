require File.dirname(__FILE__) + '/../helper'
require 'thor/group'
require 'fakeweb'
require 'padrino-gen/generators/actions'
Dir[File.dirname(__FILE__) + '/generators/{components}/**/*.rb'].each { |lib| require lib }

class TestAdminUploaderGenerator < Test::Unit::TestCase
  
  def setup
    `rm -rf /tmp/sample_project`
    @project  = Padrino::Generators::Project.dup
    @admin    = Padrino::Generators::AdminApp.dup
    @uploader = Padrino::Generators::AdminUploader.dup
  end

  context 'the admin uploader generator' do

    should 'fail outside app root' do
      output = silence_logger { @uploader.start(['-r=/tmp/sample_project']) }
      assert_match(/not at the root/, output)
      assert_no_file_exists('/tmp/admin')
    end

    should 'fail if we don\'t have admin application' do
      assert_nothing_raised { silence_logger { @project.start(['sample_project', '--root=/tmp']) } }
      assert_raise(SystemExit) { silence_logger { @uploader.start(['-r=/tmp/sample_project']) } }
    end

    should 'correctyl generate a new padrino admin application for activerecord' do
      assert_nothing_raised { silence_logger { @project.start(['sample_project', '--root=/tmp', '-d=activerecord']) } }
      assert_nothing_raised { silence_logger { @admin.start(['--root=/tmp/sample_project']) } }
      assert_nothing_raised { silence_logger { @uploader.start(['--root=/tmp/sample_project']) } }
      assert_file_exists '/tmp/sample_project/admin/controllers/uploads.rb'
      assert_file_exists '/tmp/sample_project/admin/views/uploads/grid.js.erb'
      assert_file_exists '/tmp/sample_project/admin/views/uploads/store.jml'
      assert_file_exists '/tmp/sample_project/lib/uploader.rb'
      assert_match_in_file 'mount_uploader :file, Uploader', '/tmp/sample_project/app/models/upload.rb'
      assert_match_in_file "\n# Uploader requirements\n# gem 'mini_magick'\ngem 'carrierwave'\n", "/tmp/sample_project/Gemfile"
      assert_match_in_file "role.project_module :uploads, \"/admin/uploads.js\"", '/tmp/sample_project/admin/app.rb'
    end

    should 'correctyl generate a new padrino admin application for datamapper' do
      assert_nothing_raised { silence_logger { @project.start(['sample_project', '--root=/tmp', '-d=datamapper']) } }
      assert_nothing_raised { silence_logger { @admin.start(['--root=/tmp/sample_project']) } }
      assert_nothing_raised { silence_logger { @uploader.start(['--root=/tmp/sample_project']) } }
      assert_file_exists '/tmp/sample_project/admin/controllers/uploads.rb'
      assert_file_exists '/tmp/sample_project/admin/views/uploads/grid.js.erb'
      assert_file_exists '/tmp/sample_project/admin/views/uploads/store.jml'
      assert_file_exists '/tmp/sample_project/lib/uploader.rb'
      assert_match_in_file 'property :file, String, :auto_validation => false', '/tmp/sample_project/app/models/upload.rb'
      assert_match_in_file 'mount_uploader :file, Uploader', '/tmp/sample_project/app/models/upload.rb'
      assert_match_in_file "\n# Uploader requirements\n# gem 'mini_magick'\ngem 'carrierwave'\n", "/tmp/sample_project/Gemfile"
      assert_match_in_file "role.project_module :uploads, \"/admin/uploads.js\"", '/tmp/sample_project/admin/app.rb'
    end
  end
end
