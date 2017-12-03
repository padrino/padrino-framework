module Padrino
  module Generators
    # Wrap the sequel rake task
    class SequelRakeWrapper
      # A basic initialize method.
      #
      # @param sequel [Sequel]
      # @param sequel_migrator [Sequel::Migrator]
      # @param sequel_model [Sequel::Model]
      # @param sql_helpers [Padrino::Generators::SqlHelpers]
      def initialize(sequel, sequel_migrator, sequel_model, sql_helpers)
        @sequel = sequel
        @sequel_migrator = sequel_migrator
        @sequel_model = sequel_model
        @sql_helpers = sql_helpers
      end

      # Perform automigration (reset your db data)
      # @return [nil]
      def auto
        @sequel.extension :migration
        @sequel_migrator.run @sequel_model.db, 'db/migrate', :target => 0
        @sequel_migrator.run @sequel_model.db, 'db/migrate'
        puts '<= sq:migrate:auto executed'
      end

      # Perform migration up/down to MIGRATION_VERSION
      #
      # @param version [String]
      def to(version = '')
        @sequel.extension :migration
        fail "No MIGRATION_VERSION was provided" if version.empty?
        @sequel_migrator.apply @sequel_model.db, 'db/migrate', version.to_i
        puts "<= sq:migrate:to[#{version}] executed"
      end

      # Perform migration up to latest migration available
      def up
        @sequel.extension :migration
        @sequel_migrator.run @sequel_model.db, 'db/migrate'
        puts '<= sq:migrate:up executed'
      end

      # Perform migration down (erase all data)
      def down
        @sequel.extension :migration
        @sequel_migrator.run @sequel_model.db, 'db/migrate', :target => 0
        puts '<= sq:migrate:down executed'
      end

      # Create the database
      def create
        config = @sequel_model.db.opts
        user, password, host = config[:user], config[:password], config[:host]

        database = config[:database]
        charset = config[:charset] || ENV['CHARSET'] || 'utf8'
        collation = config[:collation] || ENV['COLLATION'] || 'utf8_unicode_ci'

        puts "=> Creating database '#{database}'"
        if config[:adapter] == 'sqlite3'
          @sequel.sqlite(database)
        else
          require 'padrino-gen/padrino-tasks/sql-helpers'
          @sql_helpers.create_db config[:adapter], config[:user], config[:password], config[:host], config[:database], charset, collation
        end
        puts "<= sq:create executed"
      end

      # Drop the database (postgres and mysql only)
      def drop
        config = @sequel_model.db.opts

        user, password, host, database = config[:user], config[:password], config[:host], config[:database]

        @sequel_model.db.disconnect

        puts "=> Dropping database '#{database}'"
        if config[:adapter] == 'sqlite3'
          File.delete(database) if File.exist?(database)
        else
          @sql_helpers.drop_db config[:adapter], user, password, host, database
        end
        puts "<= sq:drop executed"
      end

      # Performs the seed command to fill the database
      def seed
        missing_model_features = Padrino.send(:default_dependency_paths) - Padrino.send(:dependency_paths)

        Padrino.require_dependencies(missing_model_features)
        Rake::Task['db:seed'].invoke
      end
    end
  end
end
