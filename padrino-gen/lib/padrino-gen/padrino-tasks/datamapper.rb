if defined?(DataMapper)
  namespace :dm do
    namespace :auto do
      desc "Perform automigration (reset your db data)"
      task :migrate => :environment do
        ::DataMapper.auto_migrate!
        puts "<= dm:auto:migrate executed"
      end

      desc "Perform non destructive automigration"
      task :upgrade => :environment do
        ::DataMapper.auto_upgrade!
        puts "<= dm:auto:upgrade executed"
      end
    end

    namespace :migrate do
      task :load => :environment do
        require 'dm-migrations/migration_runner'
        FileList["db/migrate/*.rb"].each do |migration|
          load migration
        end
      end

      desc "Migrate up using migrations"
      task :up, [:version] => :load do |t, args|
        version = args[:version] || ENV['VERSION']
        migrate_up!(version)
        puts "<= dm:migrate:up #{version} executed"
      end

      desc "Migrate down using migrations"
      task :down, [:version] => :load do |t, args|
        version = args[:version] || ENV['VERSION']
        migrate_down!(version)
        puts "<= dm:migrate:down #{version} executed"
      end
    end

    desc "Migrate the database to the latest version"
    task :migrate => 'dm:migrate:up'

    desc "Create the database"
    task :create => :environment do
      config = DataMapper.repository.adapter.options.symbolize_keys
      user, password, host = config[:user], config[:password], config[:host]
      database       = config[:database]  || config[:path].sub(/\//, "")
      charset        = config[:charset]   || ENV['CHARSET']   || 'utf8'
      collation      = config[:collation] || ENV['COLLATION'] || 'utf8_unicode_ci'
      puts "=> Creating database '#{database}'"
      case config[:adapter]
        when 'postgres'
          system("createdb", "-E", charset, "-h", host, "-U", user, database)
          puts "<= dm:create executed"
        when 'mysql'
          query = [
            "mysql", "--user=#{user}", (password.blank? ? '' : "--password=#{password}"), (%w[127.0.0.1 localhost].include?(host) ? '-e' : "--host=#{host} -e"),
            "CREATE DATABASE #{database} DEFAULT CHARACTER SET #{charset} DEFAULT COLLATE #{collation}".inspect
          ]
          system(query.compact.join(" "))
          puts "<= dm:create executed"
        when 'sqlite3'
          DataMapper.setup(DataMapper.repository.name, config)
        else
          raise "Adapter #{config[:adapter]} not supported for creating databases yet."
      end
    end

    desc "Drop the database (postgres and mysql only)"
    task :drop => :environment do
      config = DataMapper.repository.adapter.options.symbolize_keys
      user, password, host = config[:user], config[:password], config[:host]
      database       = config[:database] || config[:path].sub(/\//, "")
      puts "=> Dropping database '#{database}'"
      case config[:adapter]
        when 'postgres'
          system("dropdb", "-h", host, "-U", user, database)
          puts "<= dm:drop executed"
        when 'mysql'
          query = [
            "mysql", "--user=#{user}", (password.blank? ? '' : "--password=#{password}"), (%w[127.0.0.1 localhost].include?(host) ? '-e' : "--host=#{host} -e"),
            "DROP DATABASE IF EXISTS #{database}".inspect
          ]
          system(query.compact.join(" "))
          puts "<= dm:drop executed"
        when 'sqlite3'
          File.delete(config[:path]) if File.exist?(config[:path])
        else
          raise "Adapter #{config[:adapter]} not supported for dropping databases yet."
      end
    end

    desc "Drop the database, migrate from scratch and initialize with the seed data"
    task :reset => [:drop, :setup]

    desc "Create the database migrate and initialize with the seed data"
    task :setup => [:create, :migrate, :seed]
  end
end
