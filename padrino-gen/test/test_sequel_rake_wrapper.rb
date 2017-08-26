require File.expand_path(File.dirname(__FILE__) + '/helper')
require_relative '../lib/padrino-gen/padrino-tasks/sequel_rake_wrapper'

namespace :db do
  task :seed
end

describe Padrino::Generators::SequelRakeWrapper do
  let(:sequel_mock) { mock }
  let(:sequel_migrator_mock) { mock }
  let(:sequel_model_mock) { mock }
  let(:sql_helpers_mock) { mock }
  let(:sequel_db_opts_mock) { mock }
  let(:db_mock) { mock }
  let(:disconnect_mock) {mock }

  describe "#auto" do
    it "performs automigration (resets db data)" do
      sequel_mock.stubs(:extension).with(:migration).once

      sequel_model_mock.stubs(:db).at_most(2).returns(db_mock)

      sequel_migrator_mock.stubs(:run).once.with(db_mock, 'db/migrate', :target => 0)
      sequel_migrator_mock.stubs(:run).once.with(db_mock, 'db/migrate')

      sequel_wrapper = Padrino::Generators::SequelRakeWrapper.new(sequel_mock, sequel_migrator_mock, sequel_model_mock, sql_helpers_mock)
      assert_output(/<= sq:migrate:auto executed/) { sequel_wrapper.auto }
    end
  end

  describe "#to" do
    it "throws error if 'version' is not given" do
      sequel_wrapper = Padrino::Generators::SequelRakeWrapper.new(sequel_mock, sequel_migrator_mock, sequel_model_mock, sql_helpers_mock)

      sequel_mock.stubs(:extension).once.with(:migration)

      exception = assert_raises RuntimeError do
        sequel_wrapper.to
      end
      assert_equal 'No MIGRATION_VERSION was provided', exception.message
    end

    it "migrates to the given 'version'" do
      sequel_mock.stubs(:extension).once.with(:migration)

      sequel_model_mock.stubs(:db).once.returns(db_mock)
      sequel_migrator_mock.stubs(:apply).once.with(db_mock, 'db/migrate', 1)

      sequel_wrapper = Padrino::Generators::SequelRakeWrapper.new(sequel_mock, sequel_migrator_mock, sequel_model_mock, sql_helpers_mock)

      assert_output(/<= sq:migrate:to\[1\] executed/) { sequel_wrapper.to('1') }
    end
  end

  describe "#up" do
    it "migrates to the latest version" do
      sequel_mock.stubs(:extension).with(:migration).once

      sequel_model_mock.stubs(:db).once.returns(db_mock)

      sequel_migrator_mock.stubs(:run).once.with(db_mock, 'db/migrate')

      sequel_wrapper = Padrino::Generators::SequelRakeWrapper.new(sequel_mock, sequel_migrator_mock, sequel_model_mock, sql_helpers_mock)

      assert_output(/<= sq:migrate:up executed/) { sequel_wrapper.up }
    end
  end

  describe "#down" do
    it "erases all data" do
      sequel_mock.stubs(:extension).once.with(:migration)

      sequel_model_mock.stubs(:db).once.returns(db_mock)

      sequel_migrator_mock.stubs(:run).once.with(db_mock, 'db/migrate', :target => 0)

      sequel_wrapper = Padrino::Generators::SequelRakeWrapper.new(sequel_mock, sequel_migrator_mock, sequel_model_mock, sql_helpers_mock)

      assert_output(/<= sq:migrate:down executed/) { sequel_wrapper.down }
    end
  end

  describe "#create" do
    it "creates locale database with 'sqlite' adapter" do
      expected_credentials = {
        database: 'mochadatabase',
        adapter: 'sqlite3'
      }

      sequel_db_opts_mock.stubs(:opts).once.returns(expected_credentials)
      sequel_model_mock.stubs(:db).once.returns(sequel_db_opts_mock)

      sequel_mock.stubs(:sqlite).once.with('mochadatabase')

      sequel_wrapper = Padrino::Generators::SequelRakeWrapper.new(sequel_mock, sequel_migrator_mock, sequel_model_mock, sql_helpers_mock)

      expected_output = "=> Creating database 'mochadatabase'\n<= sq:create executed\n"
      assert_output (expected_output) { sequel_wrapper.create }
    end

    describe "collation and charset" do
      it "creates sql database with for given credentials and charset and collation" do
        expected_credentials = {
          database: 'mochadatabase',
          adapter: 'mochiadapter',
          user: 'mochamocha',
          password: 'mochikochi',
          host: 'padrinoovertheworld',
          charset: 'mochi_utf8',
          collation: 'mochi_utf8_unicode_ci'
        }

        sequel_model_mock.stubs(:db).once.returns(sequel_db_opts_mock)
        sequel_db_opts_mock.stubs(:opts).once.returns(expected_credentials)

        sequel_mock.stubs(:sqlite).with('mochadatabase').never
        sql_helpers_mock.stubs(:create_db).once.with('mochiadapter', 'mochamocha', 'mochikochi', 'padrinoovertheworld', 'mochadatabase', 'mochi_utf8', 'mochi_utf8_unicode_ci')

        sequel_wrapper = Padrino::Generators::SequelRakeWrapper.new(sequel_mock, sequel_migrator_mock, sequel_model_mock, sql_helpers_mock)

        expected_output = "=> Creating database 'mochadatabase'\n<= sq:create executed\n"

        clear_sql_helpers_from_loaded_features
        assert_equal false, $LOADED_FEATURES.grep(%r{padrino-gen/padrino-tasks/sql-helpers}).any?

        assert_output (expected_output) { sequel_wrapper.create }

        assert_equal true, $LOADED_FEATURES.grep(%r{padrino-gen/padrino-tasks/sql-helpers}).any?
      end

      it "takes values from ENV" do
        expected_credentials = {
          database: 'mochadatabase',
          adapter: 'mochiadapter',
          user: 'mochamocha',
          password: 'mochikochi',
          host: 'padrinoovertheworld'
        }
        ENV['CHARSET'] = 'mochi_utf8'
        ENV['COLLATION'] = 'mochi_utf8_unicode_ci'

        sequel_model_mock.stubs(:db).once.returns(sequel_db_opts_mock)
        sequel_db_opts_mock.stubs(:opts).once.returns(expected_credentials)

        sequel_mock.stubs(:sqlite).with('mochadatabase').never
        sql_helpers_mock.stubs(:create_db).with('mochiadapter', 'mochamocha', 'mochikochi', 'padrinoovertheworld', 'mochadatabase', 'mochi_utf8', 'mochi_utf8_unicode_ci').once

        sequel_wrapper = Padrino::Generators::SequelRakeWrapper.new(sequel_mock, sequel_migrator_mock, sequel_model_mock, sql_helpers_mock)

        expected_output = "=> Creating database 'mochadatabase'\n<= sq:create executed\n"

        clear_sql_helpers_from_loaded_features

        assert_equal false, $LOADED_FEATURES.grep(%r{padrino-gen/padrino-tasks/sql-helpers}).any?

        assert_output (expected_output) { sequel_wrapper.create }
        assert_equal true, $LOADED_FEATURES.grep(%r{padrino-gen/padrino-tasks/sql-helpers}).any?
      end

      it "takes default values" do
        expected_credentials = {
          database: 'mochadatabase',
          adapter: 'mochiadapter',
          user: 'mochamocha',
          password: 'mochikochi',
          host: 'padrinoovertheworld'
        }

        ENV['CHARSET'] = nil
        ENV['COLLATION'] = nil

        sequel_model_mock.stubs(:db).once.returns(sequel_db_opts_mock)
        sequel_db_opts_mock.stubs(:opts).once.returns(expected_credentials)

        sequel_mock.stubs(:sqlite).with('mochadatabase').never
        sql_helpers_mock.stubs(:create_db).with('mochiadapter', 'mochamocha', 'mochikochi', 'padrinoovertheworld', 'mochadatabase', 'utf8', 'utf8_unicode_ci').once

        sequel_wrapper = Padrino::Generators::SequelRakeWrapper.new(sequel_mock, sequel_migrator_mock, sequel_model_mock, sql_helpers_mock)

        clear_sql_helpers_from_loaded_features

        assert_equal false, $LOADED_FEATURES.grep(%r{padrino-gen/padrino-tasks/sql-helpers}).any?

        expected_output = "=> Creating database 'mochadatabase'\n<= sq:create executed\n"
        assert_output (expected_output) { sequel_wrapper.create }
        assert_equal true, $LOADED_FEATURES.grep(%r{padrino-gen/padrino-tasks/sql-helpers}).any?
      end
    end
  end

  describe "#drop" do
    describe "sqlite adapter" do
      it "deletes the database if it's there" do
        expected_credentials = {
          database: 'mochadatabase',
          adapter: 'sqlite3',
        }

        sequel_db_opts_mock.stubs(:opts).once.returns(expected_credentials)

        disconnect_mock.stubs(:disconnect).once

        sequel_model_mock.stubs(:db).at_most(2).returns(sequel_db_opts_mock, disconnect_mock)

        File.stubs(:exist?).once.with('mochadatabase').returns(true)
        File.stubs(:delete).once.with('mochadatabase')

        sequel_wrapper = Padrino::Generators::SequelRakeWrapper.new(sequel_mock, sequel_migrator_mock, sequel_model_mock, sql_helpers_mock)

        expected_output = "=> Dropping database 'mochadatabase'\n<= sq:drop executed\n"
        assert_output (expected_output) { sequel_wrapper.drop }
      end

      it "does not delete the database if it's not there" do
        expected_credentials = {
          database: 'mochadatabase',
          adapter: 'sqlite3'
        }

        sequel_db_opts_mock.stubs(:opts).once.returns(expected_credentials)

        disconnect_mock.stubs(:disconnect).once

        sequel_model_mock.stubs(:db).at_most(2).returns(sequel_db_opts_mock, disconnect_mock)

        File.stubs(:exist?).once.with('mochadatabase').returns(false)
        File.stubs(:delete).never.with('mochadatabase')

        sequel_wrapper = Padrino::Generators::SequelRakeWrapper.new(sequel_mock, sequel_migrator_mock, sequel_model_mock, sql_helpers_mock)

        expected_output = "=> Dropping database 'mochadatabase'\n<= sq:drop executed\n"
        assert_output (expected_output) { sequel_wrapper.drop }
      end
