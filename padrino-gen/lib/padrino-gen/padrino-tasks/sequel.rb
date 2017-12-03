def get_sequel_rake_wrapper
  require 'sequel'
  require_relative 'sql-helpers'

  sequel = Sequel
  sequel.extension :migration, :core_extensions
  migrator = Sequel::Migrator
  model = Sequel::Model
  sql_helpers = Padrino::Generators::SqlHelpers

  Padrino::Generators::SequelRakeWrapper.new sequel, migrator, model, sql_helpers
end

if PadrinoTasks.load?(:sequel, defined?(Sequel))
  @sequel_rake_wrapper = get_sequel_rake_wrapper

  namespace :sq do
    namespace :migrate do

      desc "Perform automigration (reset your db data)"
      task :auto => :skeleton do
        @sequel_rake_wrapper.auto
      end

      desc "Perform migration up/down to MIGRATION_VERSION"
      task :to, [:version] => :skeleton do |t, args|
        version = (args[:version] || env_migration_version).to_s.strip
        @sequel_rake_wrapper.to version
      end

      desc "Perform migration up to latest migration available"
      task :up => :skeleton do
        @sequel_rake_wrapper.up
      end

      desc "Perform migration down (erase all data)"
      task :down => :skeleton do
        @sequel_rake_wrapper.down
      end
    end

    desc "Perform migration up to latest migration available"
    task :migrate => 'sq:migrate:up'

    desc "Create the database"
    task :create => :skeleton do
      @sequel_rake_wrapper.create
    end

    desc "Drop the database (postgres and mysql only)"
    task :drop => :skeleton do
      @sequel_rake_wrapper.drop
    end

    desc 'Drop the database, migrate from scratch and initialize with the seed data'
    task :reset => ['drop', 'create', 'migrate', 'seed']

    task :seed => :environment do
      @sequel_rake_wrapper.seed
    end
  end

  task 'db:create' => 'sq:create'
  task 'db:migrate' => 'sq:migrate'
  task 'db:reset' => 'sq:reset'
end
