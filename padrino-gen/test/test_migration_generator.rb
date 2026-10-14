require_relative 'helper'

describe 'MigrationGenerator' do
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{SecureRandom.hex}"
    `mkdir -p #{@apptmp}`
  end

  def teardown
    `rm -rf #{@apptmp}`
  end

  describe 'the migration generator' do
    it 'should fail outside app root' do
      out, = capture_io { generate(:migration, 'add_email_to_users', '-r=/tmp') }
      assert_match(/not at the root/, out)
      assert_no_file_exists("#{@apptmp}/db/migrate")
    end

    it 'should fail with NameError if given invalid namespace names' do
      capture_io { generate(:project, 'sample', "--root=#{@apptmp}") }
      assert_raises(::NameError) { capture_io { generate(:migration, 'wrong/name', "--root=#{@apptmp}/sample") } }
    end

    it 'should fail if we do not use an adapter' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      assert_raises(SystemExit) { capture_io { generate(:migration, 'AddEmailToUsers', "-r=#{@apptmp}/sample_project") } }
    end

    it 'should generate migration inside app root' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
      capture_io { generate(:migration, 'AddEmailToUsers', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_add_email_to_users.rb"
      assert_match_in_file(/class AddEmailToUser/m, migration_file_path)
    end

    it 'should generate migration inside app root with lowercase migration argument' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
      capture_io { generate(:migration, 'add_email_to_users', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_add_email_to_users.rb"
      assert_match_in_file(/class AddEmailToUsers/m, migration_file_path)
    end

    it 'should generate migration inside app root with singular table' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
      capture_io { generate(:migration, 'add_email_to_user', 'email:string', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_add_email_to_user.rb"
      assert_match_in_file(/class AddEmailToUser/m, migration_file_path)
      assert_match_in_file(/t.string :email/, migration_file_path)
      assert_match_in_file(/t.remove :email/, migration_file_path)
    end

    describe 'the default migration numbering' do
      it 'should properly calculate version number' do
        capture_io { generate(:project, 'sample_project', '--migration_format=number', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=sequel') }
        capture_io { generate(:migration, 'add_email_to_person', 'email:string', "-r=#{@apptmp}/sample_project") }
        capture_io { generate(:migration, 'add_name_to_person', 'email:string', "-r=#{@apptmp}/sample_project") }
        capture_io { generate(:migration, 'add_age_to_user', 'email:string', "-r=#{@apptmp}/sample_project") }
        assert_match_in_file(/Sequel\.migration do/m, "#{@apptmp}/sample_project/db/migrate/001_add_email_to_person.rb")
        assert_match_in_file(/Sequel\.migration do/m, "#{@apptmp}/sample_project/db/migrate/002_add_name_to_person.rb")
        assert_match_in_file(/Sequel\.migration do/m, "#{@apptmp}/sample_project/db/migrate/003_add_age_to_user.rb")
      end
    end

    describe 'the timestamped migration numbering' do
      it 'should properly calculate version number' do
        capture_io { generate(:project, 'sample_project', '--migration_format=timestamp', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=sequel') }

        time = stop_time_for_test.utc.strftime('%Y%m%d%H%M%S')

        capture_io { generate(:migration, 'add_gender_to_person', 'gender:string', "-r=#{@apptmp}/sample_project") }
        assert_match_in_file(/Sequel\.migration do/m, "#{@apptmp}/sample_project/db/migrate/#{time}_add_gender_to_person.rb")
      end
    end

    describe 'the migration argument' do
      it 'should properly extract a table name from argument' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
        capture_io { generate(:migration, 'AddAuthenticityTokenFieldsToUsers', 'authentity_token:string', "-r=#{@apptmp}/sample_project") }
        capture_io { generate(:migration, 'AddEmailToTokyo', 'email:string', "-r=#{@apptmp}/sample_project") }
        capture_io { generate(:migration, 'AddLocationTofoo', 'location:string', "-r=#{@apptmp}/sample_project") }
        migration_file_path1 = "#{@apptmp}/sample_project/db/migrate/001_add_authenticity_token_fields_to_users.rb"
        migration_file_path2 = "#{@apptmp}/sample_project/db/migrate/002_add_email_to_tokyo.rb"
        migration_file_path3 = "#{@apptmp}/sample_project/db/migrate/003_add_location_tofoo.rb"
        assert_match_in_file(/change_table :users/, migration_file_path1)
        assert_match_in_file(/change_table :tokyo/, migration_file_path2)
        assert_match_in_file(/change_table :foos/, migration_file_path3)
      end
    end
  end

  describe 'the migration generator for activerecord' do
    before do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
    end

    it 'should generate migration for generic needs' do
      capture_io { generate(:migration, 'ModifyUserFields', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_modify_user_fields.rb"
      assert_match_in_file(/class ModifyUserFields/m, migration_file_path)
      assert_match_in_file(/def self\.up\s+end/m, migration_file_path)
      assert_match_in_file(/def self\.down\s+end/m, migration_file_path)
    end

    it 'should generate migration for adding columns' do
      migration_params = ['AddEmailToUsers', 'email:string', 'age:integer', "-r=#{@apptmp}/sample_project"]
      capture_io { generate(:migration, *migration_params) }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_add_email_to_users.rb"
      assert_match_in_file(/class AddEmailToUsers/m, migration_file_path)
      assert_match_in_file(/change_table :users.*?t\.string :email/m, migration_file_path)
      assert_match_in_file(/t\.integer :age/m, migration_file_path)
      assert_match_in_file(/change_table :users.*?t\.remove :email/m, migration_file_path)
      assert_match_in_file(/t\.remove :age/m, migration_file_path)
    end

    it 'should generate migration for removing columns' do
      migration_params = ['RemoveEmailFromUsers', 'email:string', 'age:integer', "-r=#{@apptmp}/sample_project"]
      capture_io { generate(:migration, *migration_params) }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_remove_email_from_users.rb"
      assert_match_in_file(/class RemoveEmailFromUsers/m, migration_file_path)
      assert_match_in_file(/change_table :users.*?t\.remove :email/m, migration_file_path)
      assert_match_in_file(/t\.remove :age/m, migration_file_path)
      assert_match_in_file(/change_table :users.*?t\.string :email/m, migration_file_path)
      assert_match_in_file(/t\.integer :age/m, migration_file_path)
    end

    it 'should remove references with remove_references' do
      capture_io { generate(:migration, 'AddUserToOrders', 'user:references', 'account:belongs_to', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_add_user_to_orders.rb"
      assert_match_in_file(/def self\.up\s+change_table :orders do \|t\|\s+t\.references :user\s+t\.belongs_to :account\s+end/m, migration_file_path)
      assert_match_in_file(/def self\.down\s+change_table :orders do \|t\|\s+t\.remove_references :user\s+t\.remove_references :account\s+end/m, migration_file_path)
    end

    it 'should add references when rolling back a migration removing them' do
      capture_io { generate(:migration, 'RemoveUserFromOrders', 'user:references', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_remove_user_from_orders.rb"
      assert_match_in_file(/def self\.up\s+change_table :orders do \|t\|\s+t\.remove_references :user\s+end/m, migration_file_path)
      assert_match_in_file(/def self\.down\s+change_table :orders do \|t\|\s+t\.references :user\s+end/m, migration_file_path)
    end

    it 'should add an index for a third index or uniq segment' do
      migration_params = ['AddUserIdToOrders', 'user_id:integer:index', 'code:string:uniq', 'note:string', "-r=#{@apptmp}/sample_project"]
      capture_io { generate(:migration, *migration_params) }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_add_user_id_to_orders.rb"
      up = /def self\.up\s+change_table :orders do \|t\|\s+t\.integer :user_id\s+t\.index :user_id\s+t\.string :code\s+t\.index :code, unique: true\s+t\.string :note\s+end/m
      assert_match_in_file(up, migration_file_path)
      assert_match_in_file(/def self\.down\s+change_table :orders do \|t\|\s+t\.remove :user_id\s+t\.remove :code\s+t\.remove :note\s+end/m, migration_file_path)
    end

    it 'should pass a third index or uniq segment to references' do
      capture_io { generate(:migration, 'AddUserToOrders', 'user:references:uniq', 'account:references:index', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_add_user_to_orders.rb"
      assert_match_in_file(/t\.references :user, index: \{ unique: true \}\n/, migration_file_path)
      assert_match_in_file(/t\.references :account, index: true\n/, migration_file_path)
      assert_match_in_file(/t\.remove_references :user\n/, migration_file_path)
    end
  end

  describe 'the migration generator for sequel' do
    before do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=sequel') }
    end

    it 'should generate migration for generic needs' do
      capture_io { generate(:migration, 'ModifyUserFields', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_modify_user_fields.rb"
      assert_match_in_file(/Sequel\.migration/m, migration_file_path)
      assert_match_in_file(/up do\s+end/m, migration_file_path)
      assert_match_in_file(/down do\s+end/m, migration_file_path)
    end

    it 'should generate migration for adding columns' do
      migration_params = ['AddEmailToUsers', 'email:string', 'age:integer', "-r=#{@apptmp}/sample_project"]
      capture_io { generate(:migration, *migration_params) }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_add_email_to_users.rb"
      assert_match_in_file(/Sequel\.migration/m, migration_file_path)
      assert_match_in_file(/alter_table :users.*?add_column :email, String/m, migration_file_path)
      assert_match_in_file(/add_column :age, Integer/m, migration_file_path)
      assert_match_in_file(/alter_table :users.*?drop_column :email/m, migration_file_path)
      assert_match_in_file(/drop_column :age/m, migration_file_path)
    end

    it 'should generate migration for removing columns' do
      migration_params = ['RemoveEmailFromUsers', 'email:string', 'age:integer', "-r=#{@apptmp}/sample_project"]
      capture_io { generate(:migration, *migration_params) }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_remove_email_from_users.rb"
      assert_match_in_file(/Sequel\.migration/m, migration_file_path)
      assert_match_in_file(/alter_table :users.*?drop_column :email/m, migration_file_path)
      assert_match_in_file(/drop_column :age/m, migration_file_path)
      assert_match_in_file(/alter_table :users.*?add_column :email, String/m, migration_file_path)
      assert_match_in_file(/add_column :age, Integer/m, migration_file_path)
    end
  end

  describe 'the migration destroy option' do
    before do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=sequel') }
      @migration_params = ['RemoveEmailFromUsers', 'email:string', 'age:integer', "-r=#{@apptmp}/sample_project"]
    end

    it 'should destroy the migration files' do
      capture_io { generate(:migration, *@migration_params) }
      capture_io { generate(:migration, 'RemoveEmailFromUsers', "-r=#{@apptmp}/sample_project", '-d') }
      assert_no_file_exists("#{@apptmp}/sample_project/db/migrate/001_remove_email_from_users.rb")
    end

    it 'should destroy the migration file regardless of number' do
      migration_param2 = ['AddEmailFromUsers', 'email:string', 'age:integer', "-r=#{@apptmp}/sample_project"]
      capture_io { generate(:migration, *migration_param2) }
      capture_io { generate(:migration, *@migration_params) }
      capture_io { generate(:migration, 'RemoveEmailFromUsers', "-r=#{@apptmp}/sample_project", '-d') }
      assert_no_file_exists("#{@apptmp}/sample_project/db/migrate/002_remove_email_from_users.rb")
    end
  end
end
