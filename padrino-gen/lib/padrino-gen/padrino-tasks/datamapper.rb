if PadrinoTasks.load?(:datamapper, defined?(DataMapper))
  namespace :dm do
    namespace :auto do
      desc "Perform auto migration (reset your db data)"
      task :migrate => :environment do
        ::DataMapper.repository.auto_migrate!
        puts "<= dm:auto:migrate executed"
      end

      desc "Perform non destructive auto migration"
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
        version = args[:version] || env_migration_version
        migrate_up!(version)
        puts "<= dm:migrate:up #{version} executed"
      end

      desc "Migrate down using migrations"
      task :down, [:version] => :load do |t, args|
        version = args[:version] || env_migration_version
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
      config = Padrino::Utils.symbolize_keys(DataMapper.repository.adapter.options)
      adapter = config[:adapter]
      user, password, host = config[:user], config[:password], config[:host]

      database       = config[:database]  || config[:path]
      database.sub!(/^\//,'') unless adapter.start_with?('sqlite')

      charset        = config[:charset]   || ENV['CHARSET']   || 'utf8'
      collation      = config[:collation] || ENV['COLLATION'] || 'utf8_unicode_ci'

      puts "=> Creating database '#{database}'"
      Padrino::Generators::SqlHelpers.create_db(adapter, user, password, host, database, charset, collation)
      puts "<= dm:create executed"
    end

    desc "Drop the database (postgres and mysql only)"
    task :drop => :environment do
      config = Padrino::Utils.symbolize_keys(DataMapper.repository.adapter.options)
      adapter = config[:adapter]
      user, password, host = config[:user], config[:password], config[:host]

      database       = config[:database] || config[:path]
      database.sub!(/^\//,'') unless adapter.start_with?('sqlite')

      puts "=> Dropping database '#{database}'"
      Padrino::Generators::SqlHelpers.drop_db(adapter, user, password, host, database)
      puts "<= dm:drop executed"
    end

    desc "Drop the database, migrate from scratch and initialize with the seed data"
    task :reset => [:drop, :setup]

    desc "Create the database migrate and initialize with the seed data"
    task :setup => [:create, :migrate, :seed]
  end

  task 'db:migrate:down' => 'dm:migrate:down'
  task 'db:migrate:up' => 'dm:migrate:up'
  task 'db:migrate' => 'dm:migrate'
  task 'db:create'  => 'dm:create'
  task 'db:drop'    => 'dm:drop'
  task 'db:reset'   => 'dm:reset'
  task 'db:setup'   => 'dm:setup'
end