end
    describe "with no 'sqlite' adapter" do
      it "drops the database" do
        expected_credentials = {
          database: 'mochadatabase',
          adapter: 'mochiadapter',
          user: 'mochamocha',
          password: 'mochikochi',
          host: 'padrinoovertheworld',
          charset: 'mochi_utf8',
          collation: 'mochi_utf8_unicode_ci'
        }

        sequel_db_opts_mock.stubs(:opts).once.returns(expected_credentials)

        disconnect_mock.stubs(:disconnect).once

        sequel_model_mock.stubs(:db).at_most(2).returns(sequel_db_opts_mock, disconnect_mock)

        sql_helpers_mock.stubs(:drop_db).once.with('mochiadapter', 'mochamocha', 'mochikochi', 'padrinoovertheworld', 'mochadatabase')

        sequel_wrapper = Padrino::Generators::SequelRakeWrapper.new(sequel_mock, sequel_migrator_mock, sequel_model_mock, sql_helpers_mock)

        expected_output = "=> Dropping database 'mochadatabase'\n<= sq:drop executed\n"
        assert_output (expected_output) { sequel_wrapper.drop }
      end
    end
  end

  describe "#seed" do
    it "performs the seed to command to fill the database" do
      Padrino.stubs(:send).once.with(:default_dependency_paths).returns(2)
      Padrino.stubs(:send).once.with(:dependency_paths).returns(1)
      Padrino.stubs(:require_dependencies).once.with(1)
      Rake::Task['db:seed'].stubs(:invoke).once

      sequel_wrapper = Padrino::Generators::SequelRakeWrapper.new(sequel_mock, sequel_migrator_mock, sequel_model_mock, sql_helpers_mock)
      sequel_wrapper.seed
    end
  end
end

private

# deletes sql-helpers.rb file from the included files
def clear_sql_helpers_from_loaded_features
  sql_helpers_index = $LOADED_FEATURES.index { |s| s.include?('padrino-gen/padrino-tasks/sql-helpers.rb')}

  if sql_helpers_index
    $LOADED_FEATURES.delete_at sql_helpers_index
  end
end
