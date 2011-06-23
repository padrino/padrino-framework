require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestModelGenerator < Test::Unit::TestCase
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{UUID.new.generate}"
    `mkdir -p #{@apptmp}`
  end

  def teardown
    `rm -rf #{@apptmp}`
  end

  context 'the model generator' do
    should "fail outside app root" do
      output = silence_logger { generate(:model, 'user', "-r=#{@apptmp}") }
      assert_match(/not at the root/, output)
      assert_no_file_exists('/tmp/models/user.rb')
    end

    should "generate filename properly" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=couchrest') }
      silence_logger { generate(:model, 'DemoItem', "name:string", "age", "email:string", "-r=#{@apptmp}/sample_project") }
      assert_file_exists("#{@apptmp}/sample_project/models/demo_item.rb")
    end

    should "fail if field name is not acceptable" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=couchrest') }
      output = silence_logger { generate(:model, 'DemoItem', "re@l$ly:string","display-name:string", "age&year:datetime", "email_two:string", "-r=#{@apptmp}/sample_project") }
      assert_match(/Invalid field name:/, output)
      assert_match(/display-name:string/, output)
      assert_match(/age&year:datetime/, output)
      assert_match(/re@l\$ly:string/, output)
      assert_no_match(/email_two:string/, output)
      assert_no_match(/apply/, output)
      assert_no_file_exists("#{@apptmp}/sample_project/models/demo_item.rb")
    end

    should "fail if we don't use an adapter" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      assert_raise(SystemExit) { silence_logger { generate(:model, 'user', "-r=#{@apptmp}/sample_project") } }
    end

    should "not fail if we don't have test component" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=none', '-d=activerecord') }
      response_success = silence_logger { generate(:model, 'user', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class User < ActiveRecord::Base/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_no_file_exists("#{@apptmp}/sample_project/test")
    end

    should "generate model in specified app" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=datamapper', '--script=none', '-t=bacon') }
      silence_logger { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      silence_logger { generate(:model, 'Post', "body:string", '-a=/subby', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class Post\n\s+include DataMapper::Resource/m, "#{@apptmp}/sample_project/subby/models/post.rb")
      assert_match_in_file(/property :body, String/m, "#{@apptmp}/sample_project/subby/models/post.rb")
      assert_match_in_file(/migration 1, :create_posts do/m, "#{@apptmp}/sample_project/db/migrate/001_create_posts.rb")
      assert_match_in_file(/gem 'data_mapper'/m,"#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/DataMapper.finalize/m,"#{@apptmp}/sample_project/config/boot.rb")
    end

    should "generate only generate model once" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
      response_success = silence_logger { generate(:model, 'user', "-r=#{@apptmp}/sample_project") }
      response_duplicate = silence_logger { generate(:model, 'user', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class User < ActiveRecord::Base/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match "identical\e[0m  models/user.rb", response_duplicate
      assert_match "identical\e[0m  test/models/user_test.rb", response_duplicate
    end

    should "generate migration file versions properly" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
      silence_logger { generate(:model, 'user', "-r=#{@apptmp}/sample_project") }
      silence_logger { generate(:model, 'account', "-r=#{@apptmp}/sample_project") }
      silence_logger { generate(:model, 'bank', "-r=#{@apptmp}/sample_project") }
      assert_file_exists("#{@apptmp}/sample_project/db/migrate/001_create_users.rb")
      assert_file_exists("#{@apptmp}/sample_project/db/migrate/002_create_accounts.rb")
      assert_file_exists("#{@apptmp}/sample_project/db/migrate/003_create_banks.rb")
    end
  end

  # ACTIVERECORD
  context "model generator using activerecord" do
    should "generate model file" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
      silence_logger { generate(:model, 'user', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class User < ActiveRecord::Base/m, "#{@apptmp}/sample_project/models/user.rb")
    end

    should "generate model file with camelized name" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
      silence_logger { generate(:model, 'ChunkyBacon', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class ChunkyBacon < ActiveRecord::Base/m, "#{@apptmp}/sample_project/models/chunky_bacon.rb")
      assert_match_in_file(/ChunkyBacon Model/, "#{@apptmp}/sample_project/test/models/chunky_bacon_test.rb")
    end

    should "generate migration file with no fields" do
      current_time = stop_time_for_test.strftime("%Y%m%d%H%M%S")
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
      silence_logger { generate(:model, 'user', "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_create_users.rb"
      assert_match_in_file(/class CreateUsers < ActiveRecord::Migration/m, migration_file_path)
      assert_match_in_file(/create_table :users/m, migration_file_path)
      assert_match_in_file(/drop_table :users/m, migration_file_path)
    end

    should "generate migration file with given fields" do
      current_time = stop_time_for_test.strftime("%Y%m%d%H%M%S")
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
      silence_logger { generate(:model, 'person', "name:string", "age:integer", "email:string", "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_create_people.rb"
      assert_match_in_file(/class CreatePeople < ActiveRecord::Migration/m, migration_file_path)
      assert_match_in_file(/create_table :people/m, migration_file_path)
      assert_match_in_file(/t.string :name/m,   migration_file_path)
      assert_match_in_file(/t.integer :age/m,   migration_file_path)
      assert_match_in_file(/t.string :email/m,  migration_file_path)
      assert_match_in_file(/drop_table :people/m, migration_file_path)
    end
  end

  # COUCHREST
  context "model generator using couchrest" do
    should "generate model file with no properties" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=couchrest') }
      silence_logger { generate(:model, 'user', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class User < CouchRest::Model::Base/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/# property <name>[\s\n]+?end/m, "#{@apptmp}/sample_project/models/user.rb")
    end

    should "generate model file with given fields" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=couchrest') }
      silence_logger { generate(:model, 'person', "name:string", "age", "email:string", "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class Person < CouchRest::Model::Base/m, "#{@apptmp}/sample_project/models/person.rb")
      assert_match_in_file(/property :name/m, "#{@apptmp}/sample_project/models/person.rb")
      assert_match_in_file(/property :age/m, "#{@apptmp}/sample_project/models/person.rb")
      assert_match_in_file(/property :email/m, "#{@apptmp}/sample_project/models/person.rb")
    end
  end

  # DATAMAPPER
  context "model generator using datamapper" do

    should "generate gemfile gem" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=datamapper') }
      silence_logger { generate(:model, 'user', "name:string", "age:integer", "created_at:datetime", "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/gem 'data_mapper'/m,"#{@apptmp}/sample_project/Gemfile")
    end

    should "generate model file with camelized name" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=datamapper') }
      silence_logger { generate(:model, 'ChunkyBacon', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class ChunkyBacon\n\s+include DataMapper::Resource/m, "#{@apptmp}/sample_project/models/chunky_bacon.rb")
      assert_match_in_file(/ChunkyBacon Model/, "#{@apptmp}/sample_project/test/models/chunky_bacon_test.rb")
    end

    should "generate model file with fields" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=datamapper') }
      silence_logger { generate(:model, 'user', "name:string", "age:integer", "created_at:datetime", "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class User\n\s+include DataMapper::Resource/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/property :name, String/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/property :age, Integer/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/property :created_at, DateTime/m, "#{@apptmp}/sample_project/models/user.rb")
    end

    should "properly generate version numbers" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=datamapper') }
      silence_logger { generate(:model, 'user', "name:string", "age:integer", "created_at:datetime", "-r=#{@apptmp}/sample_project") }
      silence_logger { generate(:model, 'person', "name:string", "age:integer", "created_at:datetime", "-r=#{@apptmp}/sample_project") }
      silence_logger { generate(:model, 'account', "name:string", "age:integer", "created_at:datetime", "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class User\n\s+include DataMapper::Resource/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/migration 1, :create_users do/m, "#{@apptmp}/sample_project/db/migrate/001_create_users.rb")
      assert_match_in_file(/class Person\n\s+include DataMapper::Resource/m, "#{@apptmp}/sample_project/models/person.rb")
      assert_match_in_file(/migration 2, :create_people do/m, "#{@apptmp}/sample_project/db/migrate/002_create_people.rb")
      assert_match_in_file(/class Account\n\s+include DataMapper::Resource/m, "#{@apptmp}/sample_project/models/account.rb")
      assert_match_in_file(/migration 3, :create_accounts do/m, "#{@apptmp}/sample_project/db/migrate/003_create_accounts.rb")
    end

    should "generate migration with given fields" do
      current_time = stop_time_for_test.strftime("%Y%m%d%H%M%S")
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=datamapper') }
      silence_logger { generate(:model, 'person', "name:string", "created_at:date_time", "email:string", "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class Person\n\s+include DataMapper::Resource/m, "#{@apptmp}/sample_project/models/person.rb")
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_create_people.rb"
      assert_match_in_file(/migration 1, :create_people do/m, migration_file_path)
      assert_match_in_file(/create_table :people do/m, migration_file_path)
      assert_match_in_file(/column :name, String/m, migration_file_path)
      assert_match_in_file(/column :created_at, DateTime/m, migration_file_path)
      assert_match_in_file(/column :email, String/m, migration_file_path)
      assert_match_in_file(/drop_table :people/m, migration_file_path)
    end
  end

  # SEQUEL
  context "model generator using sequel" do
    should "generate model file with given properties" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=sequel') }
      silence_logger { generate(:model, 'user', "name:string", "age:integer", "created:datetime", "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class User < Sequel::Model/m, "#{@apptmp}/sample_project/models/user.rb")
    end

    should "generate model file with camelized name" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=sequel') }
      silence_logger { generate(:model, 'ChunkyBacon', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class ChunkyBacon < Sequel::Model/m, "#{@apptmp}/sample_project/models/chunky_bacon.rb")
      assert_match_in_file(/ChunkyBacon Model/, "#{@apptmp}/sample_project/test/models/chunky_bacon_test.rb")
    end

    should "generate migration file with given properties" do
      current_time = stop_time_for_test.strftime("%Y%m%d%H%M%S")
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=sequel') }
      silence_logger { generate(:model, 'person', "name:string", "age:integer", "created:datetime", "-r=#{@apptmp}/sample_project") }
      migration_file_path = "#{@apptmp}/sample_project/db/migrate/001_create_people.rb"
      assert_match_in_file(/class Person < Sequel::Model/m, "#{@apptmp}/sample_project/models/person.rb")
      assert_match_in_file(/class CreatePeople < Sequel::Migration/m, migration_file_path)
      assert_match_in_file(/create_table :people/m, migration_file_path)
      assert_match_in_file(/String :name/m,   migration_file_path)
      assert_match_in_file(/Integer :age/m,   migration_file_path)
      assert_match_in_file(/DateTime :created/m,  migration_file_path)
      assert_match_in_file(/drop_table :people/m, migration_file_path)
    end
  end

  # MONGODB
  context "model generator using mongomapper" do
    should "generate model file with no properties" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=mongomapper') }
      silence_logger { generate(:model, 'person', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class Person\n\s+include MongoMapper::Document/m, "#{@apptmp}/sample_project/models/person.rb")
      assert_match_in_file(/# key <name>, <type>/m, "#{@apptmp}/sample_project/models/person.rb")
      assert_match_in_file(/timestamps![\n\s]+end/m, "#{@apptmp}/sample_project/models/person.rb")
    end

    should "generate model file with given fields" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=mongomapper') }
      silence_logger { generate(:model, 'user', "name:string", "age:integer", "email:string", "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class User\n\s+include MongoMapper::Document/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/key :name, String/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/key :age, Integer/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/key :email, String/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/timestamps!/m, "#{@apptmp}/sample_project/models/user.rb")
    end
  end

  context "model generator using mongoid" do
    should "generate model file with no properties" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=mongoid') }
      silence_logger { generate(:model, 'person', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class Person\n\s+include Mongoid::Document/m, "#{@apptmp}/sample_project/models/person.rb")
      assert_match_in_file(/# field <name>, :type => <type>, :default => <value>/m, "#{@apptmp}/sample_project/models/person.rb")
    end

    should "generate model file with given fields" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=mongoid') }
      silence_logger { generate(:model, 'user', "name:string", "age:integer", "email:string", "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class User\n\s+include Mongoid::Document/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/field :name, :type => String/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/field :age, :type => Integer/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/field :email, :type => String/m, "#{@apptmp}/sample_project/models/user.rb")
    end
  end

  # REDIS
  context "model generator using ohm" do
    should "generate model file with no properties" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=ohm') }
      silence_logger { generate(:model, 'person', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class Person < Ohm::Model/, "#{@apptmp}/sample_project/models/person.rb")
      assert_match_in_file(/include Ohm::Timestamping/, "#{@apptmp}/sample_project/models/person.rb")
      assert_match_in_file(/include Ohm::Typecast/, "#{@apptmp}/sample_project/models/person.rb")
      assert_match_in_file(/# attribute :name/m, "#{@apptmp}/sample_project/models/person.rb")
      assert_match_in_file(/# reference :venue, Venue/m, "#{@apptmp}/sample_project/models/person.rb")
    end

    should "generate model file with given fields" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=ohm') }
      silence_logger { generate(:model, 'user', "name:string", "age:integer", "email:string", "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class User < Ohm::Model/, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/attribute :name, String/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/attribute :age, Integer/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/attribute :email, String/m, "#{@apptmp}/sample_project/models/user.rb")
    end
  end

  # MONGOMATIC
  context "model generator using mongomatic" do
    should "generate model file with no properties" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=mongomatic') }
      silence_logger { generate(:model, 'person', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class Person < Mongomatic::Base/, "#{@apptmp}/sample_project/models/person.rb")
      assert_match_in_file(/include Mongomatic::Expectations::Helper/m, "#{@apptmp}/sample_project/models/person.rb")
    end

    should "generate model file with given fields" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=mongomatic') }
      silence_logger { generate(:model, 'user', "name:string", "age:integer", "email:string", "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class User < Mongomatic::Base/, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/include Mongomatic::Expectations::Helper/, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/be_present self\['name'\]/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/be_present self\['age'\]/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/be_present self\['email'\]/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/be_a_number self\['age'\]/m, "#{@apptmp}/sample_project/models/user.rb")
    end
  end

  # RIPPLE
  context "model generator using ripple" do
    should "generate model file with no properties" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=ripple') }
      silence_logger { generate(:model, 'person', "name:string", "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class Person\n\s+include Ripple::Document/m, "#{@apptmp}/sample_project/models/person.rb")
      assert_match_in_file(/# property :name, String/m, "#{@apptmp}/sample_project/models/person.rb")
      assert_match_in_file(/# many :addresses/m, "#{@apptmp}/sample_project/models/person.rb")
      assert_match_in_file(/# one :account/m, "#{@apptmp}/sample_project/models/person.rb")
    end

    should "generate model file with given fields" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-d=ripple') }
      silence_logger { generate(:model, 'user', "name:string", "age:integer", "email:string", "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class User\n\s+include Ripple::Document/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/property :name, String/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/property :age, Integer/m, "#{@apptmp}/sample_project/models/user.rb")
      assert_match_in_file(/property :email, String/m, "#{@apptmp}/sample_project/models/user.rb")
    end
  end

  context "model generator testing files" do
    # BACON
    should "generate test file for bacon" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
      silence_logger { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      silence_logger { generate(:model, 'SomeUser', "-a=/subby", "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/describe "SomeUser Model"/m, "#{@apptmp}/sample_project/test/subby/models/some_user_test.rb")
      assert_match_in_file(/@some_user = SomeUser.new/m, "#{@apptmp}/sample_project/test/subby/models/some_user_test.rb")
      assert_match_in_file(/@some_user\.should\.not\.be\.nil/m, "#{@apptmp}/sample_project/test/subby/models/some_user_test.rb")
    end

    # RIOT
    should "generate test file for riot" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=riot', '-d=activerecord') }
      silence_logger { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      silence_logger { generate(:model, 'SomeUser', "-a=/subby", "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/context "SomeUser Model" do/m, "#{@apptmp}/sample_project/test/subby/models/some_user_test.rb")
      assert_match_in_file(/SomeUser.new/m, "#{@apptmp}/sample_project/test/subby/models/some_user_test.rb")
      assert_match_in_file(/asserts\("that record is not nil"\) \{ \!topic.nil\? \}/m, "#{@apptmp}/sample_project/test/subby/models/some_user_test.rb")
    end

    # RSPEC
    should "generate test file for rspec" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=rspec', '-d=activerecord') }
      silence_logger { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      silence_logger { generate(:model, 'SomeUser', "-a=/subby", "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/describe "SomeUser Model"/m, "#{@apptmp}/sample_project/spec/subby/models/some_user_spec.rb")
      assert_match_in_file(/let\(:some_user\) \{ SomeUser.new \}/m, "#{@apptmp}/sample_project/spec/subby/models/some_user_spec.rb")
      assert_match_in_file(/some_user\.should_not be_nil/m, "#{@apptmp}/sample_project/spec/subby/models/some_user_spec.rb")
    end

    # SHOULDA
    should "generate test file for shoulda" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=shoulda', '-d=activerecord') }
      silence_logger { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      silence_logger { generate(:model, 'SomePerson', "-a=/subby", "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/class SomePersonTest < Test::Unit::TestCase/m, "#{@apptmp}/sample_project/test/subby/models/some_person_test.rb")
      assert_match_in_file(/context "SomePerson Model"/m, "#{@apptmp}/sample_project/test/subby/models/some_person_test.rb")
      assert_match_in_file(/@some_person = SomePerson.new/m, "#{@apptmp}/sample_project/test/subby/models/some_person_test.rb")
      assert_match_in_file(/assert_not_nil @some_person/m, "#{@apptmp}/sample_project/test/subby/models/some_person_test.rb")
    end

    # TESTSPEC
    should "generate test file for testspec" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=testspec', '-d=activerecord') }
      silence_logger { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      silence_logger { generate(:model, 'SomeUser', "-a=/subby", "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/context "SomeUser Model"/m, "#{@apptmp}/sample_project/test/subby/models/some_user_test.rb")
      assert_match_in_file(/@some_user = SomeUser.new/m, "#{@apptmp}/sample_project/test/subby/models/some_user_test.rb")
      assert_match_in_file(/@some_user\.should\.not\.be\.nil/m, "#{@apptmp}/sample_project/test/subby/models/some_user_test.rb")
    end
  end

  context "the model destroy option" do

    should "destroy the model file" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
      silence_logger { generate(:model, 'User', "-r=#{@apptmp}/sample_project") }
      silence_logger { generate(:model, 'User', "-r=#{@apptmp}/sample_project", '-d') }
      assert_no_file_exists("#{@apptmp}/sample_project/models/user.rb")
      assert_no_file_exists("#{@apptmp}/sample_project/test/models/user_test.rb")
      assert_no_file_exists("#{@apptmp}/sample_project/db/migrate/001_create_users.rb")
    end

    should "destroy the model test file with rspec" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=rspec', '-d=activerecord') }
      silence_logger { generate(:model, 'User', "-r=#{@apptmp}/sample_project") }
      silence_logger { generate(:model, 'User', "-r=#{@apptmp}/sample_project", '-d') }
      assert_no_file_exists("#{@apptmp}/sample_project/spec/models/user_spec.rb")
    end

    should "destroy the model test file in a sub app" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon', '-d=activerecord') }
      silence_logger { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      silence_logger { generate(:model, 'User', "-a=/subby","-r=#{@apptmp}/sample_project") }
      silence_logger { generate(:model, 'User', "-a=/subby","-r=#{@apptmp}/sample_project", '-d') }
      assert_no_file_exists("#{@apptmp}/sample_project/subby/models/user.rb")
      assert_no_file_exists("#{@apptmp}/sample_project/test/subby/models/user_test.rb")
      assert_no_file_exists("#{@apptmp}/sample_project/db/migrate/001_create_users.rb")
    end

    should "destroy the right model migration" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=rspec', '-d=activerecord') }
      silence_logger { generate(:model, 'bar_foo', "-r=#{@apptmp}/sample_project") }
      silence_logger { generate(:model, 'foo', "-r=#{@apptmp}/sample_project") }
      silence_logger { generate(:model, 'foo', "-r=#{@apptmp}/sample_project", '-d') }
      assert_no_file_exists("#{@apptmp}/sample_project/db/migrate/002_create_foos.rb")
      assert_file_exists("#{@apptmp}/sample_project/db/migrate/001_create_bar_foos.rb")
    end
  end
end
