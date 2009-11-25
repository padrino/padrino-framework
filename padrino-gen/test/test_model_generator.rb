require File.dirname(__FILE__) + '/helper'
require 'thor'

class TestModelGenerator < Test::Unit::TestCase
  def setup
    @skeleton = Padrino::Generators::Skeleton.dup
    @model_gen = Padrino::Generators::Model.dup
    `rm -rf /tmp/sample_app`
  end

  context 'the model generator' do
    should "fail outside app root" do
      output = silence_logger { @model_gen.start(['user', '-r=/tmp']) }
      assert_match(/not at the root/, output)
      assert_no_file_exists('/tmp/app/models/user.rb')
    end

    should "generate only generate model once" do
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=bacon', '-d=activerecord']) }
      response_success = silence_logger { @model_gen.start(['user', '-r=/tmp/sample_app']) }
      response_duplicate = silence_logger { @model_gen.start(['user', '-r=/tmp/sample_app']) }
      assert_match_in_file(/class User < ActiveRecord::Base/m, '/tmp/sample_app/app/models/user.rb')
      assert_match /'user' model has already been generated!/, response_duplicate
    end
  end

  # ACTIVERECORD
  context "model generator using activerecord" do
    should "generate model file" do
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=bacon', '-d=activerecord']) }
      silence_logger { @model_gen.start(['user', '-r=/tmp/sample_app']) }
      assert_match_in_file(/class User < ActiveRecord::Base/m, '/tmp/sample_app/app/models/user.rb')
    end

    should "generate migration file with no fields" do
      current_time = stop_time_for_test
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=bacon', '-d=activerecord']) }
      silence_logger { @model_gen.start(['user', '-r=/tmp/sample_app']) }
      migration_file_path = "/tmp/sample_app/db/migrate/#{current_time.to_i}_create_users.rb"
      assert_match_in_file(/class CreateUsers < ActiveRecord::Migration/m, migration_file_path)
      assert_match_in_file(/create_table :users/m, migration_file_path)
      assert_match_in_file(/# t.column :age, :integer[\n\s]+?end/m, migration_file_path)
      assert_match_in_file(/drop_table :users/m, migration_file_path)
    end

    should "generate migration file with given fields" do
      current_time = stop_time_for_test
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=bacon', '-d=activerecord']) }
      silence_logger { @model_gen.start(['person', "name:string", "age:integer", "email:string", '-r=/tmp/sample_app']) }
      migration_file_path = "/tmp/sample_app/db/migrate/#{current_time.to_i}_create_people.rb"
      assert_match_in_file(/class CreatePeople < ActiveRecord::Migration/m, migration_file_path)
      assert_match_in_file(/create_table :people/m, migration_file_path)
      assert_match_in_file(/# t.column :age, :integer/m, migration_file_path)
      assert_match_in_file(/t.column :name, :string/m,   migration_file_path)
      assert_match_in_file(/t.column :age, :integer/m,   migration_file_path)
      assert_match_in_file(/t.column :email, :string/m,  migration_file_path)
      assert_match_in_file(/drop_table :people/m, migration_file_path)
    end
  end

  # COUCHREST
  context "model generator using couchrest" do
    should "generate model file with no properties" do
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=bacon', '-d=couchrest']) }
      silence_logger { @model_gen.start(['user', '-r=/tmp/sample_app']) }
      assert_match_in_file(/class User < CouchRest::ExtendedDocument/m, '/tmp/sample_app/app/models/user.rb')
      assert_match_in_file(/use_database app \{ couchdb \}/m, '/tmp/sample_app/app/models/user.rb')
      assert_match_in_file(/# property <name>[\s\n]+?end/m, '/tmp/sample_app/app/models/user.rb')
    end

    should "generate model file with given fields" do
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=bacon', '-d=couchrest']) }
      silence_logger { @model_gen.start(['person', "name:string", "age", "email:string", '-r=/tmp/sample_app']) }
      assert_match_in_file(/class Person < CouchRest::ExtendedDocument/m, '/tmp/sample_app/app/models/person.rb')
      assert_match_in_file(/use_database app \{ couchdb \}/m, '/tmp/sample_app/app/models/person.rb')
      assert_match_in_file(/property :name/m, '/tmp/sample_app/app/models/person.rb')
      assert_match_in_file(/property :age/m, '/tmp/sample_app/app/models/person.rb')
      assert_match_in_file(/property :email/m, '/tmp/sample_app/app/models/person.rb')
    end
  end

  # DATAMAPPER
  context "model generator using datamapper" do
    should "generate model file with fields" do
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-d=datamapper']) }
      silence_logger { @model_gen.start(['user', "name:string", "age:integer", "created_at:datetime", '-r=/tmp/sample_app']) }
      assert_match_in_file(/class User\n\s+include DataMapper::Resource/m, '/tmp/sample_app/app/models/user.rb')
      assert_match_in_file(/property :name, String/m, '/tmp/sample_app/app/models/user.rb')
      assert_match_in_file(/property :age, Integer/m, '/tmp/sample_app/app/models/user.rb')
      assert_match_in_file(/property :created_at, DateTime/m, '/tmp/sample_app/app/models/user.rb')
    end

    should "generate migration with given fields" do
      current_time = stop_time_for_test
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-d=datamapper']) }
      silence_logger { @model_gen.start(['person', "name:string", "age:integer", "email:string", '-r=/tmp/sample_app']) }
      assert_match_in_file(/class Person\n\s+include DataMapper::Resource/m, '/tmp/sample_app/app/models/person.rb')
      migration_file_path = "/tmp/sample_app/db/migrate/#{current_time.to_i}_create_people.rb"
      assert_match_in_file(/migration NUM, :create_people do/m, migration_file_path)
      assert_match_in_file(/create_table\(:people\) do/m, migration_file_path)
      assert_match_in_file(/column\(:name, String\)/m, migration_file_path)
      assert_match_in_file(/column\(:age, Integer\)/m, migration_file_path)
      assert_match_in_file(/column\(:email, String\)/m, migration_file_path)
      assert_match_in_file(/drop_table\(:people\)/m, migration_file_path)
    end
  end

  # MONGOMAPPER
  context "model generator using mongomapper" do
    should "generate migration file with given fields" do
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-d=mongomapper']) }
      silence_logger { @model_gen.start(['person', '-r=/tmp/sample_app']) }
      assert_match_in_file(/class Person\n\s+include MongoMapper::Document/m, '/tmp/sample_app/app/models/person.rb')
      assert_match_in_file(/# key <name>, <type>[\n\s]+end/m, '/tmp/sample_app/app/models/person.rb')
    end

    should "generate model file with given fields" do
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-d=mongomapper']) }
      silence_logger { @model_gen.start(['user', "name:string", "age:integer", "email:string", '-r=/tmp/sample_app']) }
      assert_match_in_file(/class User\n\s+include MongoMapper::Document/m, '/tmp/sample_app/app/models/user.rb')
      assert_match_in_file(/key :name, String/m, '/tmp/sample_app/app/models/user.rb')
      assert_match_in_file(/key :age, Integer/m, '/tmp/sample_app/app/models/user.rb')
      assert_match_in_file(/key :email, String/m, '/tmp/sample_app/app/models/user.rb')
    end
  end

  # SEQUEL
  context "model generator using sequel" do
    should "generate model file with given properties" do
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-d=sequel']) }
      silence_logger { @model_gen.start(['user', "name:string", "age:integer", "email:string", '-r=/tmp/sample_app']) }
      assert_match_in_file(/class User < Sequel::Model/m, '/tmp/sample_app/app/models/user.rb')
    end

    should "generate migration file with given properties" do
      current_time = stop_time_for_test
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-d=sequel']) }
      silence_logger { @model_gen.start(['person', "name:string", "age:integer", "email:string", '-r=/tmp/sample_app']) }
      migration_file_path = "/tmp/sample_app/db/migrate/#{current_time.to_i}_create_people.rb"
      assert_match_in_file(/class Person < Sequel::Model/m, '/tmp/sample_app/app/models/person.rb')
      assert_match_in_file(/class CreatePeople < Sequel::Migration/m, migration_file_path)
      assert_match_in_file(/create_table :people/m, migration_file_path)
      assert_match_in_file(/string :name/m,   migration_file_path)
      assert_match_in_file(/integer :age/m,   migration_file_path)
      assert_match_in_file(/string :email/m,  migration_file_path)
      assert_match_in_file(/drop_table :people/m, migration_file_path)
    end
  end

  context "model generator testing files" do
    # BACON
    should "generate test file for bacon" do
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=bacon', '-d=activerecord']) }
      silence_logger { @model_gen.start(['User', '-r=/tmp/sample_app']) }
      assert_match_in_file(/describe "User Model"/m, '/tmp/sample_app/test/models/user_test.rb')
      assert_match_in_file(/@user = User.new/m, '/tmp/sample_app/test/models/user_test.rb')
      assert_match_in_file(/@user\.should\.not\.be\.nil/m, '/tmp/sample_app/test/models/user_test.rb')
    end

    # RIOT
    should "generate test file for riot" do
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=riot', '-d=activerecord']) }
      silence_logger { @model_gen.start(['User', '-r=/tmp/sample_app']) }
      assert_match_in_file(/context "User Model" do/m, '/tmp/sample_app/test/models/user_test.rb')
      assert_match_in_file(/@user = User.new/m, '/tmp/sample_app/test/models/user_test.rb')
      assert_match_in_file(/asserts\("that record is not nil"\) \{ \!@user.nil\? \}/m, '/tmp/sample_app/test/models/user_test.rb')
    end

    # RSPEC
    should "generate test file for rspec" do
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=rspec', '-d=activerecord']) }
      silence_logger { @model_gen.start(['User', '-r=/tmp/sample_app']) }
      assert_match_in_file(/describe "User Model"/m, '/tmp/sample_app/test/models/user_spec.rb')
      assert_match_in_file(/@user = User.new/m, '/tmp/sample_app/test/models/user_spec.rb')
      assert_match_in_file(/@user\.should\.not\.be\snil/m, '/tmp/sample_app/test/models/user_spec.rb')
    end

    # SHOULDA
    should "generate test file for shoulda" do
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=shoulda', '-d=activerecord']) }
      silence_logger { @model_gen.start(['Person', '-r=/tmp/sample_app']) }
      assert_match_in_file(/class PersonControllerTest < Test::Unit::TestCase/m, '/tmp/sample_app/test/models/person_test.rb')
      assert_match_in_file(/context "Person Model"/m, '/tmp/sample_app/test/models/person_test.rb')
      assert_match_in_file(/@person = Person.new/m, '/tmp/sample_app/test/models/person_test.rb')
      assert_match_in_file(/assert_not_nil @person/m, '/tmp/sample_app/test/models/person_test.rb')
    end

    # TESTSPEC
    should "generate test file for testspec" do
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=testspec', '-d=activerecord']) }
      silence_logger { @model_gen.start(['User', '-r=/tmp/sample_app']) }
      assert_match_in_file(/context "User Model"/m, '/tmp/sample_app/test/models/user_test.rb')
      assert_match_in_file(/@user = User.new/m, '/tmp/sample_app/test/models/user_test.rb')
      assert_match_in_file(/@user\.should\.not\.be\.nil/m, '/tmp/sample_app/test/models/user_test.rb')
    end
  end

end
