module Padrino
  module Generators 
    module SqlHelpers
      def self.create_db(adapter, user, password, host, database, charset, collation)
        case adapter
          when 'postgres'
            arguments = []
            arguments << "--encoding=#{charset}" if charset
            arguments << "--host=#{host}" if host
            arguments << "--username=#{user}" if user
            arguments << database
            system("createdb", *arguments)
          when 'mysql'
            arguments = ["--user=#{user}"]
            arguments << "--password=#{password}" unless password.blank?
            
            unless %w[127.0.0.1 localhost].include?(host)
              arguments << "--host=#{host}"
            end

            arguments << '-e'
            arguments << "CREATE DATABASE #{database} DEFAULT CHARACTER SET #{charset} DEFAULT COLLATE #{collation}"

            system('mysql',*arguments)
          else
            raise "Adapter #{adapter} not supported for creating databases yet."
        end
      end

      def self.drop_db(adapter, user, password, host, database)
        case adapter
          when 'postgres'
            arguments = []
            arguments << "--host=#{host}" if host
            arguments << "--username=#{user}" if user
            arguments << database
            system("dropdb", *arguments)
          when 'mysql'
            arguments = ["--user=#{user}"]
            arguments << "--password=#{password}" unless password.blank?

            unless %w[127.0.0.1 localhost].include?(host)
              arguments << "--host=#{host}"
            end

            arguments << '-e'
            arguments << "DROP DATABASE IF EXISTS #{database}"

            system('mysql',*arguments)
          else
            raise "Adapter #{adapter} not supported for dropping databases yet."
        end
      end
    end
  end
end
