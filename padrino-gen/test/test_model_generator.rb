require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestModelGenerator < Test::Unit::TestCase
  def setup
    `rm -rf /tmp/sample_project`
  end

  context 'the model generator' do
    should "fail outside app root" do
      output = silence_logger { generate(:model, 'user', '-r=/tmp') }
      assert_match(/not at the root/, output)
      assert_no_file_exists('/tmp/app/models/user.rb')
    end

    should "generate filename properly" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon', '-d=couchrest') }
      silence_logger { generate(:model, 'DemoItem', "name:string", "age", "email:string", '-r=/tmp/sample_project') }
      assert_file_exists('/tmp/sample_project/app/models/demo_item.rb')
    end

    should "fail if field name is not acceptable" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon', '-d=couchrest') }
      output = silence_logger { generate(:model, 'DemoItem', "re@l$ly:string","display-name:string", "age&year:datetime", "email_two:string", '-r=/tmp/sample_project') }
      assert_match(/Invalid field name:/, output)
      assert_match(/display-name:string/, output)
      assert_match(/age&year:datetime/, output)
      assert_match(/re@l\$ly:string/, output)
      assert_no_match(/email_two:string/, output)
      assert_no_match(/apply/, output)
      assert_no_file_exists('/tmp/sample_project/app/models/demo_item.rb')
    end

    should "fail if we don't use an adapter" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon') }
      assert_raise(SystemExit) { silence_logger { generate(:model, 'user', '-r=/tmp/sample_project') } }
    end

    should "not fail if we don't have test component" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--test=none', '-d=activerecord') }
      response_success = silence_logger { generate(:model, 'user', '-r=/tmp/sample_project') }
      assert_match_in_file(/class User < ActiveRecord::Base/m, '/tmp/sample_project/app/models/user.rb')
      assert_no_file_exists('/tmp/sample_project/test')
    end

    should "generate model in specified app" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '-d=datamapper', '--script=none', '-t=bacon') }
      silence_logger { generate(:app, 'subby', '-r=/tmp/sample_project') }
      silence_logger { generate(:model, 'Post', "body:string", '-a=/subby', '-r=/tmp/sample_project') }
      assert_match_in_file(/class Post\n\s+include DataMapper::Resource/m, '/tmp/sample_project/subby/models/post.rb')
      assert_match_in_file(/property :body, String/m, '/tmp/sample_project/subby/models/post.rb')
      assert_match_in_file(/migration 1, :create_posts do/m, "/tmp/sample_project/db/migrate/001_create_posts.rb")
      assert_match_in_file(/gem 'data_mapper'/m,'/tmp/sample_project/Gemfile')
    end

    should "generate only generate model once" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon', '-d=activerecord') }
      response_success = silence_logger { generate(:model, 'user', '-r=/tmp/sample_project') }
      response_duplicate = silence_logger { generate(:model, 'user', '-r=/tmp/sample_project') }
      assert_match_in_file(/class User < ActiveRecord::Base/m, '/tmp/sample_project/app/models/user.rb')
      assert_match "identical\e[0m  app/models/user.rb", response_duplicate
      assert_match "identical\e[0m  test/models/user_test.rb", response_duplicate
    end

    should "generate migration file versions properly" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon', '-d=activerecord') }
      silence_logger { generate(:model, 'user', '-r=/tmp/sample_project') }
      silence_logger { generate(:model, 'account', '-r=/tmp/sample_project') }
      silence_logger { generate(:model, 'bank', '-r=/tmp/sample_project') }
      assert_file_exists('/tmp/sample_project/db/migrate/001_create_users.rb')
      assert_file_exists('/tmp/sample_project/db/migrate/002_create_accounts.rb')
      assert_file_exists('/tmp/sample_project/db/migrate/003_create_banks.rb')
    end
  end

  # ACTIVERECORD
  context "model generator using activerecord" do
    should "generate model file" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon', '-d=activerecord') }
      silence_logger { generate(:model, 'user', '-r=/tmp/sample_project') }
      assert_match_in_file(/class User < ActiveRecord::Base/m, '/tmp/sample_project/app/models/user.rb')
    end

    should "generate migration file with no fields" do
      current_time = stop_time_for_test.strftime("%Y%m%d%H%M%S")
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon', '-d=activerecord') }
      silence_logger { generate(:model, 'user', '-r=/tmp/sample_project') }
      migration_file_path = "/tmp/sample_project/db/migrate/001_create_users.rb"
      assert_match_in_file(/class CreateUsers < ActiveRecord::Migration/m, migration_file_path)
      assert_match_in_file(/create_table :users/m, migration_file_path)
      assert_match_in_file(/drop_table :users/m, migration_file_path)
    end

    should "generate migration file with given fields" do
      current_time = stop_time_for_test.strftime("%Y%m%d%H%M%S")
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon', '-d=activerecord') }
      silence_logger { generate(:model, 'person', "name:string", "age:integer", "email:string", '-r=/tmp/sample_project') }
      migration_file_path = "/tmp/sample_project/db/migrate/001_create_people.rb"
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
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon', '-d=couchrest') }
      silence_logger { generate(:model, 'user', '-r=/tmp/sample_project') }
      assert_match_in_file(/class User < CouchRest::ExtendedDocument/m, '/tmp/sample_project/app/models/user.rb')
      assert_match_in_file(/use_database COUCHDB/m, '/tmp/sample_project/app/models/user.rb')
      assert_match_in_file(/# property <name>[\s\n]+?end/m, '/tmp/sample_project/app/models/user.rb')
    end

    should "generate model file with given fields" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon', '-d=couchrest') }
      silence_logger { generate(:model, 'person', "name:string", "age", "email:string", '-r=/tmp/sample_project') }
      assert_match_in_file(/class Person < CouchRest::ExtendedDocument/m, '/tmp/sample_project/app/models/person.rb')
      assert_match_in_file(/use_database COUCHDB/m, '/tmp/sample_project/app/models/person.rb')
      assert_match_in_file(/property :name/m, '/tmp/sample_project/app/models/person.rb')
      assert_match_in_file(/property :age/m, '/tmp/sample_project/app/models/person.rb')
      assert_match_in_file(/property :email/m, '/tmp/sample_project/app/models/person.rb')
    end
  end

  # DATAMAPPER
  context "model generator using datamapper" do

    should "generate gemfile gem" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-d=datamapper') }
      silence_logger { generate(:model, 'user', "name:string", "age:integer", "created_at:datetime", '-r=/tmp/sample_project') }
      assert_match_in_file(/gem 'data_mapper'/m,'/tmp/sample_project/Gemfile')
    end

    should "generate model file with fields" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-d=datamapper') }
      silence_logger { generate(:model, 'user', "name:string", "age:integer", "created_at:datetime", '-r=/tmp/sample_project') }
      assert_match_in_file(/class User\n\s+include DataMapper::Resource/m, '/tmp/sample_project/app/models/user.rb')
      assert_match_in_file(/property :name, String/m, '/tmp/sample_project/app/models/user.rb')
      assert_match_in_file(/property :age, Integer/m, '/tmp/sample_project/app/models/user.rb')
      assert_match_in_file(/property :created_at, DateTime/m, '/tmp/sample_project/app/models/user.rb')
    end

    should "properly generate version numbers" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-d=datamapper') }
      silence_logger { generate(:model, 'user', "name:string", "age:integer", "created_at:datetime", '-r=/tmp/sample_project') }
      silence_logger { generate(:model, 'person', "name:string", "age:integer", "created_at:datetime", '-r=/tmp/sample_project') }
      silence_logger { generate(:model, 'account', "name:string", "age:integer", "created_at:datetime", '-r=/tmp/sample_project') }
      assert_match_in_file(/class User\n\s+include DataMapper::Resource/m, '/tmp/sample_project/app/models/user.rb')
      assert_match_in_file(/migration 1, :create_users do/m, "/tmp/sample_project/db/migrate/001_create_users.rb")
      assert_match_in_file(/class Person\n\s+include DataMapper::Resource/m, '/tmp/sample_project/app/models/person.rb')
      assert_match_in_file(/migration 2, :create_people do/m, "/tmp/sample_project/db/migrate/002_create_people.rb")
      assert_match_in_file(/class Account\n\s+include DataMapper::Resource/m, '/tmp/sample_project/app/models/account.rb')
      assert_match_in_file(/migration 3, :create_accounts do/m, "/tmp/sample_project/db/migrate/003_create_accounts.rb")
    end

    should "generate migration with given fields" do
      current_time = stop_time_for_test.strftime("%Y%m%d%H%M%S")
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-d=datamapper') }
      silence_logger { generate(:model, 'person', "name:string", "created_at:date_time", "email:string", '-r=/tmp/sample_project') }
      assert_match_in_file(/class Person\n\s+include DataMapper::Resource/m, '/tmp/sample_project/app/models/person.rb')
      migration_file_path = "/tmp/sample_project/db/migrate/001_create_people.rb"
      assert_match_in_file(/migration 1, :create_people do/m, migration_file_path)
      assert_match_in_file(/create_table :people do/m, migration_file_path)
      assert_match_in_file(/column :name, DataMapper::Property::String/m, migration_file_path)
      assert_match_in_file(/column :created_at, DataMapper::Property::DateTime/m, migration_file_path)
      assert_match_in_file(/column :email, DataMapper::Property::String/m, migration_file_path)
      assert_match_in_file(/drop_table :people/m, migration_file_path)
    end
  end

  # MONGOMAPPER
  context "model generator using mongomapper" do
    should "generate model file with no properties" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-d=mongomapper') }
      silence_logger { generate(:model, 'person', '-r=/tmp/sample_project') }
      assert_match_in_file(/class Person\n\s+include MongoMapper::Document/m, '/tmp/sample_project/app/models/person.rb')
      assert_match_in_file(/# key <name>, <type>/m, '/tmp/sample_project/app/models/person.rb')
      assert_match_in_file(/timestamps![\n\s]+end/m, '/tmp/sample_project/app/models/person.rb')
    end

    should "generate model file with given fields" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-d=mongomapper') }
      silence_logger { generate(:model, 'user', "name:string", "age:integer", "email:string", '-r=/tmp/sample_project') }
      assert_match_in_file(/class User\n\s+include MongoMapper::Document/m, '/tmp/sample_project/app/models/user.rb')
      assert_match_in_file(/key :name, String/m, '/tmp/sample_project/app/models/user.rb')
      assert_match_in_file(/key :age, Integer/m, '/tmp/sample_project/app/models/user.rb')
      assert_match_in_file(/key :email, String/m, '/tmp/sample_project/app/models/user.rb')
      assert_match_in_file(/timestamps!/m, '/tmp/sample_project/app/models/user.rb')
    end
  end

  context "model generator using mongoid" do
    should "generate model file with no properties" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-d=mongoid') }
      silence_logger { generate(:model, 'person', '-r=/tmp/sample_project') }
      assert_match_in_file(/class Person\n\s+include Mongoid::Document/m, '/tmp/sample_project/app/models/person.rb')
      assert_match_in_file(/# field <name>, :type => <type>, :default => <value>/m, '/tmp/sample_project/app/models/person.rb')
    end

    should "generate model file with given fields" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-d=mongoid') }
      silence_logger { generate(:model, 'user', "name:string", "age:integer", "email:string", '-r=/tmp/sample_project') }
      assert_match_in_file(/class User\n\s+include Mongoid::Document/m, '/tmp/sample_project/app/models/user.rb')
      assert_match_in_file(/field :name, :type => String/m, '/tmp/sample_project/app/models/user.rb')
      assert_match_in_file(/field :age, :type => Integer/m, '/tmp/sample_project/app/models/user.rb')
      assert_match_in_file(/field :email, :type => String/m, '/tmp/sample_project/app/models/user.rb')
    end
  end

  # SEQUEL
  context "model generator using sequel" do
    should "generate model file with given properties" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-d=sequel') }
      silence_logger { generate(:model, 'user', "name:string", "age:integer", "created:datetime", '-r=/tmp/sample_project') }
      assert_match_in_file(/class User < Sequel::Model/m, '/tmp/sample_project/app/models/user.rb')
    end

    should "generate migration file with given properties" do
      current_time = stop_time_for_test.strftime("%Y%m%d%H%M%S")
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-d=sequel') }
      silence_logger { generate(:model, 'person', "name:string", "age:integer", "created:datetime", '-r=/tmp/sample_project') }
      migration_file_path = "/tmp/sample_project/db/migrate/001_create_people.rb"
      assert_match_in_file(/class Person < Sequel::Model/m, '/tmp/sample_project/app/models/person.rb')
      assert_match_in_file(/class CreatePeople < Sequel::Migration/m, migration_file_path)
      assert_match_in_file(/create_table :people/m, migration_file_path)
      assert_match_in_file(/String :name/m,   migration_file_path)
      assert_match_in_file(/Integer :age/m,   migration_file_path)
      assert_match_in_file(/DateTime :created/m,  migration_file_path)
      assert_match_in_file(/drop_table :people/m, migration_file_path)
    end
  end

  context "model generator testing files" do
    # BACON
    should "generate test file for bacon" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon', '-d=activerecord') }
      silence_logger { generate(:model, 'SomeUser', '-r=/tmp/sample_project') }
      assert_match_in_file(/describe "SomeUser Model"/m, '/tmp/sample_project/test/models/some_user_test.rb')
      assert_match_in_file(/@some_user = SomeUser.new/m, '/tmp/sample_project/test/models/some_user_test.rb')
      assert_match_in_file(/@some_user\.should\.not\.be\.nil/m, '/tmp/sample_project/test/models/some_user_test.rb')
    end

    # RIOT
    should "generate test file for riot" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=riot', '-d=activerecord') }
      silence_logger { generate(:model, 'SomeUser', '-r=/tmp/sample_project') }
      assert_match_in_file(/context "SomeUser Model" do/m, '/tmp/sample_project/test/models/some_user_test.rb')
      assert_match_in_file(/SomeUser.new/m, '/tmp/sample_project/test/models/some_user_test.rb')
      assert_match_in_file(/asserts\("that record is not nil"\) \{ \!topic.nil\? \}/m, '/tmp/sample_project/test/models/some_user_test.rb')
    end

    # RSPEC
    should "generate test file for rspec" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=rspec', '-d=activerecord') }
      silence_logger { generate(:model, 'SomeUser', '-r=/tmp/sample_project') }
      assert_match_in_file(/describe "SomeUser Model"/m, '/tmp/sample_project/spec/models/some_user_spec.rb')
      assert_match_in_file(/@some_user = SomeUser.new/m, '/tmp/sample_project/spec/models/some_user_spec.rb')
      assert_match_in_file(/@some_user\.should_not be_nil/m, '/tmp/sample_project/spec/models/some_user_spec.rb')
    end

    # SHOULDA
    should "generate test file for shoulda" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=shoulda', '-d=activerecord') }
      silence_logger { generate(:model, 'SomePerson', '-r=/tmp/sample_project') }
      assert_match_in_file(/class SomePersonControllerTest < Test::Unit::TestCase/m, '/tmp/sample_project/test/models/some_person_test.rb')
      assert_match_in_file(/context "SomePerson Model"/m, '/tmp/sample_project/test/models/some_person_test.rb')
      assert_match_in_file(/@some_person = SomePerson.new/m, '/tmp/sample_project/test/models/some_person_test.rb')
      assert_match_in_file(/assert_not_nil @some_person/m, '/tmp/sample_project/test/models/some_person_test.rb')
    end

    # TESTSPEC
    should "generate test file for testspec" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=testspec', '-d=activerecord') }
      silence_logger { generate(:model, 'SomeUser', '-r=/tmp/sample_project') }
      assert_match_in_file(/context "SomeUser Model"/m, '/tmp/sample_project/test/models/some_user_test.rb')
      assert_match_in_file(/@some_user = SomeUser.new/m, '/tmp/sample_project/test/models/some_user_test.rb')
      assert_match_in_file(/@some_user\.should\.not\.be\.nil/m, '/tmp/sample_project/test/models/some_user_test.rb')
    end
  end

  context "the model destroy option" do

    should "destroy the model file" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=bacon', '-d=activerecord') }
      silence_logger { generate(:model, 'User', '-r=/tmp/sample_project') }
      silence_logger { generate(:model, 'User', '-r=/tmp/sample_project', '-d') }
      assert_no_file_exists('/tmp/sample_project/app/models/user.rb')
      assert_no_file_exists('/tmp/sample_project/test/models/user_test.rb')
      assert_no_file_exists('/tmp/sample_project/db/migrate/001_create_users.rb')
    end

    should "destroy the model test file with rspec" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=rspec', '-d=activerecord') }
      silence_logger { generate(:model, 'User', '-r=/tmp/sample_project') }
      silence_logger { generate(:model, 'User', '-r=/tmp/sample_project', '-d') }
      assert_no_file_exists('/tmp/sample_project/spec/models/user_spec.rb')
    end

    should "destroy the model migration" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '-t=rspec', '-d=activerecord') }
      silence_logger { generate(:model, 'Person', '-r=/tmp/sample_project') }
      silence_logger { generate(:model, 'User', '-r=/tmp/sample_project') }
      silence_logger { generate(:model, 'User', '-r=/tmp/sample_project', '-d') }
      assert_no_file_exists('/tmp/sample_project/db/migrate/002_create_users.rb')
    end
  end
end