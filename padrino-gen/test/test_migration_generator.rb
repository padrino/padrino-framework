require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "MigrationGenerator" do
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{SecureRandom.hex}"
    `mkdir -p #{@apptmp}`
  end

  def teardown
    `rm -rf #{@apptmp}`
  end

  describe 'the migration generator' do
    it 'should fail outside app root' do
      out, err = capture_io { generate(:migration, 'add_email_to_users', '-r=/tmp') }
      assert_match(/not at the root/, out)
      assert_no_file_exists("#{@apptmp}/db/migrate")
    end

    it 'should fail with NameError if given invalid namespace names' do
      capture_io { generate(:project, "sample", "--root=#{@apptmp}") }
      assert_raises(::NameError) { capture_io { generate(:migration, "wrong/name", "--root=#{@apptmp}/sample") } }
    end

    it 'should fail if we do not use an adapter' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      assert_raises(SystemExit) { capture_io { generate(:migration, 'AddEmailToUsers', "-r=#{@apptmp}/sample_project") } }
    end

    it 'should generate migration inside app root' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
      response_success = capture_io { generate(:migration, 'AddEmailToUsers', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_add_email_to_users.rb"
      assert_match_in_file(/class AddEmailToUser/m, migration_file_path)
    end

    it 'should generate migration inside app root with lowercase migration argument' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
      response_success = capture_io { generate(:migration, 'add_email_to_users', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_add_email_to_users.rb"
      assert_match_in_file(/class AddEmailToUsers/m, migration_file_path)
    end

    it 'should generate migration inside app root with singular table' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
      capture_io { generate(:migration, 'add_email_to_user', "email:string", "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_add_email_to_user.rb"
      assert_match_in_file(/class AddEmailToUser/m, migration_file_path)
      assert_match_in_file(/t.string :email/, migration_file_path)
      assert_match_in_file(/t.remove :email/, migration_file_path)
    end

    describe "the default migration numbering" do
      it 'should properly calculate version number' do
        capture_io { generate(:project, 'sample_project', '--migration_format=number', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=sequel') }
        capture_io { generate(:migration, 'add_email_to_person', "email:string", "-r=#{@apptmp}/sample_project") }
        capture_io { generate(:migration, 'add_name_to_person', "email:string", "-r=#{@apptmp}/sample_project") }
        capture_io { generate(:migration, 'add_age_to_user', "email:string", "-r=#{@apptmp}/sample_project") }
        assert_match_in_file(/Sequel\.migration do/m, "#{@apptmp}/sample_project/db/migrate/001_add_email_to_person.rb")
        assert_match_in_file(/Sequel\.migration do/m, "#{@apptmp}/sample_project/db/migrate/002_add_name_to_person.rb")
        assert_match_in_file(/Sequel\.migration do/m, "#{@apptmp}/sample_project/db/migrate/003_add_age_to_user.rb")
      end
    end

    describe "the timestamped migration numbering" do
      it 'should properly calculate version number' do
        capture_io { generate(:project, 'sample_project', '--migration_format=timestamp', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=sequel') }

        time = stop_time_for_test.utc.strftime("%Y%m%d%H%M%S")

        capture_io { generate(:migration, 'add_gender_to_person', "gender:string", "-r=#{@apptmp}/sample_project") }
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
        assert_match_in_file(/change_table :foos/,   migration_file_path3)
      end
    end
  end

  describe 'the migration generator for activerecord' do
    before do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
    end

    it 'should generate migration for generic needs' do
      response_success = capture_io { generate(:migration, 'ModifyUserFields', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_modify_user_fields.rb"
      assert_match_in_file(/class ModifyUserFields/m, migration_file_path)
      assert_match_in_file(/def self\.up\s+end/m, migration_file_path)
      assert_match_in_file(/def self\.down\s+end/m, migration_file_path)
    end

    it 'should generate migration for adding columns' do
      migration_params = ['AddEmailToUsers', 'email:string', 'age:integer', "-r=#{@apptmp}/sample_project"]
      response_success = capture_io { generate(:migration, *migration_params) }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_add_email_to_users.rb"
      assert_match_in_file(/class AddEmailToUsers/m, migration_file_path)
      assert_match_in_file(/change_table :users.*?t\.string :email/m, migration_file_path)
      assert_match_in_file(/t\.integer :age/m, migration_file_path)
      assert_match_in_file(/change_table :users.*?t\.remove :email/m, migration_file_path)
      assert_match_in_file(/t\.remove :age/m, migration_file_path)
    end

    it 'should generate migration for removing columns' do
      migration_params = ['RemoveEmailFromUsers', 'email:string', 'age:integer', "-r=#{@apptmp}/sample_project"]
      response_success = capture_io { generate(:migration, *migration_params) }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_remove_email_from_users.rb"
      assert_match_in_file(/class RemoveEmailFromUsers/m, migration_file_path)
      assert_match_in_file(/change_table :users.*?t\.remove :email/m, migration_file_path)
      assert_match_in_file(/t\.remove :age/m, migration_file_path)
      assert_match_in_file(/change_table :users.*?t\.string :email/m, migration_file_path)
      assert_match_in_file(/t\.integer :age/m, migration_file_path)
    end
  end

  describe 'the migration generator for datamapper' do
    before do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=datamapper') }
    end

    it 'should generate migration for generic needs' do
      response_success = capture_io { generate(:migration, 'ModifyUserFields', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_modify_user_fields.rb"
      assert_match_in_file(/migration\s1.*?:modify_user_fields/m, migration_file_path)
      assert_match_in_file(/up\sdo\s+end/m, migration_file_path)
      assert_match_in_file(/down\sdo\s+end/m, migration_file_path)
    end

    it 'should generate migration for adding columns' do
      migration_params = ['AddEmailToUsers', 'email:string', 'age:integer', "-r=#{@apptmp}/sample_project"]
      response_success = capture_io { generate(:migration, *migration_params) }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_add_email_to_users.rb"
      assert_match_in_file(/migration\s1.*?:add_email_to_users/m, migration_file_path)
      assert_match_in_file(/modify_table :users.*?add_column :email, String/m, migration_file_path)
      assert_match_in_file(/add_column :age, Integer/m, migration_file_path)
      assert_match_in_file(/modify_table :users.*?drop_column :email/m, migration_file_path)
      assert_match_in_file(/drop_column :age/m, migration_file_path)
    end

    it 'should generate migration for removing columns' do
      migration_params = ['RemoveEmailFromUsers', 'email:string', 'age:integer', "-r=#{@apptmp}/sample_project"]
      response_success = capture_io { generate(:migration, *migration_params) }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_remove_email_from_users.rb"
      assert_match_in_file(/migration\s1.*?:remove_email_from_users/m, migration_file_path)
      assert_match_in_file(/modify_table :users.*?drop_column :email/m, migration_file_path)
      assert_match_in_file(/drop_column :age/m, migration_file_path)
      assert_match_in_file(/modify_table :users.*?add_column :email, String/m, migration_file_path)
      assert_match_in_file(/add_column :age, Integer/m, migration_file_path)
    end

    it 'should properly version migration files' do
      response_success = capture_io { generate(:migration, 'ModifyUserFields', "-r=#{@apptmp}/sample_project") }
      response_success = capture_io { generate(:migration, 'ModifyUserFields2', "-r=#{@apptmp}/sample_project") }
      response_success = capture_io { generate(:migration, 'ModifyUserFields3', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/migration\s1.*?:modify_user_fields/m, "#{@apptmp}/sample_project/db/migrate/001_modify_user_fields.rb")
      assert_match_in_file(/migration\s2.*?:modify_user_fields2/m, "#{@apptmp}/sample_project/db/migrate/002_modify_user_fields2.rb")
      assert_match_in_file(/migration\s3.*?:modify_user_fields3/m, "#{@apptmp}/sample_project/db/migrate/003_modify_user_fields3.rb")
    end
  end

  describe 'the migration generator for sequel' do
    before do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=sequel') }
    end

    it 'should generate migration for generic needs' do
      response_success = capture_io { generate(:migration, 'ModifyUserFields', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_modify_user_fields.rb"
      assert_match_in_file(/Sequel\.migration/m, migration_file_path)
      assert_match_in_file(/up do\s+end/m, migration_file_path)
      assert_match_in_file(/down do\s+end/m, migration_file_path)
    end

    it 'should generate migration for adding columns' do
      migration_params = ['AddEmailToUsers', 'email:string', 'age:integer', "-r=#{@apptmp}/sample_project"]
      response_success = capture_io { generate(:migration, *migration_params) }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_add_email_to_users.rb"
      assert_match_in_file(/Sequel\.migration/m, migration_file_path)
      assert_match_in_file(/alter_table :users.*?add_column :email, String/m, migration_file_path)
      assert_match_in_file(/add_column :age, Integer/m, migration_file_path)
      assert_match_in_file(/alter_table :users.*?drop_column :email/m, migration_file_path)
      assert_match_in_file(/drop_column :age/m, migration_file_path)
    end

    it 'should generate migration for removing columns' do
      migration_params = ['RemoveEmailFromUsers', 'email:string', 'age:integer', "-r=#{@apptmp}/sample_project"]
      response_success = capture_io { generate(:migration, *migration_params) }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_remove_email_from_users.rb"
      assert_match_in_file(/Sequel\.migration/m, migration_file_path)
      assert_match_in_file(/alter_table :users.*?drop_column :email/m, migration_file_path)
      assert_match_in_file(/drop_column :age/m, migration_file_path)
      assert_match_in_file(/alter_table :users.*?add_column :email, String/m, migration_file_path)
      assert_match_in_file(/add_column :age, Integer/m, migration_file_path)
    end
  end

  describe "the migration destroy option" do
    before do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=sequel') }
      @migration_params = ['RemoveEmailFromUsers', 'email:string', 'age:integer', "-r=#{@apptmp}/sample_project"]
    end

    it 'should destroy the migration files' do
      capture_io { generate(:migration, *@migration_params) }
      capture_io { generate(:migration, 'RemoveEmailFromUsers', "-r=#{@apptmp}/sample_project",'-d') }
      assert_no_file_exists("#{@apptmp}/sample_project/db/migrate/001_remove_email_from_users.rb")
    end

    it 'should destroy the migration file regardless of number' do
      migration_param2 = ['AddEmailFromUsers', 'email:string', 'age:integer', "-r=#{@apptmp}/sample_project"]
      capture_io { generate(:migration, *migration_param2) }
      capture_io { generate(:migration, *@migration_params) }
      capture_io { generate(:migration, 'RemoveEmailFromUsers', "-r=#{@apptmp}/sample_project",'-d') }
      assert_no_file_exists("#{@apptmp}/sample_project/db/migrate/002_remove_email_from_users.rb")
    end
  end
end
