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
      out, = capture_io { generate(:model, 'user', "-r=#{@apptmp}") }
      assert_match(/not at the root/, out)
      assert_no_file_exists('/tmp/models/user.rb')
    end

    it 'should generate filename properly' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=sequel') }
      capture_io { generate(:model, 'DemoItem', 'name:string', 'age', 'email:string', "-r=#{@apptmp}/sample_project") }
      assert_file_exists("#{@apptmp}/sample_project/models/demo_item.rb")
    end

    it 'should fail if field name is not acceptable' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=sequel') }
      out, = capture_io { generate(:model, 'DemoItem', 're@l$ly:string', 'display-name:string', 'age&year:datetime', 'email_two:string', "-r=#{@apptmp}/sample_project") }
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
      assert_raises(SystemExit) { capture_io { generate(:model, 'user', "-r=#{@apptmp}/sample_project") } }
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
      out, = capture_io { generate(:model, 'kernel', "--root=#{@apptmp}/sample_project") }
      assert_match(/Kernel already exists/, out)
      assert_no_file_exists("#{@apptmp}/sample_project/db/migrate/001_create_kernel.rb")
      assert_no_file_exists("#{@apptmp}/sample_project/models/kernel.rb")
    end

    it 'should abort if model name already exists in root' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=activerecord') }
      capture_io { generate(:app, 'user', "--root=#{@apptmp}/sample_project") }
      out, = capture_io { generate_with_parts(:model, 'user', "--root=#{@apptmp}/sample_project", apps: 'user') }
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
  end

  # MINIRECORD
  describe 'model generator using minirecord' do
    it 'should generate hooks for auto upgrade' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=minirecord') }
      assert_match_in_file(
        "Padrino.after_load do\n  ActiveRecord::Base.auto_upgrade!",
        "#{@apptmp}/sample_project/config/boot.rb"
      )
    end

    it 'should add activerecord middleware' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=minirecord') }
      assert_match_in_file(/  use ConnectionPoolManagement/m, "#{@apptmp}/sample_project/app/app.rb")
      assert_file_exists("#{@apptmp}/sample_project/lib/connection_pool_management_middleware.rb")
    end

    it 'should generate model file' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=minirecord') }
      capture_io { generate(:model, 'user', 'name:string', 'surname:string', 'age:integer', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class User < ActiveRecord::Base/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/field :name, as: :string/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/field :surname, as: :string/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/field :age, as: :integer/m, "#{@apptmp}/sample_project/models/user.rb")
    end

    it 'should generate model file with camelized name' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=minirecord') }
      capture_io { generate(:model, 'ChunkyBacon', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class ChunkyBacon < ActiveRecord::Base/m, "#{@apptmp}/sample_project/models/chunky_bacon.rb")
      assert_match_in_file(/ChunkyBacon Model/, "#{@apptmp}/sample_project/test/models/chunky_bacon_test.rb")
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
  end

  # REDIS
  describe 'model generator using ohm' do
    it 'should generate model file with no properties' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=ohm') }
      capture_io { generate(:model, 'person', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class Person < Ohm::Model/, "#{@apptmp}/sample_project/models/person.rb")
      assert_match_in_file(/# attribute :name/m, "#{@apptmp}/sample_project/models/person.rb")
      assert_match_in_file(/# reference :venue, Venue/m, "#{@apptmp}/sample_project/models/person.rb")
    end

    it 'should generate model file with given fields' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=ohm') }
      capture_io { generate(:model, 'user', 'name:string', 'age:integer', 'email:string', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class User < Ohm::Model/, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/attribute :name/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/attribute :age/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/attribute :email/m, "#{@apptmp}/sample_project/models/user.rb")
    end
  end

  # MONGOMATIC
  describe 'model generator using mongomatic' do
    it 'should generate model file with no properties' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=mongomatic') }
      capture_io { generate(:model, 'person', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class Person < Mongomatic::Base/, "#{@apptmp}/sample_project/models/person.rb")
      assert_match_in_file(/include Mongomatic::Expectations::Helper/m, "#{@apptmp}/sample_project/models/person.rb")
    end

    it 'should generate model file with given fields' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=mongomatic') }
      capture_io { generate(:model, 'user', 'name:string', 'age:integer', 'email:string', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class User < Mongomatic::Base/, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/include Mongomatic::Expectations::Helper/, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/be_present self\['name'\]/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/be_present self\['age'\]/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/be_present self\['email'\]/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/be_a_number self\['age'\]/m, "#{@apptmp}/sample_project/models/user.rb")
    end
  end

  # DYNAMOID
  describe 'model generator using dynamoid' do
    it 'should generate model file with no properties' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=dynamoid') }
      capture_io { generate(:model, 'person', 'name:string', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class Person\n\s+include Dynamoid::Document/m, "#{@apptmp}/sample_project/models/person.rb")
    end

    it 'should generate model file with given fields' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=dynamoid') }
      capture_io { generate(:model, 'user', 'name:string', 'age:integer', 'email:string', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class User\n\s+include Dynamoid::Document/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/field :name, :string/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/field :age, :integer/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/field :email, :string/m, "#{@apptmp}/sample_project/models/user.rb")
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
