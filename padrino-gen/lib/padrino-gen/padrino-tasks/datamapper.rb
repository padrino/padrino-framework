if PadrinoTasks.load?(:datamapper, defined?(DataMapper))
  namespace :dm do
    namespace :auto do
      desc "Perform automigration (reset your db data)"
      task :migrate => :environment do
        ::DataMapper.repository.auto_migrate!
        puts "<= dm:auto:migrate executed"
      end

      desc "Perform non destructive automigration"
      task :upgrade => :environment do
        ::DataMapper.repository.auto_upgrade!
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
    task :migrate do
      migrate_task = if Dir['db/migrate/*.rb'].empty?
                       'dm:auto:upgrade'
                     else
                       'dm:migrate:up'
                     end

      Rake::Task[migrate_task].invoke
    end

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
          arguments = []
          arguments << "--encoding=#{charset}" if charset
          arguments << "--host=#{host}" if host
          arguments << "--username=#{user}" if user
          arguments << database
          system("createdb", *arguments)
          puts "<= dm:create executed"
        when 'mysql'
          arguments = ["--user=#{user}"]
          arguments << "--password=#{password}" unless password.blank?
          
          unless %w[127.0.0.1 localhost].include?(host)
            arguments << "--host=#{host}"
          end

          arguments << '-e'
          arguments << "CREATE DATABASE #{database} DEFAULT CHARACTER SET #{charset} DEFAULT COLLATE #{collation}"

          system('mysql',*arguments)
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
          arguments = []
          arguments << "--host=#{host}" if host
          arguments << "--username=#{user}" if user
          arguments << database
          system("dropdb", *arguments)
          puts "<= dm:drop executed"
        when 'mysql'
          arguments = ["--user=#{user}"]
          arguments << "--password=#{password}" unless password.blank?

          unless %w[127.0.0.1 localhost].include?(host)
            arguments << "--host=#{host}"
          end

          arguments << '-e'
          arguments << "DROP DATABASE IF EXISTS #{database}"

          system('mysql',*arguments)
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

  task 'db:migrate' => 'dm:migrate'
  task 'db:create'  => 'dm:create'
  task 'db:drop'    => 'dm:drop'
  task 'db:reset'   => 'dm:reset'
  task 'db:setup'   => 'dm:setup'
end
