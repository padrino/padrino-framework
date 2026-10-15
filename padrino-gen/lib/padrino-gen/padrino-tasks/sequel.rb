if PadrinoTasks.load?(:sequel, defined?(Sequel))
  namespace :sq do
    namespace :migrate do
      desc 'Perform automigration (reset your db data)'
      task auto: :skeleton do
        ::Sequel.extension :migration
        ::Sequel::Migrator.run Sequel::Model.db, 'db/migrate', target: 0
        ::Sequel::Migrator.run Sequel::Model.db, 'db/migrate'
        puts '<= sq:migrate:auto executed'
      end

      desc 'Perform migration up/down to MIGRATION_VERSION'
      task :to, [:version] => :skeleton do |_t, args|
        version = (args[:version] || env_migration_version).to_s.strip
        ::Sequel.extension :migration
        raise 'No MIGRATION_VERSION was provided' if version.empty?
        ::Sequel::Migrator.apply(Sequel::Model.db, 'db/migrate', version.to_i)
        puts "<= sq:migrate:to[#{version}] executed"
      end

      desc 'Perform migration up to latest migration available'
      task up: :skeleton do
        ::Sequel.extension :migration
        ::Sequel::Migrator.run Sequel::Model.db, 'db/migrate'
        puts '<= sq:migrate:up executed'
      end

      desc 'Perform migration down (erase all data)'
      task down: :skeleton do
        ::Sequel.extension :migration
        ::Sequel::Migrator.run Sequel::Model.db, 'db/migrate', target: 0
        puts '<= sq:migrate:down executed'
      end
    end

    desc 'Perform migration up to latest migration available'
    task migrate: 'sq:migrate:up'

    desc 'Create the database'
    task create: :skeleton do
      config = Sequel::Model.db.opts
      user, password, host = config[:user], config[:password], config[:host]
      database = config[:database]
      charset = config[:charset] || ENV['CHARSET'] || 'utf8'
      collation = config[:collation] || ENV['COLLATION'] || 'utf8_unicode_ci'

      puts "=> Creating database '#{database}'"
      begin
        # The boot connects, so a database it can reach exists already; like Rails, that isn't an error.
        Sequel::Model.db.test_connection
        puts "<= Database '#{database}' already exists"
        next
      rescue Sequel::DatabaseConnectionError
        nil
      end
      require 'padrino-gen/padrino-tasks/sql-helpers'
      Padrino::Generators::SqlHelpers.create_db(config[:adapter], user, password, host, database, charset, collation, port: config[:port])
      puts '<= sq:create executed'
    end

    desc 'Drop the database'
    task drop: :skeleton do
      config = ::Sequel::Model.db.opts
      user, password, host, database = config[:user], config[:password], config[:host], config[:database]

      ::Sequel::Model.db.disconnect

      puts "=> Dropping database '#{database}'"
      Padrino::Generators::SqlHelpers.drop_db(config[:adapter], user, password, host, database, port: config[:port])
      puts '<= sq:drop executed'
    end

    desc 'Drop the database, migrate from scratch and initialize with the seed data'
    task reset: %w[drop create migrate seed]

    task seed: :environment do
      Rake::Task['db:seed'].invoke
    end
  end

  task 'db:create' => 'sq:create'
  task 'db:migrate' => 'sq:migrate'
  task 'db:reset' => 'sq:reset'
end
