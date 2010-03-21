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
      task :up, :version, :needs => :load do |t, args|
        version = args[:version] || ENV['VERSION']
        migrate_up!(version)
        puts "<= dm:migrate:up #{version} executed"
      end

      desc "Migrate down using migrations"
      task :down, :version, :needs => :load do |t, args|
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
      puts "=> Creating database #{config[:database]}"
      case config[:adapter]
      when 'postgres'
        `createdb -U #{config[:username]} #{config[:database]}`
        puts "<= dm:create executed"
      when 'mysql'
        user, password, database = config[:username], config[:password], config[:database]
        `mysql -u #{user} #{password ? "-p #{password}" : ''} -e "create database #{database}"`
        puts "<= dm:create executed"
      when 'sqlite3'
        Rake::Task['dm:auto:migrate'].invoke
      else
        raise "Adapter #{config[:adapter]} not supported for creating databases yet."
      end
    end

    desc "Drop the database (postgres and mysql only)"
    task :drop => :environment do
      config = DataMapper.repository.adapter.options.symbolize_keys
      puts "=> Dropping database '#{config[:database]}'"
      case config[:adapter]
      when 'postgres'
        `dropdb -U #{config[:username]} #{config[:database]}`
        puts "<= dm:drop executed"
      when 'mysql'
        user, password, database = config[:username], config[:password], config[:database]
        `mysql -u #{user} #{password ? "-p #{password}" : ''} -e "drop database #{database}"`
        puts "<= dm:drop executed"
      else
        raise "Adapter #{config[:adapter]} not supported for dropping databases yet.\ntry dm:auto:migrate"
      end
    end

    desc "Drop the database, and migrate from scratch"
    task :reset => [:drop, :create, :migrate]

  end
end