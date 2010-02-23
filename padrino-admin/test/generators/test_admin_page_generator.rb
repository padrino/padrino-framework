require File.dirname(__FILE__) + '/../helper'
require 'thor/group'
require 'fakeweb'
require 'padrino-gen/generators/actions'
Dir[File.dirname(__FILE__) + '/generators/{components}/**/*.rb'].each { |lib| require lib }

class Person
  def self.properties
    [:id, :name, :age, :email].map { |c| OpenStruct.new(:name => c) }
  end
end

class TestAdminPageGenerator < Test::Unit::TestCase

  def setup
    `rm -rf /tmp/sample_project`
    @project = Padrino::Generators::Project.dup
    @admin   = Padrino::Generators::AdminApp.dup
    @page    = Padrino::Generators::AdminPage.dup
    @model   = Padrino::Generators::Model.dup
  end

  context 'the admin page generator' do
    
    should 'fail outside app root' do
      output = silence_logger { @page.start(['foo', '-r=/tmp/sample_project']) }
      assert_match(/not at the root/, output)
      assert_no_file_exists('/tmp/admin')
    end

    should 'fail without argument and model' do
      silence_logger { @project.start(['sample_project', '--root=/tmp', '-d=activerecord']) }
      silence_logger { @admin.start(['--root=/tmp/sample_project']) }
      assert_raise(Padrino::Admin::Generators::OrmError) { @page.start(['foo', '-r=/tmp/sample_project']) }
    end

    should 'correctyl generate a new padrino admin application' do
      'Person'.classify.constantize
      silence_logger { @project.start(['sample_project', '--root=/tmp', '-d=datamapper']) }
      silence_logger { @admin.start(['--root=/tmp/sample_project']) }
      silence_logger { @model.start(['person', "name:string", "age:integer", "email:string", '-root=/tmp/sample_project']) }
      silence_logger { @page.start(['person', '--root=/tmp/sample_project']) }
      assert_file_exists '/tmp/sample_project/admin/controllers/people.rb'
      assert_file_exists '/tmp/sample_project/admin/views/people/_form.erb'
      assert_file_exists '/tmp/sample_project/admin/views/people/edit.erb'
      assert_file_exists '/tmp/sample_project/admin/views/people/index.erb'
      assert_file_exists '/tmp/sample_project/admin/views/people/new.erb'
      %w(name age email).each do |field|
        assert_match_in_file "label :#{field}", '/tmp/sample_project/admin/views/people/_form.erb'
        assert_match_in_file "text_field :#{field}", '/tmp/sample_project/admin/views/people/_form.erb'
      end
      assert_match_in_file 'role.project_module :people, "/people"', '/tmp/sample_project/admin/app.rb'
    end
  end
end
