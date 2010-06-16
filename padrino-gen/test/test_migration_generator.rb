require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestMigrationGenerator < Test::Unit::TestCase
  def setup
    `rm -rf /tmp/sample_project`
  end

  context 'the migration generator' do
    should "fail outside app root" do
      output = silence_logger { generate(:migration, 'add_email_to_users', '-r=/tmp') }
      assert_match(/not at the root/, output)
      assert_no_file_exists('/tmp/db/migration')
    end

    should "fail if we don't use an adapter" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon') }
      assert_raise(SystemExit) { silence_logger { generate(:migration, 'AddEmailToUsers', '-r=/tmp/sample_project') } }
    end

    should "generate migration inside app root" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon', '-d=activerecord') }
      response_success = silence_logger { generate(:migration, 'AddEmailToUsers', '-r=/tmp/sample_project') }
      migration_file_path = "/tmp/sample_project/db/migrate/001_add_email_to_users.rb"
      assert_match_in_file(/class AddEmailToUser/m, migration_file_path)
    end

    should "generate migration inside app root with lowercase migration argument" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon', '-d=activerecord') }
      response_success = silence_logger { generate(:migration, 'add_email_to_users', '-r=/tmp/sample_project') }
      migration_file_path = "/tmp/sample_project/db/migrate/001_add_email_to_users.rb"
      assert_match_in_file(/class AddEmailToUsers/m, migration_file_path)
    end

    should "generate migration inside app root with singular table" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon', '-d=activerecord') }
      silence_logger { generate(:migration, 'add_email_to_user', "email:string", '-r=/tmp/sample_project') }
      migration_file_path = "/tmp/sample_project/db/migrate/001_add_email_to_user.rb"
      assert_match_in_file(/class AddEmailToUser/m, migration_file_path)
      assert_match_in_file(/t.string :email/, migration_file_path)
      assert_match_in_file(/t.remove :email/, migration_file_path)
    end

    should "properly calculate version number" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon', '-d=sequel') }
      silence_logger { generate(:migration, 'add_email_to_person', "email:string", '-r=/tmp/sample_project') }
      silence_logger { generate(:migration, 'add_name_to_person', "email:string", '-r=/tmp/sample_project') }
      silence_logger { generate(:migration, 'add_age_to_user', "email:string", '-r=/tmp/sample_project') }
      assert_match_in_file(/class AddEmailToPerson/m, "/tmp/sample_project/db/migrate/001_add_email_to_person.rb")
      assert_match_in_file(/class AddNameToPerson/m, "/tmp/sample_project/db/migrate/002_add_name_to_person.rb")
      assert_match_in_file(/class AddAgeToUser/m, "/tmp/sample_project/db/migrate/003_add_age_to_user.rb")
    end
  end

  context 'the migration generator for activerecord' do
    should "generate migration for generic needs" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon', '-d=activerecord') }
      response_success = silence_logger { generate(:migration, 'ModifyUserFields', '-r=/tmp/sample_project') }
      migration_file_path = "/tmp/sample_project/db/migrate/001_modify_user_fields.rb"
      assert_match_in_file(/class ModifyUserFields/m, migration_file_path)
      assert_match_in_file(/def self\.up\s+end/m, migration_file_path)
      assert_match_in_file(/def self\.down\s+end/m, migration_file_path)
    end

    should "generate migration for adding columns" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon', '-d=activerecord') }
      migration_params = ['AddEmailToUsers', "email:string", "age:integer", '-r=/tmp/sample_project']
      response_success = silence_logger { generate(:migration, *migration_params) }
      migration_file_path = "/tmp/sample_project/db/migrate/001_add_email_to_users.rb"
      assert_match_in_file(/class AddEmailToUsers/m, migration_file_path)
      assert_match_in_file(/change_table :users.*?t\.string :email/m, migration_file_path)
      assert_match_in_file(/t\.integer :age/m, migration_file_path)
      assert_match_in_file(/change_table :users.*?t\.remove :email/m, migration_file_path)
      assert_match_in_file(/t\.remove :age/m, migration_file_path)
    end

    should "generate migration for removing columns" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon', '-d=activerecord') }
      migration_params = ['RemoveEmailFromUsers', "email:string", "age:integer", '-r=/tmp/sample_project']
      response_success = silence_logger { generate(:migration, *migration_params) }
      migration_file_path = "/tmp/sample_project/db/migrate/001_remove_email_from_users.rb"
      assert_match_in_file(/class RemoveEmailFromUsers/m, migration_file_path)
      assert_match_in_file(/change_table :users.*?t\.remove :email/m, migration_file_path)
      assert_match_in_file(/t\.remove :age/m, migration_file_path)
      assert_match_in_file(/change_table :users.*?t\.string :email/m, migration_file_path)
      assert_match_in_file(/t\.integer :age/m, migration_file_path)
    end
  end

  context 'the migration generator for datamapper' do
    should "generate migration for generic needs" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon', '-d=datamapper') }
      response_success = silence_logger { generate(:migration, 'ModifyUserFields', '-r=/tmp/sample_project') }
      migration_file_path = "/tmp/sample_project/db/migrate/001_modify_user_fields.rb"
      assert_match_in_file(/migration\s1.*?:modify_user_fields/m, migration_file_path)
      assert_match_in_file(/up\sdo\s+end/m, migration_file_path)
      assert_match_in_file(/down\sdo\s+end/m, migration_file_path)
    end

    should "generate migration for adding columns" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon', '-d=datamapper') }
      migration_params = ['AddEmailToUsers', "email:string", "age:integer", '-r=/tmp/sample_project']
      response_success = silence_logger { generate(:migration, *migration_params) }
      migration_file_path = "/tmp/sample_project/db/migrate/001_add_email_to_users.rb"
      assert_match_in_file(/migration\s1.*?:add_email_to_users/m, migration_file_path)
      assert_match_in_file(/modify_table :users.*?add_column :email, DataMapper::Property::String/m, migration_file_path)
      assert_match_in_file(/add_column :age, DataMapper::Property::Integer/m, migration_file_path)
      assert_match_in_file(/modify_table :users.*?drop_column :email/m, migration_file_path)
      assert_match_in_file(/drop_column :age/m, migration_file_path)
    end

    should "generate migration for removing columns" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon', '-d=datamapper') }
      migration_params = ['RemoveEmailFromUsers', "email:string", "age:integer", '-r=/tmp/sample_project']
      response_success = silence_logger { generate(:migration, *migration_params) }
      migration_file_path = "/tmp/sample_project/db/migrate/001_remove_email_from_users.rb"
      assert_match_in_file(/migration\s1.*?:remove_email_from_users/m, migration_file_path)
      assert_match_in_file(/modify_table :users.*?drop_column :email/m, migration_file_path)
      assert_match_in_file(/drop_column :age/m, migration_file_path)
      assert_match_in_file(/modify_table :users.*?add_column :email, DataMapper::Property::String/m, migration_file_path)
      assert_match_in_file(/add_column :age, DataMapper::Property::Integer/m, migration_file_path)
    end

    should "properly version migration files" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon', '-d=datamapper') }
      response_success = silence_logger { generate(:migration, 'ModifyUserFields', '-r=/tmp/sample_project') }
      response_success = silence_logger { generate(:migration, 'ModifyUserFields2', '-r=/tmp/sample_project') }
      response_success = silence_logger { generate(:migration, 'ModifyUserFields3', '-r=/tmp/sample_project') }
      assert_match_in_file(/migration\s1.*?:modify_user_fields/m, "/tmp/sample_project/db/migrate/001_modify_user_fields.rb")
      assert_match_in_file(/migration\s2.*?:modify_user_fields2/m, "/tmp/sample_project/db/migrate/002_modify_user_fields2.rb")
      assert_match_in_file(/migration\s3.*?:modify_user_fields3/m, "/tmp/sample_project/db/migrate/003_modify_user_fields3.rb")
    end
  end

  context 'the migration generator for sequel' do
    should "generate migration for generic needs" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon', '-d=sequel') }
      response_success = silence_logger { generate(:migration, 'ModifyUserFields', '-r=/tmp/sample_project') }
      migration_file_path = "/tmp/sample_project/db/migrate/001_modify_user_fields.rb"
      assert_match_in_file(/class ModifyUserFields/m, migration_file_path)
      assert_match_in_file(/def\sup\s+end/m, migration_file_path)
      assert_match_in_file(/def\sdown\s+end/m, migration_file_path)
    end

    should "generate migration for adding columns" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon', '-d=sequel') }
      migration_params = ['AddEmailToUsers', "email:string", "age:integer", '-r=/tmp/sample_project']
      response_success = silence_logger { generate(:migration, *migration_params) }
      migration_file_path = "/tmp/sample_project/db/migrate/001_add_email_to_users.rb"
      assert_match_in_file(/class AddEmailToUsers/m, migration_file_path)
      assert_match_in_file(/alter_table :users.*?add_column :email, String/m, migration_file_path)
      assert_match_in_file(/add_column :age, Integer/m, migration_file_path)
      assert_match_in_file(/alter_table :users.*?drop_column :email/m, migration_file_path)
      assert_match_in_file(/drop_column :age/m, migration_file_path)
    end

    should "generate migration for removing columns" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon', '-d=sequel') }
      migration_params = ['RemoveEmailFromUsers', "email:string", "age:integer", '-r=/tmp/sample_project']
      response_success = silence_logger { generate(:migration, *migration_params) }
      migration_file_path = "/tmp/sample_project/db/migrate/001_remove_email_from_users.rb"
      assert_match_in_file(/class RemoveEmailFromUsers/m, migration_file_path)
      assert_match_in_file(/alter_table :users.*?drop_column :email/m, migration_file_path)
      assert_match_in_file(/drop_column :age/m, migration_file_path)
      assert_match_in_file(/alter_table :users.*?add_column :email, String/m, migration_file_path)
      assert_match_in_file(/add_column :age, Integer/m, migration_file_path)
    end
  end

  context "the migration destroy option" do

    should "destroy the migration files" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon', '-d=sequel') }
      migration_params = ['RemoveEmailFromUsers', "email:string", "age:integer", '-r=/tmp/sample_project']
      silence_logger { generate(:migration, *migration_params) }
      silence_logger { generate(:migration, 'RemoveEmailFromUsers', '-r=/tmp/sample_project','-d') }
      assert_no_file_exists("/tmp/sample_project/db/migrate/001_remove_email_from_users.rb")
    end

    should "destroy the migration file regardless of number" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon', '-d=sequel') }
      migration_params = ['RemoveEmailFromUsers', "email:string", "age:integer", '-r=/tmp/sample_project']
      migration_param2 = ['AddEmailFromUsers', "email:string", "age:integer", '-r=/tmp/sample_project']
      silence_logger { generate(:migration, *migration_param2) }
      silence_logger { generate(:migration, *migration_params) }
      silence_logger { generate(:migration, 'RemoveEmailFromUsers', '-r=/tmp/sample_project','-d') }
      assert_no_file_exists("/tmp/sample_project/db/migrate/002_remove_email_from_users.rb")
    end
  end
end