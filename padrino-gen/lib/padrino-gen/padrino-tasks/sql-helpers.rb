require 'fileutils'

module Padrino
  module Generators
    module SqlHelpers
      # Creates the database that +config+ (the app's Sequel connection options) names.
      def self.create_db(config, charset, collation)
        database = config[:database]
        case config[:adapter].to_s
        when 'postgres', 'postgresql'
          on_server(config, *postgres_maintenance_databases(database)) do |db|
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
          on_server(config, *postgres_maintenance_databases(database)) { |db| db.run "DROP DATABASE IF EXISTS #{db.quote_identifier(database)}" }
        when 'mysql', 'mysql2'
          on_server(config, nil) { |db| db.run "DROP DATABASE IF EXISTS #{db.quote_identifier(database)}" }
        when 'sqlite', 'sqlite3'
          File.delete(database) if File.file?(database)
        else
          raise "Adapter #{config[:adapter]} not supported for dropping databases yet."
        end
      end

      def self.dump_db(adapter, user, password, host, port, socket, database, file)
        adapter = adapter.to_s
        password = password.to_s
        partial = "#{file}.tmp"
        environment = {}
        options = {}

        case adapter
        when 'postgres', 'postgresql'
          binary = 'pg_dump'
          environment['PGPASSWORD'] = password unless password.empty?

          arguments = ["--file=#{partial}"]
          arguments << "--host=#{host}" if host
          arguments << "--port=#{port}" if port
          arguments << "--username=#{user}" if user
          arguments << database
        when 'mysql', 'mysql2'
          binary = 'mysqldump'
          environment['MYSQL_PWD'] = password unless password.empty?

          arguments = ["--result-file=#{partial}"]
          arguments << "--user=#{user}" if user
          arguments << "--host=#{host}" if host
          arguments << "--port=#{port}" if port
          arguments << "--socket=#{socket}" if socket
          arguments << database
        when 'sqlite', 'sqlite3'
          raise "Database #{database} does not exist" unless File.file?(database.to_s)
          binary = 'sqlite3'
          arguments = [database, '.dump']
          options[:out] = partial
        else
          raise "Adapter #{adapter} not supported for dumping databases yet."
        end

        FileUtils.mkdir_p(File.dirname(file))
        begin
          pid = Process.spawn(environment, binary, *arguments, options)
        rescue Errno::ENOENT
          FileUtils.rm_f(partial) # spawn creates the out: file before exec fails
          raise "#{binary} not found on PATH"
        end
        _, status = Process.wait2(pid)
        unless status.success?
          FileUtils.rm_f(partial)
          raise "Error dumping database #{database}"
        end
        File.rename(partial, file)
        file
      end

      # Like createdb and dropdb, Postgres connects to postgres and then template1, but never to the
      # database being created or dropped: Postgres can't drop the database a connection is using.
      def self.postgres_maintenance_databases(database)
        %w[postgres template1] - [database]
      end
      private_class_method :postgres_maintenance_databases

      # Options of the app connection that name or expect the app's own database.
      APP_DATABASE_OPTIONS = %i[uri orig_opts after_connect connect_sqls extensions preconnect servers].freeze
      private_constant :APP_DATABASE_OPTIONS

      # Connects to the app's server, but to the first of +databases+ that accepts the connection
      # rather than the app's own database, which may not exist.
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
