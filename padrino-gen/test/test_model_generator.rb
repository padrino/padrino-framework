require_relative 'helper'

describe 'ModelGenerator' do
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{SecureRandom.hex}"
    `mkdir -p #{@apptmp}`
  end

  def teardown
    `rm -rf #{@apptmp}`
  end

  describe 'the model generator' do
    it 'should fail outside app root' do
      out, = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:model, 'user', "-r=#{@apptmp}") }.status }
      assert_match(/not at the root/, out)
      assert_empty Dir.children(@apptmp)
    end

    it 'should fail if the name is missing' do
      _, err = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:model, "-r=#{@apptmp}") }.status }
      assert_match(/No value provided for required arguments 'name'/, err)
    end

    it 'should fail with a message if the model name is not a valid constant' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=sequel') }
      _, err = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:model, '2bad', "-r=#{@apptmp}/sample_project") }.status }
      assert_match(/2bad is not a valid constant name/, err)
      assert_no_file_exists("#{@apptmp}/sample_project/models/2bad.rb")
    end

    it 'should generate filename properly' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=sequel') }
      capture_io { generate(:model, 'DemoItem', 'name:string', 'age', 'email:string', "-r=#{@apptmp}/sample_project") }
      assert_file_exists("#{@apptmp}/sample_project/models/demo_item.rb")
    end

    it 'should fail if field name is not acceptable' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=sequel') }
      fields = ['re@l$ly:string', 'display-name:string', 'age&year:datetime', 'email_two:string']
      out, = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:model, 'DemoItem', *fields, "-r=#{@apptmp}/sample_project") }.status }
      assert_match(/Invalid field name:/, out)
      assert_match(/display-name:string/, out)
      assert_match(/age&year:datetime/, out)
      assert_match(/re@l\$ly:string/, out)
      refute_match(/email_two:string/, out)
      refute_match(/apply/, out)
      assert_no_file_exists("#{@apptmp}/sample_project/models/demo_item.rb")
    end

    it 'should fail if we do not use an adapter' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      out, = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:model, 'user', "-r=#{@apptmp}/sample_project") }.status }
      assert_match(/You need an ORM adapter/, out)
    end

    %w[minirecord ohm].each do |removed_orm|
      it "should fail with a message if the orm in .components is no longer available (#{removed_orm})" do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=sequel') }
        components = "#{@apptmp}/sample_project/.components"
        File.write(components, File.read(components).sub(':orm: sequel', ":orm: #{removed_orm}"))
        out, = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:model, 'user', "-r=#{@apptmp}/sample_project") }.status }
        assert_match(/The #{removed_orm} orm component is no longer available in Padrino \(available: .*\bsequel\b/, out)
        assert_no_file_exists("#{@apptmp}/sample_project/models/user.rb")
      end
    end

    it 'should not fail if we do not have test component' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=none', '-d=activerecord') }
      capture_io { generate(:model, 'user', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class User < ActiveRecord::Base/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_no_file_exists("#{@apptmp}/sample_project/test")
    end

    it 'should generate model in specified app' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=sequel', '--script=none', '-t=bacon') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:model, 'Post', 'body:string', '-a=/subby', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class Post < Sequel::Model/m, "#{@apptmp}/sample_project/subby/models/post.rb")
    end

    it 'should generate migration file versions properly' do
      capture_io { generate(:project, 'sample_project', '--migration_format=number', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
      capture_io { generate(:model, 'user', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:model, 'account', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:model, 'bank', "-r=#{@apptmp}/sample_project") }
      assert_file_exists("#{@apptmp}/sample_project/db/migrate/001_create_users.rb")
      assert_file_exists("#{@apptmp}/sample_project/db/migrate/002_create_accounts.rb")
      assert_file_exists("#{@apptmp}/sample_project/db/migrate/003_create_banks.rb")
    end

    it 'should generate migration file versions properly when timestamped' do
      capture_io { generate(:project, 'sample_project', '--migration_format=timestamp', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }

      time = stop_time_for_test.utc.strftime('%Y%m%d%H%M%S')

      capture_io { generate(:model, 'user', "-r=#{@apptmp}/sample_project") }
      assert_file_exists("#{@apptmp}/sample_project/db/migrate/#{time}_create_users.rb")
    end

    it 'should generate a default type value for fields' do
      stop_time_for_test
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
      capture_io { generate(:model, 'friend', 'name', 'age:integer', 'email', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_create_friends.rb"
      assert_match_in_file(/class CreateFriends < ActiveRecord::Migration/m, migration_file_path)
      assert_match_in_file(/    create_table :friends/m,                     migration_file_path)
      assert_match_in_file(/      t.string :name/m,                          migration_file_path)
      assert_match_in_file(/      t.integer :age/m,                          migration_file_path)
      assert_match_in_file(/      t.string :email/m,                         migration_file_path)
      assert_match_in_file(/    drop_table :friends/m,                       migration_file_path)
    end

    it 'should abort if model name already exists' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=activerecord') }
      out, = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:model, 'kernel', "--root=#{@apptmp}/sample_project") }.status }
      assert_match(/Kernel already exists/, out)
      assert_no_file_exists("#{@apptmp}/sample_project/db/migrate/001_create_kernel.rb")
      assert_no_file_exists("#{@apptmp}/sample_project/models/kernel.rb")
    end

    it 'should abort if model name already exists in root' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=activerecord') }
      capture_io { generate(:app, 'user', "--root=#{@apptmp}/sample_project") }
      out, = capture_io { assert_equal 1, assert_raises(SystemExit) { generate_with_parts(:model, 'user', "--root=#{@apptmp}/sample_project", apps: 'user') }.status }
      assert_file_exists("#{@apptmp}/sample_project/user/app.rb")
      assert_no_file_exists("#{@apptmp}/sample_project/models/user.rb")
      assert_match(/User already exists/, out)
    end

    it 'should generate model files if :force option is specified' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=activerecord') }
      capture_io { generate(:app, 'user', "--root=#{@apptmp}/sample_project") }
      capture_io { generate_with_parts(:model, 'user', "--root=#{@apptmp}/sample_project", '--force', apps: 'user') }
      assert_file_exists("#{@apptmp}/sample_project/user/app.rb")
      assert_file_exists("#{@apptmp}/sample_project/models/user.rb")
    end
  end

  # ACTIVERECORD
  describe 'model generator using activerecord' do
    it 'should add activerecord middleware' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=activerecord') }
      assert_match_in_file(/  use ConnectionPoolManagement/m, "#{@apptmp}/sample_project/app/app.rb")
      assert_file_exists("#{@apptmp}/sample_project/lib/connection_pool_management_middleware.rb")
    end

    it 'should generate model file' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
      capture_io { generate(:model, 'user', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class User < ActiveRecord::Base/m, "#{@apptmp}/sample_project/models/user.rb")
    end

    it 'should generate model file with camelized name' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
      capture_io { generate(:model, 'ChunkyBacon', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class ChunkyBacon < ActiveRecord::Base/m, "#{@apptmp}/sample_project/models/chunky_bacon.rb")
      assert_match_in_file(/ChunkyBacon Model/, "#{@apptmp}/sample_project/test/models/chunky_bacon_test.rb")
    end

    it 'should generate migration file with no fields' do
      stop_time_for_test
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
      capture_io { generate(:model, 'user', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_create_users.rb"
      assert_match_in_file(/class CreateUsers < ActiveRecord::Migration/m, migration_file_path)
      assert_match_in_file(/    create_table :users/m, migration_file_path)
      assert_match_in_file(/    drop_table :users/m, migration_file_path)
    end

    it 'should generate migration file with given fields' do
      stop_time_for_test
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
      capture_io { generate(:model, 'friend', 'name:string', 'age:integer', 'email:string', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_create_friends.rb"
      assert_match_in_file(/class CreateFriends < ActiveRecord::Migration/m, migration_file_path)
      assert_match_in_file(/    create_table :friends/m, migration_file_path)
      assert_match_in_file(/      t.string :name/m,   migration_file_path)
      assert_match_in_file(/      t.integer :age/m,   migration_file_path)
      assert_match_in_file(/      t.string :email/m,  migration_file_path)
      assert_match_in_file(/    drop_table :friends/m, migration_file_path)
    end

    it 'should generate migration file with references and indexed fields' do
      stop_time_for_test
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
      capture_io { generate(:model, 'order', 'user:belongs_to', 'code:string:uniq', 'state:string:index', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_create_orders.rb"
      fields = /create_table :orders do \|t\|\s+t\.belongs_to :user\s+t\.string :code\s+t\.index :code, unique: true\s+t\.string :state\s+t\.index :state\s+t\.timestamps/m
      assert_match_in_file(fields, migration_file_path)
    end

    it 'should generate migration file with a polymorphic reference' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
      capture_io { generate(:model, 'comment', 'body:text', 'commentable:references:polymorphic', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_create_comments.rb"
      fields = /create_table :comments do \|t\|\s+t\.text :body\s+t\.references :commentable, polymorphic: true\s+t\.timestamps/m
      assert_match_in_file(fields, migration_file_path)
    end

    it 'should generate migration file with a uniquely indexed polymorphic reference' do
      stop_time_for_test
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
      capture_io { generate(:model, 'comment', 'commentable:references:uniq:polymorphic', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_create_comments.rb"
      fields = /create_table :comments do \|t\|\s+t\.references :commentable, polymorphic: true, index: \{ unique: true \}\s+t\.timestamps/m
      assert_match_in_file(fields, migration_file_path)
    end
  end

  # SEQUEL
  describe 'model generator using sequel' do
    it 'should generate model file with given properties' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=sequel') }
      capture_io { generate(:model, 'user', 'name:string', 'age:integer', 'created:datetime', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class User < Sequel::Model/m, "#{@apptmp}/sample_project/models/user.rb")
    end

    it 'should generate model file with camelized name' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=sequel') }
      capture_io { generate(:model, 'ChunkyBacon', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class ChunkyBacon < Sequel::Model/m, "#{@apptmp}/sample_project/models/chunky_bacon.rb")
      assert_match_in_file(/ChunkyBacon Model/, "#{@apptmp}/sample_project/test/models/chunky_bacon_test.rb")
    end

    it 'should generate migration file with given properties' do
      stop_time_for_test
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=sequel') }
      capture_io { generate(:model, 'friend', 'name:string', 'age:integer', 'created:datetime', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_create_friends.rb"
      assert_match_in_file(/class Friend < Sequel::Model/m, "#{@apptmp}/sample_project/models/friend.rb")
      assert_match_in_file(/Sequel\.migration do/m,  migration_file_path)
      assert_match_in_file(/create_table :friends/m, migration_file_path)
      assert_match_in_file(/String :name/m,          migration_file_path)
      assert_match_in_file(/Integer :age/m,          migration_file_path)
      assert_match_in_file(/DateTime :created/m,     migration_file_path)
      assert_match_in_file(/drop_table :friends/m,   migration_file_path)
    end

    it 'should generate foreign keys for references in the migration file' do
      stop_time_for_test
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=sequel') }
      fields = %w[title:string user:references author:belongs_to:index editor:References:uniq views:integer]
      capture_io { generate(:model, 'post', *fields, "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_create_posts.rb"
      lines = ['primary_key :id', 'String :title', 'foreign_key :user_id, :users, index: true', 'foreign_key :author_id, :authors, index: true',
               'foreign_key :editor_id, :editors, index: { unique: true }', 'Integer :views']
      columns = /create_table :posts do\s+#{lines.map { |line| Regexp.escape(line) }.join('\s+')}\s+end/m
      assert_match_in_file(columns, migration_file_path)
    end

    it 'should index columns with an index or uniq segment in the migration file and ignore other segments' do
      stop_time_for_test
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=sequel') }
      fields = %w[name:string:index slug:String:uniq body:text:index age:integer code:string:foo]
      capture_io { generate(:model, 'page', *fields, "-r=#{@apptmp}/sample_project") }
      migration = File.read("#{@apptmp}/sample_project/db/migrate/001_create_pages.rb")
      ['String :name, index: true', 'String :slug, index: { unique: true }', 'Text :body, index: true',
       'Integer :age', 'String :code'].each { |line| assert_includes migration, "      #{line}\n" }
    end

    it 'should generate the id and type columns of a polymorphic reference in the migration file' do
      stop_time_for_test
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=sequel') }
      capture_io { generate(:model, 'comment', 'body:text', 'commentable:references:polymorphic', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_create_comments.rb"
      columns = /create_table :comments do\s+primary_key :id\s+Text :body\s+Integer :commentable_id\s+String :commentable_type\s+index \[:commentable_type, :commentable_id\]\s+end/m
      assert_match_in_file(columns, migration_file_path)
    end

    it 'should combine a polymorphic modifier with uniq in any order in the migration file' do
      stop_time_for_test
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=sequel') }
      capture_io { generate(:model, 'comment', 'commentable:references:uniq:polymorphic', 'email:string:index:uniq', "-r=#{@apptmp}/sample_project") }
      migration = File.read("#{@apptmp}/sample_project/db/migrate/001_create_comments.rb")
      ['Integer :commentable_id', 'String :commentable_type', 'index [:commentable_type, :commentable_id], unique: true',
       'String :email, index: { unique: true }'].each { |line| assert_includes migration, "      #{line}\n" }
    end
  end

  describe 'model generator using mongoid' do
    it 'should generate model file with no properties' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=mongoid') }
      capture_io { generate(:model, 'person', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class Person\n\s+include Mongoid::Document/m, "#{@apptmp}/sample_project/models/person.rb")
      assert_match_in_file(/# field <name>, type: <type>, default: <value>/m, "#{@apptmp}/sample_project/models/person.rb")
    end

    it 'should generate model file with given fields' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=mongoid') }
      capture_io { generate(:model, 'user', 'name:string', 'age:integer', 'email:string', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class User\n\s+include Mongoid::Document/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/field :name, type: String/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/field :age, type: Integer/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/field :email, type: String/m, "#{@apptmp}/sample_project/models/user.rb")
    end

    it 'should map SQL field kinds to Mongoid types' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=mongoid') }
      kinds = %w[body:text token:uuid views:bigint price:decimal published_at:datetime seen_at:timestamp
                 data:binary meta:json ref:object_id note:Text]
      capture_io { generate(:model, 'post', *kinds, "-r=#{@apptmp}/sample_project") }
      model = File.read("#{@apptmp}/sample_project/models/post.rb")
      expected = [
        'field :body, type: String', 'field :token, type: String', 'field :views, type: Integer',
        'field :price, type: BigDecimal', 'field :published_at, type: Time', 'field :seen_at, type: Time',
        'field :data, type: BSON::Binary', 'field :meta, type: Object', 'field :ref, type: BSON::ObjectId',
        'field :note, type: String'
      ]
      expected.each { |line| assert_includes model, "  #{line}\n" }
    end

    it 'should keep field kinds that already name a Mongoid type' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=mongoid') }
      kinds = %w[a:boolean b:date c:time d:date_time e:DateTime f:big_decimal g:float h:array i:hash j:symbol k:money]
      capture_io { generate(:model, 'post', *kinds, "-r=#{@apptmp}/sample_project") }
      model = File.read("#{@apptmp}/sample_project/models/post.rb")
      %w[a:Boolean b:Date c:Time d:DateTime e:DateTime f:BigDecimal g:Float h:Array i:Hash j:Symbol k:Money].each do |pair|
        field, type = pair.split(':')
        assert_includes model, "  field :#{field}, type: #{type}\n"
      end
    end

    it 'should generate belongs_to for references' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=mongoid') }
      kinds = %w[account:references author:belongs_to:index commentable:references:polymorphic owner:references:index:polymorphic]
      capture_io { generate(:model, 'post', *kinds, "-r=#{@apptmp}/sample_project") }
      model = File.read("#{@apptmp}/sample_project/models/post.rb")
      assert_includes model, "  belongs_to :account\n"
      assert_includes model, "  belongs_to :author\n"
      assert_includes model, "  belongs_to :commentable, polymorphic: true\n"
      assert_includes model, "  belongs_to :owner, polymorphic: true\n"
      refute_match(/field :(account|author|commentable|owner)/, model)
    end
  end

  describe 'model generator testing files' do
    # BACON
    it 'should generate test file for bacon' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:model, 'SomeUser', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/describe "SomeUser Model"/m, "#{@apptmp}/sample_project/test/models/some_user_test.rb")
      assert_match_in_file(/@some_user = SomeUser.new/m, "#{@apptmp}/sample_project/test/models/some_user_test.rb")
      assert_match_in_file(/@some_user\.should\.not\.be\.nil/m, "#{@apptmp}/sample_project/test/models/some_user_test.rb")
      assert_match_in_file(%r{"\#\{__dir__\}(/\.\.){1}/test}m, "#{@apptmp}/sample_project/test/models/some_user_test.rb")
    end

    it 'should generate test file for bacon in specified app' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:model, 'SomeUser', '-a=/subby', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/describe "SomeUser Model"/m, "#{@apptmp}/sample_project/test/subby/models/some_user_test.rb")
      assert_match_in_file(/@some_user = SomeUser.new/m, "#{@apptmp}/sample_project/test/subby/models/some_user_test.rb")
      assert_match_in_file(/@some_user\.should\.not\.be\.nil/m, "#{@apptmp}/sample_project/test/subby/models/some_user_test.rb")
      assert_match_in_file(%r{"\#\{__dir__\}(/\.\.){2}/test}m, "#{@apptmp}/sample_project/test/subby/models/some_user_test.rb")
    end

    # MINITEST
    it 'should generate test file for minitest' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=minitest', '-d=activerecord') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:model, 'SomeUser', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/describe "SomeUser Model"/m, "#{@apptmp}/sample_project/test/models/some_user_test.rb")
      assert_match_in_file(/refute_nil @some_user/m, "#{@apptmp}/sample_project/test/models/some_user_test.rb")
    end

    it 'should generate test file for minitest in specified app' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=minitest', '-d=activerecord') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:model, 'SomeUser', '-a=/subby', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/describe "SomeUser Model"/m, "#{@apptmp}/sample_project/test/subby/models/some_user_test.rb")
      assert_match_in_file(/refute_nil @some_user/m, "#{@apptmp}/sample_project/test/subby/models/some_user_test.rb")
    end

    # RSPEC
    it 'should generate test file for rspec' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=rspec', '-d=activerecord') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:model, 'SomeUser', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/describe SomeUser do/m, "#{@apptmp}/sample_project/spec/models/some_user_spec.rb")
      # assert_match_in_file(/let\(:some_user\) \{ SomeUser.new \}/m, "#{@apptmp}/sample_project/spec/models/some_user_spec.rb")
      # assert_match_in_file(/some_user\.should_not be_nil/m, "#{@apptmp}/sample_project/spec/models/some_user_spec.rb")
    end

    it 'should generate test file for rspec in specified app' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=rspec', '-d=activerecord') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:model, 'SomeUser', '-a=/subby', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/describe SomeUser do/m, "#{@apptmp}/sample_project/spec/subby/models/some_user_spec.rb")
      # assert_match_in_file(/let\(:some_user\) \{ SomeUser.new \}/m, "#{@apptmp}/sample_project/spec/subby/models/some_user_spec.rb")
      # assert_match_in_file(/some_user\.should_not be_nil/m, "#{@apptmp}/sample_project/spec/subby/models/some_user_spec.rb")
    end

    # SHOULDA
    it 'should generate test file for shoulda' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=shoulda', '-d=activerecord') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:model, 'SomePerson', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class SomePersonTest < Test::Unit::TestCase/m, "#{@apptmp}/sample_project/test/models/some_person_test.rb")
      assert_match_in_file(/context "SomePerson Model"/m, "#{@apptmp}/sample_project/test/models/some_person_test.rb")
      assert_match_in_file(/@some_person = SomePerson.new/m, "#{@apptmp}/sample_project/test/models/some_person_test.rb")
      assert_match_in_file(/assert_not_nil @some_person/m, "#{@apptmp}/sample_project/test/models/some_person_test.rb")
      assert_match_in_file(%r{"\#\{__dir__\}(/\.\.){1}/test}m, "#{@apptmp}/sample_project/test/models/some_person_test.rb")
    end

    it 'should generate test file for shoulda in specified app' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=shoulda', '-d=activerecord') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:model, 'SomePerson', '-a=/subby', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class SomePersonTest < Test::Unit::TestCase/m, "#{@apptmp}/sample_project/test/subby/models/some_person_test.rb")
      assert_match_in_file(/context "SomePerson Model"/m, "#{@apptmp}/sample_project/test/subby/models/some_person_test.rb")
      assert_match_in_file(/@some_person = SomePerson.new/m, "#{@apptmp}/sample_project/test/subby/models/some_person_test.rb")
      assert_match_in_file(/assert_not_nil @some_person/m, "#{@apptmp}/sample_project/test/subby/models/some_person_test.rb")
      assert_match_in_file(%r{"\#\{__dir__\}(/\.\.){2}/test}m, "#{@apptmp}/sample_project/test/subby/models/some_person_test.rb")
    end
  end

  describe 'the model destroy option' do
    module ActiveRecord
      Base = Class.new
    end

    it 'should destroy the model file' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
      capture_io { generate(:model, 'User', "-r=#{@apptmp}/sample_project") }
      capture_io { generate_with_parts(:model, 'User', "-r=#{@apptmp}/sample_project", '-d') }
      assert_no_file_exists("#{@apptmp}/sample_project/models/user.rb")
      assert_no_file_exists("#{@apptmp}/sample_project/test/models/user_test.rb")
      assert_no_file_exists("#{@apptmp}/sample_project/db/migrate/001_create_users.rb")
    end

    it 'should destroy the model test file with rspec' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=rspec', '-d=activerecord') }
      capture_io { generate(:model, 'User', "-r=#{@apptmp}/sample_project") }
      capture_io { generate_with_parts(:model, 'User', "-r=#{@apptmp}/sample_project", '-d') }
      assert_no_file_exists("#{@apptmp}/sample_project/spec/models/user_spec.rb")
    end

    it 'should destroy the model test file in a sub app' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:model, 'User', '-a=/subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate_with_parts(:model, 'User', '-a=/subby', "-r=#{@apptmp}/sample_project", '-d', apps: 'subby') }
      assert_no_file_exists("#{@apptmp}/sample_project/subby/models/user.rb")
      assert_no_file_exists("#{@apptmp}/sample_project/test/subby/models/user_test.rb")
      assert_no_file_exists("#{@apptmp}/sample_project/db/migrate/001_create_users.rb")
    end

    it 'should destroy the right model migration' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=rspec', '-d=activerecord') }
      capture_io { generate(:model, 'bar_foo', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:model, 'foo', "-r=#{@apptmp}/sample_project") }
      capture_io { generate_with_parts(:model, 'foo', "-r=#{@apptmp}/sample_project", '-d') }
      assert_no_file_exists("#{@apptmp}/sample_project/db/migrate/002_create_foos.rb")
      assert_file_exists("#{@apptmp}/sample_project/db/migrate/001_create_bar_foos.rb")
    end
  end
end
