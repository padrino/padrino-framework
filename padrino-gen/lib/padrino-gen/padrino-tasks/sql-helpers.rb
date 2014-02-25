module Padrino
  module Generators
    module SqlHelpers
      def self.create_db(adapter, user, password, host, database, charset, collation)
        case adapter
          when 'postgres'
            environment = {}
            environment['PGPASSWORD'] = password unless password.blank?

            arguments = []
            arguments << "--encoding=#{charset}" if charset
            arguments << "--host=#{host}" if host
            arguments << "--username=#{user}" if user
            arguments << database

            Process.spawn(environment, 'createdb', *arguments)
          when 'mysql'
            environment = {}
            environment['MYSQL_PWD'] = password unless password.blank?

            arguments = []
            arguments << "--user=#{user}" if user
            arguments << "--host=#{host}" unless %w[127.0.0.1 localhost].include?(host)

            arguments << '-e'
            arguments << "CREATE DATABASE #{database} DEFAULT CHARACTER SET #{charset} DEFAULT COLLATE #{collation}"

            Process.spawn(environment, 'mysql', *arguments)
          else
            raise "Adapter #{adapter} not supported for creating databases yet."
        end
      end

      def self.drop_db(adapter, user, password, host, database)
        case adapter
          when 'postgres'
            environment = {}
            environment['PGPASSWORD'] = password unless password.blank?

            arguments = []
            arguments << "--host=#{host}" if host
            arguments << "--username=#{user}" if user
            arguments << database

            Process.spawn(environment, 'dropdb', *arguments)
          when 'mysql'
            environment = {}
            environment['MYSQL_PWD'] = password unless password.blank?

            arguments = []
            arguments << "--user=#{user}" if user
            arguments << "--host=#{host}" unless %w[127.0.0.1 localhost].include?(host)

            arguments << '-e'
            arguments << "DROP DATABASE IF EXISTS #{database}"

            Process.spawn(environment, 'mysql', *arguments)
          else
            raise "Adapter #{adapter} not supported for dropping databases yet."
        end
      end
    end
  end
end
