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
      out, = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:migration, 'add_email_to_users', "-r=#{@apptmp}") }.status }
      assert_match(/not at the root/, out)
      assert_empty Dir.children(@apptmp)
    end

    it 'should fail with a message if given invalid namespace names' do
      capture_io { generate(:project, 'sample', "--root=#{@apptmp}") }
      _, err = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:migration, 'wrong/name', "--root=#{@apptmp}/sample") }.status }
      assert_match(%r{Namespace 'wrong/name' must consist only of alphanumeric characters or '_'}, err)
    end

    it 'should fail if we do not use an adapter' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      out, = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:migration, 'AddEmailToUsers', "-r=#{@apptmp}/sample_project") }.status }
      assert_match(/You need an ORM adapter/, out)
    end

    %w[dynamoid ohm].each do |removed_orm|
      it "should fail with a message if the orm in .components is no longer available (#{removed_orm})" do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
        components = "#{@apptmp}/sample_project/.components"
        File.write(components, File.read(components).sub(':orm: activerecord', ":orm: #{removed_orm}"))
        out, = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:migration, 'AddEmailToUsers', "-r=#{@apptmp}/sample_project") }.status }
        assert_match(/The #{removed_orm} orm component is no longer available in Padrino/, out)
        assert_empty Dir["#{@apptmp}/sample_project/db/migrate/*"]
      end
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

    it 'should add and remove a polymorphic reference for a third polymorphic segment' do
      capture_io { generate(:migration, 'AddCommentableToComments', 'commentable:references:polymorphic', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_add_commentable_to_comments.rb"
      assert_match_in_file(/def self\.up\s+change_table :comments do \|t\|\s+t\.references :commentable, polymorphic: true\s+end/m, migration_file_path)
      assert_match_in_file(/def self\.down\s+change_table :comments do \|t\|\s+t\.remove_references :commentable, polymorphic: true\s+end/m, migration_file_path)
    end

    it 'should add a polymorphic reference when rolling back a migration removing it' do
      capture_io { generate(:migration, 'RemoveCommentableFromComments', 'commentable:belongs_to:polymorphic', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_remove_commentable_from_comments.rb"
      assert_match_in_file(/def self\.up\s+change_table :comments do \|t\|\s+t\.remove_references :commentable, polymorphic: true\s+end/m, migration_file_path)
      assert_match_in_file(/def self\.down\s+change_table :comments do \|t\|\s+t\.belongs_to :commentable, polymorphic: true\s+end/m, migration_file_path)
    end

    it 'should combine a polymorphic modifier with an index modifier in any order' do
      capture_io { generate(:migration, 'AddCommentableToComments', 'commentable:references:index:polymorphic', 'owner:belongs_to:polymorphic:uniq', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_add_commentable_to_comments.rb"
      up = /def self\.up\s+change_table :comments do \|t\|\s+t\.references :commentable, polymorphic: true, index: true\s+t\.belongs_to :owner, polymorphic: true, index: \{ unique: true \}\s+end/m
      down = /def self\.down\s+change_table :comments do \|t\|\s+t\.remove_references :commentable, polymorphic: true\s+t\.remove_references :owner, polymorphic: true\s+end/m
      assert_match_in_file(up, migration_file_path)
      assert_match_in_file(down, migration_file_path)
    end

    it 'should add one unique index for index and uniq, and read an index after an unknown segment' do
      capture_io { generate(:migration, 'AddEmailToUsers', 'email:string:index:uniq', 'name:string:foo:index', 'title:string:polymorphic', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_add_email_to_users.rb"
      up = /def self\.up\s+change_table :users do \|t\|\s+t\.string :email\s+t\.index :email, unique: true\s+t\.string :name\s+t\.index :name\s+t\.string :title\s+end/m
      assert_match_in_file(up, migration_file_path)
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

    it 'should pass kinds that are not Sequel generic types as type names' do
      kinds = %w[body:text active:boolean price:decimal seen_at:timestamp views:bigint published_at:datetime cost:big_decimal]
      capture_io { generate(:migration, 'AddBodyToPosts', *kinds, "-r=#{@apptmp}/sample_project") }
      migration = File.read("#{@apptmp}/sample_project/db/migrate/001_add_body_to_posts.rb")
      ['add_column :body, :text', 'add_column :active, :boolean', 'add_column :price, :decimal',
       'add_column :seen_at, :timestamp', 'add_column :views, :bigint', 'add_column :published_at, DateTime',
       'add_column :cost, BigDecimal'].each { |line| assert_includes migration, "#{line}\n" }
    end

    it 'should add references as foreign keys and drop them with drop_foreign_key' do
      fields = %w[user:references author:belongs_to:index editor:References:uniq title:string]
      capture_io { generate(:migration, 'AddUserToPosts', *fields, "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_add_user_to_posts.rb"
      added = ['add_foreign_key :user_id, :users, index: true', 'add_foreign_key :author_id, :authors, index: true',
               'add_foreign_key :editor_id, :editors, index: { unique: true }', 'add_column :title, String']
      up = /up do\s+alter_table :posts do\s+#{added.map { |line| Regexp.escape(line) }.join('\s+')}\s+end\s+end/m
      down = /down do\s+alter_table :posts do\s+drop_foreign_key :user_id\s+drop_foreign_key :author_id\s+drop_foreign_key :editor_id\s+drop_column :title\s+end\s+end/m
      assert_match_in_file(up, migration_file_path)
      assert_match_in_file(down, migration_file_path)
    end

    it 'should add foreign keys when rolling back a migration removing references' do
      capture_io { generate(:migration, 'RemoveUserFromPosts', 'user:references:index', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_remove_user_from_posts.rb"
      assert_match_in_file(/up do\s+alter_table :posts do\s+drop_foreign_key :user_id\s+end\s+end/m, migration_file_path)
      assert_match_in_file(/down do\s+alter_table :posts do\s+add_foreign_key :user_id, :users, index: true\s+end\s+end/m, migration_file_path)
    end

    it 'should index a reference by default and drop the foreign key with its index' do
      capture_io { generate(:migration, 'AddUserToPosts', 'user:references', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:migration, 'RemoveUserFromPosts', 'user:belongs_to', "-r=#{@apptmp}/sample_project") }
      add_path = "#{@apptmp}/sample_project/db/migrate/001_add_user_to_posts.rb"
      remove_path = "#{@apptmp}/sample_project/db/migrate/002_remove_user_from_posts.rb"
      assert_match_in_file(/up do\s+alter_table :posts do\s+add_foreign_key :user_id, :users, index: true\s+end\s+end/m, add_path)
      assert_match_in_file(/down do\s+alter_table :posts do\s+drop_foreign_key :user_id\s+end\s+end/m, add_path)
      assert_match_in_file(/up do\s+alter_table :posts do\s+drop_foreign_key :user_id\s+end\s+end/m, remove_path)
      assert_match_in_file(/down do\s+alter_table :posts do\s+add_foreign_key :user_id, :users, index: true\s+end\s+end/m, remove_path)
    end

    it 'should index columns with an index or uniq segment and ignore other segments' do
      fields = %w[name:string:index email:String:uniq body:text:uniq title:string code:string:foo]
      capture_io { generate(:migration, 'AddNameToUsers', *fields, "-r=#{@apptmp}/sample_project") }
      migration = File.read("#{@apptmp}/sample_project/db/migrate/001_add_name_to_users.rb")
      ['add_column :name, String, index: true', 'add_column :email, String, index: { unique: true }',
       'add_column :body, :text, index: { unique: true }', 'add_column :title, String', 'add_column :code, String',
       'drop_column :name', 'drop_column :email', 'drop_column :body', 'drop_column :title', 'drop_column :code'].each do |line|
        assert_includes migration, "      #{line}\n"
      end
    end

    it 'should combine index modifiers and a polymorphic modifier in any order' do
      fields = %w[email:string:index:uniq name:string:foo:index commentable:references:uniq:polymorphic]
      capture_io { generate(:migration, 'AddEmailToUsers', *fields, "-r=#{@apptmp}/sample_project") }
      migration = File.read("#{@apptmp}/sample_project/db/migrate/001_add_email_to_users.rb")
      ['add_column :email, String, index: { unique: true }', 'add_column :name, String, index: true',
       'add_column :commentable_id, Integer', 'add_column :commentable_type, String',
       'add_index [:commentable_type, :commentable_id], unique: true',
       'drop_column :commentable_id', 'drop_column :commentable_type'].each do |line|
        assert_includes migration, "      #{line}\n"
      end
    end

    it 'should add and drop the id and type columns of a polymorphic reference' do
      capture_io { generate(:migration, 'AddCommentableToComments', 'commentable:references:polymorphic', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_add_commentable_to_comments.rb"
      up = /up do\s+alter_table :comments do\s+add_column :commentable_id, Integer\s+add_column :commentable_type, String\s+add_index \[:commentable_type, :commentable_id\]\s+end\s+end/m
      assert_match_in_file(up, migration_file_path)
      assert_match_in_file(/down do\s+alter_table :comments do\s+drop_column :commentable_id\s+drop_column :commentable_type\s+end\s+end/m, migration_file_path)
    end

    it 'should add the id and type columns back when rolling back a migration removing a polymorphic reference' do
      capture_io { generate(:migration, 'RemoveCommentableFromComments', 'commentable:references:polymorphic', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_remove_commentable_from_comments.rb"
      assert_match_in_file(/up do\s+alter_table :comments do\s+drop_column :commentable_id\s+drop_column :commentable_type\s+end\s+end/m, migration_file_path)
      down = /down do\s+alter_table :comments do\s+add_column :commentable_id, Integer\s+add_column :commentable_type, String\s+add_index \[:commentable_type, :commentable_id\]\s+end\s+end/m
      assert_match_in_file(down, migration_file_path)
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
