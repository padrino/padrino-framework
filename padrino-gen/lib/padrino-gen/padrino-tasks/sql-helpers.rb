require 'fileutils'

module Padrino
  module Generators
    module SqlHelpers
      def self.create_db(adapter, user, password, host, database, charset, collation, port: nil)
        case adapter.to_s
        when 'postgres', 'postgresql'
          environment = {}
          environment['PGPASSWORD'] = password unless password.nil? || password.empty?

          arguments = []
          arguments << "--encoding=#{charset}" if charset
          arguments << "--host=#{host}" if host
          arguments << "--port=#{port}" if port
          arguments << "--username=#{user}" if user
          arguments << database

          run_client(environment, 'createdb', arguments, "creating database #{database}")
        when 'mysql', 'mysql2'
          environment = {}
          environment['MYSQL_PWD'] = password unless password.nil? || password.empty?

          arguments = []
          arguments << "--user=#{user}" if user
          arguments.concat(mysql_host_arguments(host, port))

          arguments << '-e'
          arguments << "CREATE DATABASE #{database} DEFAULT CHARACTER SET #{charset} DEFAULT COLLATE #{collation}"

          run_client(environment, 'mysql', arguments, "creating database #{database}")
        when 'sqlite', 'sqlite3'
          # Connecting to a SQLite database creates its file, so it may exist already.
          FileUtils.mkdir_p(File.dirname(database))
          File.open(database, 'a') {}
        else
          raise "Adapter #{adapter} not supported for creating databases yet."
        end
      end

      def self.drop_db(adapter, user, password, host, database, port: nil)
        case adapter.to_s
        when 'postgres', 'postgresql'
          environment = {}
          environment['PGPASSWORD'] = password unless password.nil? || password.empty?

          arguments = ['--if-exists']
          arguments << "--host=#{host}" if host
          arguments << "--port=#{port}" if port
          arguments << "--username=#{user}" if user
          arguments << database

          run_client(environment, 'dropdb', arguments, "dropping database #{database}")
        when 'mysql', 'mysql2'
          environment = {}
          environment['MYSQL_PWD'] = password unless password.nil? || password.empty?

          arguments = []
          arguments << "--user=#{user}" if user
          arguments.concat(mysql_host_arguments(host, port))

          arguments << '-e'
          arguments << "DROP DATABASE IF EXISTS #{database}"

          run_client(environment, 'mysql', arguments, "dropping database #{database}")
        when 'sqlite', 'sqlite3'
          File.delete(database) if File.file?(database)
        else
          raise "Adapter #{adapter} not supported for dropping databases yet."
        end
      end

      # Reach the server the app connects to (mysql2 passes the host and port as given): 127.0.0.1
      # with a port is a TCP server, so it gets --host, while localhost stays on the local socket.
      def self.mysql_host_arguments(host, port)
        arguments = []
        arguments << "--host=#{host}" if host && (port || !%w[127.0.0.1 localhost].include?(host))
        arguments << "--port=#{port}" if port
        arguments
      end
      private_class_method :mysql_host_arguments

      # Runs a database client without a shell and raises if it fails.
      def self.run_client(environment, command, arguments, action)
        _, status = Process.wait2(Process.spawn(environment, command, *arguments))
        return if status.success?

        reason = status.exitstatus ? "exited with status #{status.exitstatus}" : "was stopped (#{status.inspect})"
        raise "Failed #{action}: #{command} #{reason}"
      end
      private_class_method :run_client
    end
  end
end
