require 'fileutils'
require 'tempfile'

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
        when 'mysql', 'mysql2', 'trilogy'
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
        when 'mysql', 'mysql2', 'trilogy'
          on_server(config, nil) { |db| db.run "DROP DATABASE IF EXISTS #{db.quote_identifier(database)}" }
        when 'sqlite', 'sqlite3'
          File.delete(database) if File.file?(database)
        else
          raise "Adapter #{config[:adapter]} not supported for dropping databases yet."
        end
      end

      # Dumps the data of the database that +config+ (Sequel connection options) names into +file+.
      def self.dump_db(config, file)
        adapter = config[:adapter].to_s
        user, host, port, socket, database = config.values_at(:user, :host, :port, :socket, :database)
        password = config[:password].to_s
        # One temp file per process, so overlapping dumps to the same file can't write into each other's.
        partial = "#{file}.#{Process.pid}.tmp"
        environment = {}
        options = {}
        read_errors = false
        errors = nil

        case adapter
        when 'postgres', 'postgresql'
          binary = 'pg_dump'
          environment['PGPASSWORD'] = password unless password.empty?
          # The app's TLS settings, as Rails passes them, so the dump is held to the same rules.
          POSTGRES_TLS_ENVIRONMENT.each { |key, name| environment[name] = config[key].to_s if config[key] }

          arguments = ["--file=#{partial}"]
          arguments << "--host=#{host}" if host
          arguments << "--port=#{port}" if port
          arguments << "--username=#{user}" if user
          arguments << database
        when 'mysql', 'mysql2', 'trilogy'
          binary = 'mysqldump'
          environment['MYSQL_PWD'] = password unless password.empty?

          arguments = ["--result-file=#{partial}"]
          arguments << "--user=#{user}" if user
          if adapter == 'trilogy'
            arguments.concat(trilogy_host_arguments(host, port, socket))
            arguments.concat(trilogy_tls_arguments(config))
          else
            arguments.concat(mysql_host_arguments(host, port))
            arguments << "--socket=#{socket}" if socket
            MYSQL_TLS_ARGUMENTS.each { |key, flag| arguments << "#{flag}=#{config[key]}" if config[key] }
          end
          arguments << database
        when 'sqlite', 'sqlite3'
          raise "Database #{database} does not exist" unless File.file?(database.to_s)
          binary = 'sqlite3'
          # Wait up to 5 seconds for a lock, as the app's queries would.
          arguments = ['-cmd', '.timeout 5000', database, '.dump']
          options[:out] = partial
          # The sqlite3 shell exits 0 when .dump fails, as on a locked database or a file that isn't
          # one, so its errors are read from stderr and from the end of the dump.
          read_errors = true
        else
          raise "Adapter #{adapter} not supported for dumping databases yet."
        end

        FileUtils.mkdir_p(File.dirname(file))
        pid = status = nil
        renamed = false
        begin
          # Data dumps can hold secrets, so only the owner may read them. The tools truncate this
          # file rather than create it, which keeps its mode.
          FileUtils.rm_f(partial)
          File.open(partial, File::WRONLY | File::CREAT | File::EXCL, 0o600) {}
          options[:err] = errors = Tempfile.create('padrino-dump-errors') if read_errors
          begin
            pid = Process.spawn(environment, binary, *arguments, options)
          rescue Errno::ENOENT
            raise "#{binary} not found on PATH"
          end
          _, status = Process.wait2(pid)
          problem = sqlite_dump_errors(errors.path, partial) if errors
          raise ["Error dumping database #{database}", problem].compact.join(': ') if problem || !status.success?

          File.rename(partial, file)
          renamed = true
          file
        ensure
          begin
            stop_child(pid) if pid && status.nil?
          ensure
            # spawn may create the out: file before exec fails; an interrupt leaves it too
            FileUtils.rm_f(partial) unless renamed
            if errors
              errors.close
              FileUtils.rm_f(errors.path)
            end
          end
        end
      end

      # What the sqlite3 shell wrote to stderr or, when that is empty, a note if the dump ends with the
      # rollback it writes instead of COMMIT after an error. nil for a complete dump.
      def self.sqlite_dump_errors(errors, dump)
        message = File.read(errors).strip
        return message unless message.empty?

        tail = File.open(dump) do |io|
          io.seek([io.size - 64, 0].max)
          io.read
        end
        'the dump ends with "ROLLBACK; -- due to errors"' if tail.end_with?("ROLLBACK; -- due to errors\n")
      end
      private_class_method :sqlite_dump_errors

      # Reach the server the app connects to. mysql2 uses the local socket when the host is missing
      # or localhost, and ignores the port there; the MariaDB client switches to TCP whenever it gets
      # --port, so pass neither. Any other host, 127.0.0.1 included, is TCP to that host and port.
      def self.mysql_host_arguments(host, port)
        return [] if host.nil? || host == 'localhost'

        arguments = ["--host=#{host}"]
        arguments << "--port=#{port}" if port
        arguments
      end
      private_class_method :mysql_host_arguments

      # Reach the server trilogy connects to. It takes any host over TCP, localhost included, which
      # mysqldump does only with --protocol, and ignores the socket then. Without a host it uses the
      # socket, /tmp/mysql.sock by default. ar:dump drops the host, as Active Record does, when both are set.
      def self.trilogy_host_arguments(host, port, socket)
        return ["--socket=#{socket || '/tmp/mysql.sock'}"] unless host

        arguments = ['--protocol=tcp', "--host=#{host}"]
        arguments << "--port=#{port}" if port
        arguments
      end
      private_class_method :trilogy_host_arguments

      # Trilogy's TLS settings as mysqldump options. Its ssl_mode is one of Trilogy's integers, or under
      # Active Record also a name, with or without the SSL_MODE_ prefix.
      def self.trilogy_tls_arguments(config)
        TRILOGY_TLS_ARGUMENTS.select { |key, _| config[key] }.map do |key, flag|
          value = key == :ssl_mode ? TRILOGY_SSL_MODES.fetch(config[key]) { config[key].to_s.sub(/\ASSL_MODE_/i, '') } : config[key]
          "#{flag}=#{value}"
        end
      end
      private_class_method :trilogy_tls_arguments

      # The connection options (Sequel's and ActiveRecord's names) that set TLS, and how the
      # Postgres and MySQL clients take them, as in Rails' database tasks.
      POSTGRES_TLS_ENVIRONMENT = {
        sslmode: 'PGSSLMODE', sslcert: 'PGSSLCERT', sslkey: 'PGSSLKEY', sslrootcert: 'PGSSLROOTCERT'
      }.freeze
      MYSQL_TLS_ARGUMENTS = {
        sslca: '--ssl-ca', sslcert: '--ssl-cert', sslcapath: '--ssl-capath', sslcipher: '--ssl-cipher',
        sslkey: '--ssl-key', ssl_mode: '--ssl-mode'
      }.freeze
      TRILOGY_TLS_ARGUMENTS = {
        ssl_ca: '--ssl-ca', ssl_cert: '--ssl-cert', ssl_capath: '--ssl-capath', ssl_cipher: '--ssl-cipher',
        ssl_crl: '--ssl-crl', ssl_crlpath: '--ssl-crlpath', ssl_key: '--ssl-key', ssl_mode: '--ssl-mode'
      }.freeze
      TRILOGY_SSL_MODES = { 0 => 'DISABLED', 1 => 'VERIFY_IDENTITY', 2 => 'VERIFY_CA', 3 => 'REQUIRED', 4 => 'PREFERRED' }.freeze
      private_constant :POSTGRES_TLS_ENVIRONMENT, :MYSQL_TLS_ARGUMENTS, :TRILOGY_TLS_ARGUMENTS, :TRILOGY_SSL_MODES

      # Stops and reaps a dump that was given up on, as when an interrupt or a signal reached only
      # this process, so it doesn't keep running, or write the temp file after it was removed.
      def self.stop_child(pid)
        Process.kill('TERM', pid)
        Process.wait(pid)
      rescue Errno::ESRCH, Errno::ECHILD
        nil
      end
      private_class_method :stop_child

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
