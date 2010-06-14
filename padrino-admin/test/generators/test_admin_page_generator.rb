require File.expand_path(File.dirname(__FILE__) + '/../helper')

class Person
  def self.properties
    [:id, :name, :age, :email].map { |c| OpenStruct.new(:name => c) }
  end
end

class Page
  def self.properties
    [:id, :name, :body].map { |c| OpenStruct.new(:name => c) }
  end
end

class TestAdminPageGenerator < Test::Unit::TestCase

  def setup
    `rm -rf /tmp/sample_project`
  end

  context 'the admin page generator' do

    should 'fail outside app root' do
      output = silence_logger { generate(:admin_page, 'foo', '-r=/tmp/sample_project') }
      assert_match(/not at the root/, output)
      assert_no_file_exists('/tmp/admin')
    end

    should 'fail without argument and model' do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '-d=activerecord') }
      silence_logger { generate(:admin_app, '--root=/tmp/sample_project') }
      assert_raise(Padrino::Admin::Generators::OrmError) { generate(:admin_page, 'foo', '-r=/tmp/sample_project') }
    end

    should 'correctly generate a new padrino admin application default renderer' do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '-d=datamapper','-e=haml') }
      silence_logger { generate(:admin_app, '--root=/tmp/sample_project') }
      silence_logger { generate(:model, 'person', "name:string", "age:integer", "email:string", '-root=/tmp/sample_project') }
      silence_logger { generate(:admin_page, 'person', '--root=/tmp/sample_project') }
      assert_file_exists '/tmp/sample_project/admin/controllers/people.rb'
      assert_file_exists '/tmp/sample_project/admin/views/people/_form.haml'
      assert_file_exists '/tmp/sample_project/admin/views/people/edit.haml'
      assert_file_exists '/tmp/sample_project/admin/views/people/index.haml'
      assert_file_exists '/tmp/sample_project/admin/views/people/new.haml'
      %w(name age email).each do |field|
        assert_match_in_file "label :#{field}", '/tmp/sample_project/admin/views/people/_form.haml'
        assert_match_in_file "text_field :#{field}", '/tmp/sample_project/admin/views/people/_form.haml'
      end
      assert_match_in_file 'role.project_module :people, "/people"', '/tmp/sample_project/admin/app.rb'
    end

    should 'correctly generate a new padrino admin application with erb renderer' do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '-d=datamapper', '-e=erb') }
      silence_logger { generate(:admin_app, '--root=/tmp/sample_project') }
      silence_logger { generate(:model, 'person', "name:string", "age:integer", "email:string", '-root=/tmp/sample_project') }
      silence_logger { generate(:admin_page, 'person', '--root=/tmp/sample_project') }
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

    should 'correctly generate a new padrino admin application with multiple models' do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '-d=datamapper','-e=haml') }
      silence_logger { generate(:admin_app, '--root=/tmp/sample_project') }
      silence_logger { generate(:model, 'person', "name:string", "age:integer", "email:string", '-root=/tmp/sample_project') }
      silence_logger { generate(:model, 'page', "name:string", "body:string", '-root=/tmp/sample_project') }
      silence_logger { generate(:admin_page, 'person', 'page', '--root=/tmp/sample_project') }
      # For Person
      assert_file_exists '/tmp/sample_project/admin/controllers/people.rb'
      assert_file_exists '/tmp/sample_project/admin/views/people/_form.haml'
      assert_file_exists '/tmp/sample_project/admin/views/people/edit.haml'
      assert_file_exists '/tmp/sample_project/admin/views/people/index.haml'
      assert_file_exists '/tmp/sample_project/admin/views/people/new.haml'
      %w(name age email).each do |field|
        assert_match_in_file "label :#{field}", '/tmp/sample_project/admin/views/people/_form.haml'
        assert_match_in_file "text_field :#{field}", '/tmp/sample_project/admin/views/people/_form.haml'
      end
      assert_match_in_file 'role.project_module :people, "/people"', '/tmp/sample_project/admin/app.rb'
      # For Page
      assert_file_exists '/tmp/sample_project/admin/controllers/pages.rb'
      assert_file_exists '/tmp/sample_project/admin/views/pages/_form.haml'
      assert_file_exists '/tmp/sample_project/admin/views/pages/edit.haml'
      assert_file_exists '/tmp/sample_project/admin/views/pages/index.haml'
      assert_file_exists '/tmp/sample_project/admin/views/pages/new.haml'
      %w(name body).each do |field|
        assert_match_in_file "label :#{field}", '/tmp/sample_project/admin/views/pages/_form.haml'
        assert_match_in_file "text_field :#{field}", '/tmp/sample_project/admin/views/pages/_form.haml'
      end
      assert_match_in_file 'role.project_module :pages, "/pages"', '/tmp/sample_project/admin/app.rb'
    end
  end
end
