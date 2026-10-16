require 'English'
if PadrinoTasks.load?(:activerecord, defined?(ActiveRecord))
  # Fixes for Yardoc YRI Building
  begin
    require 'active_record'
    require 'active_record/schema'
  rescue LoadError
    module ActiveRecord; end unless defined?(ActiveRecord)
    class ActiveRecord::Schema; end unless defined?(ActiveRecord::Schema)
  end

  namespace :ar do
    namespace :create do
      desc 'Create all the local databases defined in config/database.yml'
      task all: :skeleton do
        with_all_databases do |config|
          # Skip entries that don't have a database key, such as the first entry here:
          #
          #  defaults: &defaults
          #    adapter: mysql
          #    username: root
          #    password:
          #    host: localhost
          #
          #  development:
          #    database: blog_development
          #    <<: *defaults
          next unless config[:database]
          # Only connect to local databases
          local_database?(config) { create_database(config) }
        end
      end
    end

    desc 'Creates the database defined in config/database.yml for the current Padrino.env'
    task create: :skeleton do
      with_database(Padrino.env) do |config|
        create_database(config)
      end
    end

    def create_database(config)
      if config[:adapter] =~ /sqlite/
        if File.exist?(config[:database])
          $stderr.puts "#{config[:database]} already exists."
        else
          begin
            # Create the SQLite database
            FileUtils.mkdir_p File.dirname(config[:database]) unless File.exist?(File.dirname(config[:database]))
            connect_to_database(config)
          rescue StandardError => e
            catch_error(:create, e, config)
          end
        end
        return
      end

      begin
        connect_to_database(config)
        $stderr.puts "#{config[:database]} already exists"
        return
      rescue StandardError => e
        connection_error = e
      end

      case config[:adapter]
      when 'mysql', 'mysql2', 'em_mysql2', 'jdbcmysql'
        @charset   = ENV['CHARSET']   || 'utf8'
        @collation = ENV['COLLATION'] || 'utf8_unicode_ci'
        creation_options = { charset: config[:charset] || @charset, collation: config[:collation] || @collation }
        begin
          ActiveRecord::Base.establish_connection(config.merge(database: nil))
          ActiveRecord::Base.connection.create_database(config[:database], creation_options)
          ActiveRecord::Base.establish_connection(config)
        rescue StandardError => e
          catch_error(:create, connection_error, config) if probe_error?(e)
          $stderr.puts "Couldn't create database #{config[:database]}, charset: #{config[:charset] || @charset}, collation: #{config[:collation] || @collation}"
          $stderr.puts '(if you set the charset manually, make sure you have a matching collation)' if config[:charset]
          raise
        end
      when 'postgresql'
        @encoding = config[:encoding] || ENV['CHARSET'] || 'utf8'
        begin
          ActiveRecord::Base.establish_connection(config.merge(database: 'postgres', schema_search_path: 'public'))
          ActiveRecord::Base.connection.create_database(config[:database], config.merge(encoding: @encoding))
          ActiveRecord::Base.establish_connection(config)
        rescue StandardError => e
          catch_error(:create, probe_error?(e) ? connection_error : e, config)
        end
      else
        catch_error(:create, connection_error, config)
      end
    end

    # Active Record 7.1+ connects lazily, so only a verified connection shows that the database exists.
    def connect_to_database(config)
      ActiveRecord::Base.establish_connection(config)
      ActiveRecord::Base.connection.verify!
    end

    # A create that finds the database already there means the connection failed for another reason
    # (no access to that database, bad settings), which is the error to report.
    def probe_error?(error)
      defined?(ActiveRecord::DatabaseAlreadyExists) && error.is_a?(ActiveRecord::DatabaseAlreadyExists)
    end

    namespace :drop do
      desc 'Drops all the local databases defined in config/database.yml'
      task all: :skeleton do
        with_all_databases do |config|
          # Skip entries that don't have a database key
          next unless config[:database]
          begin
            # Only connect to local databases
            local_database?(config) { drop_database(config) }
          rescue StandardError => e
            catch_error(:drop, e, config)
          end
        end
      end
    end

    desc 'Drops the database for the current Padrino.env'
    task drop: :skeleton do
      with_database(Padrino.env || :development) do |config|
        drop_database(config)
      rescue StandardError => e
        catch_error(:drop, e, config)
      end
    end

    def local_database?(config, &block)
      if %w[127.0.0.1 localhost].include?(config[:host]) || !config[:host]
        yield
      else
        puts "This task only modifies local databases. #{config[:database]} is on a remote host."
      end
    end

    desc 'Migrate the database through scripts in db/migrate and update db/schema.rb by invoking ar:schema:dump. Target specific version with MIGRATION_VERSION=x. Turn off output with VERBOSE=false.'
    task migrate: :skeleton do
      ActiveRecord::Migration.verbose = ENV['VERBOSE'] ? ENV['VERBOSE'] == 'true' : true

      if less_than_active_record_5_2?
        ActiveRecord::Migrator.migrate('db/migrate/', env_migration_version)
      else
        migration_context.migrate(env_migration_version)
      end

      dump_schema
    end

    namespace :migrate do
      desc 'Rollbacks the database one migration and re migrate up. If you want to rollback more than one step, define STEP=x. Target specific version with MIGRATION_VERSION=x.'
      task redo: :skeleton do
        if env_migration_version
          Rake::Task['ar:migrate:down'].invoke
          Rake::Task['ar:migrate:up'].invoke
        else
          Rake::Task['ar:rollback'].invoke
          Rake::Task['ar:migrate'].invoke
        end
      end

      desc 'Resets your database using your migrations for the current environment.'
      task reset: ['ar:drop', 'ar:create', 'ar:migrate']

      desc "Runs the 'up' for a given MIGRATION_VERSION."
      task(up: :skeleton) { migrate_as(:up) }

      desc "Runs the 'down' for a given MIGRATION_VERSION."
      task(down: :skeleton) { migrate_as(:down) }
    end

    desc 'Rolls the schema back to the previous version. Specify the number of steps with STEP=n'
    task(rollback: :skeleton) { move_as(:rollback) }

    desc 'Pushes the schema to the next version. Specify the number of steps with STEP=n'
    task(forward: :skeleton) { move_as(:forward) }

    desc 'Drops and recreates the database from db/schema.rb for the current environment and loads the seeds.'
    task reset: ['ar:drop', 'ar:setup']

    desc "Retrieves the charset for the current environment's database"
    task charset: :skeleton do
      with_database(Padrino.env || :development) do |config|
        case config[:adapter]
        when 'mysql', 'mysql2', 'em_mysql2', 'jdbcmysql'
          ActiveRecord::Base.establish_connection(config)
          puts ActiveRecord::Base.connection.charset
        when 'postgresql'
          ActiveRecord::Base.establish_connection(config)
          puts ActiveRecord::Base.connection.encoding
        else
          puts 'Sorry, your database adapter is not supported yet, feel free to submit a patch.'
        end
      end
    end

    desc "Retrieves the collation for the current environment's database."
    task collation: :skeleton do
      with_database(Padrino.env || :development) do |config|
        case config[:adapter]
        when 'mysql', 'mysql2', 'em_mysql2', 'jdbcmysql'
          ActiveRecord::Base.establish_connection(config)
          puts ActiveRecord::Base.connection.collation
        else
          puts 'sorry, your database adapter is not supported yet, feel free to submit a patch'
        end
      end
    end

    desc 'Retrieves the current schema version number.'
    task version: :skeleton do
      puts "Current version: #{ActiveRecord::Migrator.current_version}"
    end

    desc 'Raises an error if there are pending migrations.'
    task abort_if_pending_migrations: :skeleton do
      if defined? ActiveRecord
        pending_migrations =
          if less_than_active_record_5_2?
            ActiveRecord::Migrator.open(ActiveRecord::Migrator.migrations_paths).pending_migrations
          else
            migration_context.open.pending_migrations
          end

        if pending_migrations.any?
          puts "You have #{pending_migrations.size} pending migrations:"
          pending_migrations.each do |pending_migration|
            puts format('  %4d %s', pending_migration.version, pending_migration.name)
          end
          abort %(Run "rake ar:migrate" to update your database then try again.)
        end
      end
    end

    desc 'Create the database, load the schema, and initialize with the seed data.'
    task setup: ['ar:create', 'ar:schema:load', 'seed']

    namespace :schema do
      desc 'Create a db/schema.rb file that can be portably used against any DB supported by AR.'
      task dump: :skeleton do
        require 'active_record/schema_dumper'
        File.open(ENV['SCHEMA'] || Padrino.root('db', 'schema.rb'), 'w') do |file|
          ActiveRecord::SchemaDumper.dump(schema_dumper_source, file)
        end
        Rake::Task['ar:schema:dump'].reenable
      end

      desc 'Load a schema.rb file into the database.'
      task load: :skeleton do
        file = ENV['SCHEMA'] || Padrino.root('db', 'schema.rb')
        File.exist?(file) ? load(file) : raise(<<~MESSAGE.gsub("\n", ' '))
          #{file} doesn't exist yet. Run "rake ar:migrate" to create it then try again.
          If you do not intend to use a database, you should instead alter #{Padrino.root}/config/boot.rb to limit the frameworks that will be loaded
        MESSAGE
      end
    end

    namespace :structure do
      desc 'Dump the database structure to a SQL file.'
      task dump: :skeleton do
        with_database(Padrino.env) do |config|
          case config[:adapter]
          when 'mysql', 'mysql2', 'em_mysql2', 'oci', 'oracle', 'jdbcmysql'
            ActiveRecord::Tasks::DatabaseTasks.structure_dump(config.transform_keys(&:to_s), resolve_structure_sql)
          when 'postgresql'
            ENV['PGHOST']     = config[:host] if config[:host]
            ENV['PGPORT']     = config[:port].to_s if config[:port]
            ENV['PGPASSWORD'] = config[:password].to_s if config[:password]

            search_path = config[:schema_search_path]
            search_path = search_path.split(',').map { |path| "--schema=#{path.strip}" }.join(' ') if search_path

            `pg_dump -U "#{config[:username]}" -s -x -O -f db/#{Padrino.env}_structure.sql #{search_path} #{config[:database]}`
            raise 'Error dumping database' if $CHILD_STATUS.exitstatus == 1
          when 'sqlite', 'sqlite3'
            dbfile = config[:database] || config[:dbfile]
            `#{config[:adapter]} #{dbfile} .schema > db/#{Padrino.env}_structure.sql`
          when 'sqlserver'
            `scptxfr /s #{config[:host]} /d #{config[:database]} /I /f db\\#{Padrino.env}_structure.sql /q /A /r`
            `scptxfr /s #{config[:host]} /d #{config[:database]} /I /F db\ /q /A /r`
          when 'firebird'
            set_firebird_env(config)
            db_string = firebird_db_string(config)
            sh "isql -a #{db_string} > #{Padrino.root}/db/#{Padrino.env}_structure.sql"
          else
            raise "Task not supported by '#{config[:adapter]}'."
          end
        end

        connection = ActiveRecord::Base.connection
        if !connection.respond_to?(:supports_migrations?) || connection.supports_migrations?
          versions_sql = connection.respond_to?(:dump_schema_versions) ? connection.dump_schema_versions : connection.dump_schema_information
          File.open(resolve_structure_sql, 'a') { |f| f << versions_sql }
        end
      end
    end

    desc 'Dump the database data to a SQL file (FILE=path, default tmp/<env>_dump.sql)'
    task dump: :skeleton do
      targets = dump_targets(Padrino.env)
      raise 'FILE= is ambiguous: more than one database is configured for this environment' if ENV['FILE'] && targets.size > 1

      targets.each do |config, name|
        suffix = targets.size > 1 ? "_#{name}" : ''
        file = ENV['FILE'] || Padrino.root('tmp', "#{Padrino.env}#{suffix}_dump.sql")
        # The config under Sequel's names for the user and database; the rest, TLS included, match.
        options = config.symbolize_keys.merge(user: config[:username], database: config[:database] || config[:dbfile])

        puts "=> Dumping database '#{options[:database]}' to #{file}"
        Padrino::Generators::SqlHelpers.dump_db(options, file)
      end
      puts '<= ar:dump executed'
    end

    desc 'Generates .yml files for I18n translations.'
    task translate: :environment do
      models = Dir["#{Padrino.root}/{app,}/models/**/*.rb"].map { |m| File.basename(m, '.rb') }

      models.each do |m|
        # get the model class
        klass = m.camelize.constantize

        # avoid non ActiveRecord models
        next unless klass.ancestors.include?(ActiveRecord::Base)

        # init the processing
        print "Processing #{m.humanize}: "
        FileUtils.mkdir_p("#{Padrino.root}/app/locale/models/#{m}")
        langs = Array(I18n.locale)

        # create models for it and en locales
        langs.each do |lang|
          filename   = "#{Padrino.root}/app/locale/models/#{m}/#{lang}.yml"
          columns    = klass.columns.map(&:name)
          # If the lang file already exist we need to check it.
          if File.exist?(filename)
            locale = File.open(filename).read
            columns.each do |c|
              locale += "\n        #{c}: #{klass.human_attribute_name(c)}" unless locale.include?("#{c}:")
            end
          else
            locale = <<~YAML
              #{lang}:
                models:
                  #{m}:
                    name: #{klass.model_name.human}
                    attributes:
            YAML

            columns.each { |c| locale += "        #{c}: #{klass.human_attribute_name(c)}\n" }
            locale.chomp!
          end

          $stdout.flush
          File.open(filename, 'w') { |f| f.puts locale }
        end
        puts
      end
    end

    task seed: :environment do
      Rake::Task['db:seed'].invoke
    end
  end

  def drop_database(config)
    case config[:adapter]
    when 'mysql', 'mysql2', 'em_mysql2', 'jdbcmysql'
      # Connect without the database, which may not exist; DROP DATABASE IF EXISTS doesn't need it.
      ActiveRecord::Base.establish_connection(config.merge(database: nil))
      ActiveRecord::Base.connection.drop_database config[:database]
    when /^sqlite/
      require 'pathname'
      path = Pathname.new(config[:database])
      file = path.absolute? ? path.to_s : Padrino.root(path)

      FileUtils.rm(file) if File.exist?(file)
    when 'postgresql'
      ActiveRecord::Base.establish_connection(config.merge(database: 'postgres', schema_search_path: 'public'))
      ActiveRecord::Base.connection.drop_database config[:database]
    end
  end

  def set_firebird_env(config)
    ENV['ISC_USER']     = config[:username].to_s if config[:username]
    ENV['ISC_PASSWORD'] = config[:password].to_s if config[:password]
  end

  def firebird_db_string(config)
    FireRuby::Database.db_string_for(config.symbolize_keys)
  end

  # Says which database failed and re-raises, so the task exits non-zero with the error.
  def catch_error(type, error, config)
    case type
    when :create
      $stderr.puts "Couldn't create database #{config[:database]}"
    when :drop
      $stderr.puts "Couldn't drop #{config[:database]}"
    end
    raise error
  end

  def migrate_as(type)
    version = env_migration_version
    raise 'MIGRATION_VERSION is required' unless version

    if less_than_active_record_5_2?
      ActiveRecord::Migrator.run(type, 'db/migrate/', version)
    else
      migration_context.run(type, version)
    end

    dump_schema
  end

  def move_as(type)
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1

    if less_than_active_record_5_2?
      ActiveRecord::Migrator.send(type, 'db/migrate/', step)
    else
      migration_context.send(type, step)
    end

    dump_schema
  end

  def dump_schema
    Rake::Task['ar:schema:dump'].invoke if schema_format_ruby?
  end

  def schema_format_ruby?
    format_source = ActiveRecord.respond_to?(:schema_format) ? ActiveRecord : ActiveRecord::Base
    format_source.schema_format == :ruby
  end

  # Active Record 7.2+ dumps the schema from a connection pool; older versions take a connection.
  def schema_dumper_source
    ActiveRecord::Base.respond_to?(:lease_connection) ? ActiveRecord::Base.connection_pool : ActiveRecord::Base.connection
  end

  def resolve_structure_sql
    "#{Padrino.root}/db/#{Padrino.env}_structure.sql"
  end

  def less_than_active_record_5_2?
    ActiveRecord.version < Gem::Version.create('5.2.0')
  end

  def less_than_active_record_6_0?
    ActiveRecord.version < Gem::Version.create('6.0.0')
  end

  def less_than_active_record_6_1?
    ActiveRecord.version < Gem::Version.create('6.1.0')
  end

  def migration_context
    if less_than_active_record_6_0?
      ActiveRecord::MigrationContext.new(ActiveRecord::Migrator.migrations_paths)
    else
      connection = ActiveRecord::Base.connection
      connection = connection.pool unless connection.respond_to?(:migration_context)
      connection.migration_context
    end
  end

  def with_database(env_name)
    if less_than_active_record_6_0?
      config = ActiveRecord::Base.configurations.with_indifferent_access[env_name]

      yield config
    else
      db_configs = ActiveRecord::Base.configurations.configs_for(env_name: env_name.to_s)

      db_configs.each do |db_config|
        yield configuration_hash(db_config)
      end
    end
  end

  def dump_targets(env_name)
    return [[ActiveRecord::Base.configurations.with_indifferent_access[env_name], nil]] if less_than_active_record_6_0?

    ActiveRecord::Base.configurations.configs_for(env_name: env_name.to_s).map do |db_config|
      name = db_config.respond_to?(:name) ? db_config.name : db_config.spec_name
      [configuration_hash(db_config), name]
    end
  end

  def with_all_databases(&block)
    if less_than_active_record_6_0?
      ActiveRecord::Base.configurations.each_value(&block)
    else
      ActiveRecord::Base.configurations.configs_for.each do |db_config|
        block.call(configuration_hash(db_config))
      end
    end
  end

  def configuration_hash(configuration)
    return configuration if less_than_active_record_6_0?
    config = less_than_active_record_6_1? ? configuration.config : configuration.configuration_hash
    config.with_indifferent_access
  end

  task 'db:migrate' => 'ar:migrate'
  task 'db:create' => 'ar:create'
  task 'db:drop' => 'ar:drop'
  task 'db:reset' => 'ar:reset'
  task 'db:setup' => 'ar:setup'
  task 'db:dump' => 'ar:dump'
end
