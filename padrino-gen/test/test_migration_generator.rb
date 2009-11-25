require File.dirname(__FILE__) + '/helper'
require 'thor'

class TestMigrationGenerator < Test::Unit::TestCase
  def setup
    @skeleton = Padrino::Generators::Skeleton.dup
    @mig_gen  = Padrino::Generators::Migration.dup
    `rm -rf /tmp/sample_app`
  end

  context 'the migration generator' do
    should "fail outside app root" do
      output = silence_logger { @mig_gen.start(['add_email_to_users', '-r=/tmp']) }
      assert_match(/not at the root/, output)
      assert_no_file_exists('/tmp/db/migration')
    end

    should "generate migration inside app root" do
      current_time = stop_time_for_test.strftime("%Y%m%d%H%M%S")
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=bacon', '-d=activerecord']) }
      response_success = silence_logger { @mig_gen.start(['AddEmailToUsers', '-r=/tmp/sample_app']) }
      migration_file_path = "/tmp/sample_app/db/migrate/#{current_time}_add_email_to_users.rb"
      assert_match_in_file(/class AddEmailToUser/m, migration_file_path)
    end

    should "generate migration inside app root with lowercase migration argument" do
      current_time = stop_time_for_test.strftime("%Y%m%d%H%M%S")
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=bacon', '-d=activerecord']) }
      response_success = silence_logger { @mig_gen.start(['add_email_to_users', '-r=/tmp/sample_app']) }
      migration_file_path = "/tmp/sample_app/db/migrate/#{current_time}_add_email_to_users.rb"
      assert_match_in_file(/class AddEmailToUsers/m, migration_file_path)
    end

    should "generate migration inside app root with singular table" do
      current_time = stop_time_for_test.strftime("%Y%m%d%H%M%S")
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=bacon', '-d=activerecord']) }
      response_success = silence_logger { @mig_gen.start(['add_email_to_user', "email:string", '-r=/tmp/sample_app']) }
      migration_file_path = "/tmp/sample_app/db/migrate/#{current_time}_add_email_to_user.rb"
      assert_match_in_file(/class AddEmailToUser/m, migration_file_path)
      assert_match_in_file(/t.column :email, :string/, migration_file_path)
      assert_match_in_file(/t.remove :email/, migration_file_path)
    end
  end

  context 'the migration generator for activerecord' do
    should "generate migration for generic needs" do
      current_time = stop_time_for_test.strftime("%Y%m%d%H%M%S")
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=bacon', '-d=activerecord']) }
      response_success = silence_logger { @mig_gen.start(['ModifyUserFields', '-r=/tmp/sample_app']) }
      migration_file_path = "/tmp/sample_app/db/migrate/#{current_time}_modify_user_fields.rb"
      assert_match_in_file(/class ModifyUserFields/m, migration_file_path)
      assert_match_in_file(/def self\.up\s+end/m, migration_file_path)
      assert_match_in_file(/def self\.down\s+end/m, migration_file_path)
    end
    should "generate migration for adding columns" do
      current_time = stop_time_for_test.strftime("%Y%m%d%H%M%S")
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=bacon', '-d=activerecord']) }
      migration_params = ['AddEmailToUsers', "email:string", "age:integer", '-r=/tmp/sample_app']
      response_success = silence_logger { @mig_gen.start(migration_params) }
      migration_file_path = "/tmp/sample_app/db/migrate/#{current_time}_add_email_to_users.rb"
      assert_match_in_file(/class AddEmailToUsers/m, migration_file_path)
      assert_match_in_file(/change_table :users.*?t\.column :email, :string/m, migration_file_path)
      assert_match_in_file(/t\.column :age, :integer/m, migration_file_path)
      assert_match_in_file(/change_table :users.*?t\.remove :email/m, migration_file_path)
      assert_match_in_file(/t\.remove :age/m, migration_file_path)
    end
    should "generate migration for removing columns" do
      current_time = stop_time_for_test.strftime("%Y%m%d%H%M%S")
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=bacon', '-d=activerecord']) }
      migration_params = ['RemoveEmailFromUsers', "email:string", "age:integer", '-r=/tmp/sample_app']
      response_success = silence_logger { @mig_gen.start(migration_params) }
      migration_file_path = "/tmp/sample_app/db/migrate/#{current_time}_remove_email_from_users.rb"
      assert_match_in_file(/class RemoveEmailFromUsers/m, migration_file_path)
      assert_match_in_file(/change_table :users.*?t\.remove :email/m, migration_file_path)
      assert_match_in_file(/t\.remove :age/m, migration_file_path)
      assert_match_in_file(/change_table :users.*?t\.column :email, :string/m, migration_file_path)
      assert_match_in_file(/t\.column :age, :integer/m, migration_file_path)
    end
  end

  context 'the migration generator for datamapper' do
    should "generate migration for generic needs" do
      current_time = stop_time_for_test.strftime("%Y%m%d%H%M%S")
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=bacon', '-d=datamapper']) }
      response_success = silence_logger { @mig_gen.start(['ModifyUserFields', '-r=/tmp/sample_app']) }
      migration_file_path = "/tmp/sample_app/db/migrate/#{current_time}_modify_user_fields.rb"
      assert_match_in_file(/migration.*?:modify_user_fields/m, migration_file_path)
      assert_match_in_file(/up\sdo\s+end/m, migration_file_path)
      assert_match_in_file(/down\sdo\s+end/m, migration_file_path)
    end
    should "generate migration for adding columns" do
      current_time = stop_time_for_test.strftime("%Y%m%d%H%M%S")
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=bacon', '-d=datamapper']) }
      migration_params = ['AddEmailToUsers', "email:string", "age:integer", '-r=/tmp/sample_app']
      response_success = silence_logger { @mig_gen.start(migration_params) }
      migration_file_path = "/tmp/sample_app/db/migrate/#{current_time}_add_email_to_users.rb"
      assert_match_in_file(/migration.*?:add_email_to_users/m, migration_file_path)
      assert_match_in_file(/modify_table :users.*?add_column :email, String/m, migration_file_path)
      assert_match_in_file(/add_column :age, Integer/m, migration_file_path)
      assert_match_in_file(/modify_table :users.*?drop_column :email/m, migration_file_path)
      assert_match_in_file(/drop_column :age/m, migration_file_path)
    end
    should "generate migration for removing columns" do
      current_time = stop_time_for_test.strftime("%Y%m%d%H%M%S")
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=bacon', '-d=datamapper']) }
      migration_params = ['RemoveEmailFromUsers', "email:string", "age:integer", '-r=/tmp/sample_app']
      response_success = silence_logger { @mig_gen.start(migration_params) }
      migration_file_path = "/tmp/sample_app/db/migrate/#{current_time}_remove_email_from_users.rb"
      assert_match_in_file(/migration.*?:remove_email_from_users/m, migration_file_path)
      assert_match_in_file(/modify_table :users.*?drop_column :email/m, migration_file_path)
      assert_match_in_file(/drop_column :age/m, migration_file_path)
      assert_match_in_file(/modify_table :users.*?add_column :email, String/m, migration_file_path)
      assert_match_in_file(/add_column :age, Integer/m, migration_file_path)
    end
  end

  context 'the migration generator for sequel' do
    should "generate migration for generic needs" do
      current_time = stop_time_for_test.strftime("%Y%m%d%H%M%S")
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=bacon', '-d=sequel']) }
      response_success = silence_logger { @mig_gen.start(['ModifyUserFields', '-r=/tmp/sample_app']) }
      migration_file_path = "/tmp/sample_app/db/migrate/#{current_time}_modify_user_fields.rb"
      assert_match_in_file(/class ModifyUserFields/m, migration_file_path)
      assert_match_in_file(/def\sup\s+end/m, migration_file_path)
      assert_match_in_file(/def\sdown\s+end/m, migration_file_path)
    end
    should "generate migration for adding columns" do
      current_time = stop_time_for_test.strftime("%Y%m%d%H%M%S")
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=bacon', '-d=sequel']) }
      migration_params = ['AddEmailToUsers', "email:string", "age:integer", '-r=/tmp/sample_app']
      response_success = silence_logger { @mig_gen.start(migration_params) }
      migration_file_path = "/tmp/sample_app/db/migrate/#{current_time}_add_email_to_users.rb"
      assert_match_in_file(/class AddEmailToUsers/m, migration_file_path)
      assert_match_in_file(/alter_table :users.*?add_column :email, String/m, migration_file_path)
      assert_match_in_file(/add_column :age, Integer/m, migration_file_path)
      assert_match_in_file(/alter_table :users.*?drop_column :email/m, migration_file_path)
      assert_match_in_file(/drop_column :age/m, migration_file_path)
    end
    should "generate migration for removing columns" do
      current_time = stop_time_for_test.strftime("%Y%m%d%H%M%S")
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=bacon', '-d=sequel']) }
      migration_params = ['RemoveEmailFromUsers', "email:string", "age:integer", '-r=/tmp/sample_app']
      response_success = silence_logger { @mig_gen.start(migration_params) }
      migration_file_path = "/tmp/sample_app/db/migrate/#{current_time}_remove_email_from_users.rb"
      assert_match_in_file(/class RemoveEmailFromUsers/m, migration_file_path)
      assert_match_in_file(/alter_table :users.*?drop_column :email/m, migration_file_path)
      assert_match_in_file(/drop_column :age/m, migration_file_path)
      assert_match_in_file(/alter_table :users.*?add_column :email, String/m, migration_file_path)
      assert_match_in_file(/add_column :age, Integer/m, migration_file_path)
    end
  end
end
