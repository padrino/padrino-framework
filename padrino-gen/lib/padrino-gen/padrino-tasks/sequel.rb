if PadrinoTasks.load?(:sequel, defined?(Sequel))
  # Sequel's Migrator raises without migration files (a new project, or a clone, since git drops the
  # empty db/migrate); like ar:migrate, there's then nothing to do.
  no_migrations = lambda do
    next false if Dir.glob('db/migrate/*.[rR][bB]').any?

    puts '<= No migrations in db/migrate'
    true
  end

  namespace :sq do
    namespace :migrate do
      desc 'Perform automigration (reset your db data)'
      task auto: :skeleton do
        next if no_migrations.call

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
        next if no_migrations.call

        ::Sequel.extension :migration
        ::Sequel::Migrator.run Sequel::Model.db, 'db/migrate'
        puts '<= sq:migrate:up executed'
      end

      desc 'Perform migration down (erase all data)'
      task down: :skeleton do
        next if no_migrations.call

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
      Padrino::Generators::SqlHelpers.create_db(config, charset, collation)
      puts '<= sq:create executed'
    end

    desc 'Drop the database'
    task drop: :skeleton do
      config = ::Sequel::Model.db.opts

      ::Sequel::Model.db.disconnect

      puts "=> Dropping database '#{config[:database]}'"
      Padrino::Generators::SqlHelpers.drop_db(config)
      puts '<= sq:drop executed'
    end

    desc 'Dump the database data to a SQL file (FILE=path, default tmp/<env>_dump.sql)'
    task dump: :skeleton do
      config = ::Sequel::Model.db.opts
      file = ENV['FILE'] || Padrino.root('tmp', "#{Padrino.env}_dump.sql")

      puts "=> Dumping database '#{config[:database]}' to #{file}"
      Padrino::Generators::SqlHelpers.dump_db(config, file)
      puts '<= sq:dump executed'
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
  task 'db:dump' => 'sq:dump'
end
