require 'fileutils'

module Padrino
  module Generators
    module SqlHelpers
      # Creates the database that +config+ (the app's Sequel connection options) names.
      def self.create_db(config, charset, collation)
        database = config[:database]
        case config[:adapter].to_s
        when 'postgres', 'postgresql'
          on_server(config, 'postgres', 'template1') do |db|
            db.run "CREATE DATABASE #{db.quote_identifier(database)} ENCODING #{db.literal(charset)}"
          end
        when 'mysql', 'mysql2'
          on_server(config, nil) do |db|
            db.run "CREATE DATABASE #{db.quote_identifier(database)} " \
                   "DEFAULT CHARACTER SET #{db.literal(charset)} DEFAULT COLLATE #{db.literal(collation)}"
          end
        when 'sqlite', 'sqlite3'
          # Connecting to a SQLite database creates its file, so it may exist already.
          FileUtils.mkdir_p(File.dirname(database))
          File.open(database, 'a') {}
        else
          raise "Adapter #{config[:adapter]} not supported for creating databases yet."
        end
      end

      # Drops the database that +config+ (the app's Sequel connection options) names.
      def self.drop_db(config)
        database = config[:database]
        case config[:adapter].to_s
        when 'postgres', 'postgresql'
          on_server(config, 'postgres', 'template1') { |db| db.run "DROP DATABASE IF EXISTS #{db.quote_identifier(database)}" }
        when 'mysql', 'mysql2'
          on_server(config, nil) { |db| db.run "DROP DATABASE IF EXISTS #{db.quote_identifier(database)}" }
        when 'sqlite', 'sqlite3'
          File.delete(database) if File.file?(database)
        else
          raise "Adapter #{config[:adapter]} not supported for dropping databases yet."
        end
      end

      # Options of the app connection that name or expect the app's own database.
      APP_DATABASE_OPTIONS = %i[uri orig_opts after_connect connect_sqls extensions preconnect servers].freeze
      private_constant :APP_DATABASE_OPTIONS

      # Connects to the app's server, but to the first of +databases+ that accepts the connection
      # rather than the app's own database, which may not exist. Like createdb, Postgres tries
      # postgres and then template1.
      def self.on_server(config, *databases, &block)
        options = config.reject { |key, _| APP_DATABASE_OPTIONS.include?(key) }
        begin
          Sequel.connect(options.merge(database: databases.first), &block)
        rescue Sequel::DatabaseConnectionError
          databases.shift
          raise if databases.empty?

          retry
        end
      end
      private_class_method :on_server
    end
  end
end
