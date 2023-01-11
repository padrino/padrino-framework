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
      desc "Create all the local databases defined in config/database.yml"
      task :all => :skeleton do
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

    desc "Creates the database defined in config/database.yml for the current Padrino.env"
    task :create => :skeleton do
      with_database(Padrino.env) do |config|
        create_database(config)
      end
    end

    def create_database(config)
      begin
        if config[:adapter] =~ /sqlite/
          if File.exist?(config[:database])
            $stderr.puts "#{config[:database]} already exists."
          else
            begin
              # Create the SQLite database
              FileUtils.mkdir_p File.dirname(config[:database]) unless File.exist?(File.dirname(config[:database]))
              ActiveRecord::Base.establish_connection(config)
              ActiveRecord::Base.connection
            rescue StandardError => e
              catch_error(:create, e, config)
            end
          end
          return # Skip the else clause of begin/rescue
        else
          ActiveRecord::Base.establish_connection(config)
          ActiveRecord::Base.connection
        end
      rescue
        case config[:adapter]
        when 'mysql', 'mysql2', 'em_mysql2', 'jdbcmysql'
          @charset   = ENV['CHARSET']   || 'utf8'
          @collation = ENV['COLLATION'] || 'utf8_unicode_ci'
          creation_options = {:charset => (config[:charset] || @charset), :collation => (config[:collation] || @collation)}
          begin
            ActiveRecord::Base.establish_connection(config.merge(:database => nil))
            ActiveRecord::Base.connection.create_database(config[:database], creation_options)
            ActiveRecord::Base.establish_connection(config)
          rescue StandardError => e
            $stderr.puts *(e.backtrace)
            $stderr.puts e.inspect
            $stderr.puts "Couldn't create database for #{config.inspect}, charset: #{config[:charset] || @charset}, collation: #{config[:collation] || @collation}"
            $stderr.puts "(if you set the charset manually, make sure you have a matching collation)" if config[:charset]
          end
        when 'postgresql'
          @encoding = config[:encoding] || ENV['CHARSET'] || 'utf8'
          begin
            ActiveRecord::Base.establish_connection(config.merge(:database => 'postgres', :schema_search_path => 'public'))
            ActiveRecord::Base.connection.create_database(config[:database], config.merge(:encoding => @encoding))
            ActiveRecord::Base.establish_connection(config)
          rescue StandardError => e
            catch_error(:create, e, config)
          end
        end
      else
        $stderr.puts "#{config[:database]} already exists"
      end
    end

    namespace :drop do
      desc "Drops all the local databases defined in config/database.yml"
      task :all => :skeleton do
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

    desc "Drops the database for the current Padrino.env"
    task :drop => :skeleton do
      with_database(Padrino.env || :development) do |config|
        begin
          drop_database(config)
        rescue StandardError => e
          catch_error(:drop, e, config)
        end
      end
    end

    def local_database?(config, &block)
      if %w( 127.0.0.1 localhost ).include?(config[:host]) || !config[:host]
        yield
      else
        puts "This task only modifies local databases. #{config[:database]} is on a remote host."
      end
    end

    desc "Migrate the database through scripts in db/migrate and update db/schema.rb by invoking ar:schema:dump. Target specific version with MIGRATION_VERSION=x. Turn off output with VERBOSE=false."
    task :migrate => :skeleton do
      ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true

      if less_than_active_record_5_2?
        ActiveRecord::Migrator.migrate("db/migrate/", env_migration_version)
      elsif less_than_active_record_6_0?
        ActiveRecord::MigrationContext.new("db/migrate/").migrate(env_migration_version)
      else
        ActiveRecord::MigrationContext.new("db/migrate/", ActiveRecord::SchemaMigration).migrate(env_migration_version)
      end

      Rake::Task["ar:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
    end

    namespace :migrate do
      desc "Rollbacks the database one migration and re migrate up. If you want to rollback more than one step, define STEP=x. Target specific version with MIGRATION_VERSION=x."
      task :redo => :skeleton do
        if env_migration_version
          Rake::Task["ar:migrate:down"].invoke
          Rake::Task["ar:migrate:up"].invoke
        else
          Rake::Task["ar:rollback"].invoke
          Rake::Task["ar:migrate"].invoke
        end
      end

      desc "Resets your database using your migrations for the current environment."
      task :reset => ["ar:drop", "ar:create", "ar:migrate"]

      desc "Runs the 'up' for a given MIGRATION_VERSION."
      task(:up => :skeleton){ migrate_as(:up) }

      desc "Runs the 'down' for a given MIGRATION_VERSION."
      task(:down => :skeleton){ migrate_as(:down) }
    end

    desc "Rolls the schema back to the previous version. Specify the number of steps with STEP=n"
    task(:rollback => :skeleton){ move_as(:rollback) }

    desc "Pushes the schema to the next version. Specify the number of steps with STEP=n"
    task(:forward => :skeleton){ move_as(:forward) }

    desc "Drops and recreates the database from db/schema.rb for the current environment and loads the seeds."
    task :reset => [ 'ar:drop', 'ar:setup' ]

    desc "Retrieves the charset for the current environment's database"
    task :charset => :skeleton do
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
    task :collation => :skeleton do
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

    desc "Retrieves the current schema version number."
    task :version => :skeleton do
      puts "Current version: #{ActiveRecord::Migrator.current_version}"
    end

    desc "Raises an error if there are pending migrations."
    task :abort_if_pending_migrations => :skeleton do
      if defined? ActiveRecord
        pending_migrations =
          if less_than_active_record_5_2?
            ActiveRecord::Migrator.open(ActiveRecord::Migrator.migrations_paths).pending_migrations
          elsif less_than_active_record_6_0?
            ActiveRecord::MigrationContext.new(ActiveRecord::Migrator.migrations_paths).open.pending_migrations
          else
            ActiveRecord::MigrationContext.new(ActiveRecord::Migrator.migrations_paths, ActiveRecord::SchemaMigration).open.pending_migrations
          end

        if pending_migrations.any?
          puts "You have #{pending_migrations.size} pending migrations:"
          pending_migrations.each do |pending_migration|
            puts '  %4d %s' % [pending_migration.version, pending_migration.name]
          end
          abort %{Run "rake ar:migrate" to update your database then try again.}
        end
      end
    end

    desc "Create the database, load the schema, and initialize with the seed data."
    task :setup => [ 'ar:create', 'ar:schema:load', 'seed' ]

    namespace :schema do
      desc "Create a db/schema.rb file that can be portably used against any DB supported by AR."
      task :dump => :skeleton do
        require 'active_record/schema_dumper'
        File.open(ENV['SCHEMA'] || Padrino.root("db", "schema.rb"), "w") do |file|
          ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
        end
        Rake::Task["ar:schema:dump"].reenable
      end

      desc "Load a schema.rb file into the database."
      task :load => :skeleton do
        file = ENV['SCHEMA'] || Padrino.root("db", "schema.rb")
        if File.exist?(file)
          load(file)
        else
          raise %{#{file} doesn't exist yet. Run "rake ar:migrate" to create it then try again. If you do not intend to use a database, you should instead alter #{Padrino.root}/config/boot.rb to limit the frameworks that will be loaded}
        end
      end
    end

    namespace :structure do
      desc "Dump the database structure to a SQL file."
      task :dump => :skeleton do
        with_database(Padrino.env) do |config|
          case config[:adapter]
          when "mysql", "mysql2", 'em_mysql2', "oci", "oracle", 'jdbcmysql'
            config = config.inject({}){|result, (key, value)| result[key.to_s] = value; result }
            ActiveRecord::Tasks::DatabaseTasks.structure_dump(config, resolve_structure_sql)
          when "postgresql"
            ENV['PGHOST']     = config[:host] if config[:host]
            ENV['PGPORT']     = config[:port].to_s if config[:port]
            ENV['PGPASSWORD'] = config[:password].to_s if config[:password]
            search_path = config[:schema_search_path]
            if search_path
              search_path = search_path.split(",").map{|search_path| "--schema=#{search_path.strip}" }.join(" ")
            end
            `pg_dump -U "#{config[:username]}" -s -x -O -f db/#{Padrino.env}_structure.sql #{search_path} #{config[:database]}`
            raise "Error dumping database" if $?.exitstatus == 1
          when "sqlite", "sqlite3"
            dbfile = config[:database] || config[:dbfile]
            `#{config[:adapter]} #{dbfile} .schema > db/#{Padrino.env}_structure.sql`
          when "sqlserver"
            `scptxfr /s #{config[:host]} /d #{config[:database]} /I /f db\\#{Padrino.env}_structure.sql /q /A /r`
            `scptxfr /s #{config[:host]} /d #{config[:database]} /I /F db\ /q /A /r`
          when "firebird"
            set_firebird_env(config)
            db_string = firebird_db_string(config)
            sh "isql -a #{db_string} > #{Padrino.root}/db/#{Padrino.env}_structure.sql"
          else
            raise "Task not supported by '#{config[:adapter]}'."
          end
        end

        if !ActiveRecord::Base.connection.respond_to?(:supports_migrations?) || ActiveRecord::Base.connection.supports_migrations?
          File.open(resolve_structure_sql, "a"){|f| f << ActiveRecord::Base.connection.dump_schema_information }
        end
      end
    end

    desc "Generates .yml files for I18n translations."
    task :translate => :environment do
      models = Dir["#{Padrino.root}/{app,}/models/**/*.rb"].map { |m| File.basename(m, ".rb") }

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
            print "Lang #{lang.to_s.upcase} already exist ... "; $stdout.flush
          else
            locale     = "#{lang}:" + "\n" +
                         "  models:" + "\n" +
                         "    #{m}:" + "\n" +
                         "      name: #{klass.model_name.human}" + "\n" +
                         "      attributes:" + "\n" +
                         columns.map { |c| "        #{c}: #{klass.human_attribute_name(c)}" }.join("\n")
            print "created a new for #{lang.to_s.upcase} Lang ... "; $stdout.flush
          end
          File.open(filename, "w") { |f| f.puts locale }
        end
        puts
      end
    end

    task :seed => :environment do
      missing_model_features = Padrino.send(:default_dependency_paths) - Padrino.send(:dependency_paths)
      Padrino.require_dependencies(missing_model_features)
      Rake::Task['db:seed'].invoke
    end
  end

  def drop_database(config)
    case config[:adapter]
    when 'mysql', 'mysql2', 'em_mysql2', 'jdbcmysql'
      ActiveRecord::Base.establish_connection(config)
      ActiveRecord::Base.connection.drop_database config[:database]
    when /^sqlite/
      require 'pathname'
      path = Pathname.new(config[:database])
      file = path.absolute? ? path.to_s : Padrino.root(path)

      FileUtils.rm(file)
    when 'postgresql'
      ActiveRecord::Base.establish_connection(config.merge(:database => 'postgres', :schema_search_path => 'public'))
      ActiveRecord::Base.connection.drop_database config[:database]
    end
  end

  def set_firebird_env(config)
    ENV["ISC_USER"]     = config[:username].to_s if config[:username]
    ENV["ISC_PASSWORD"] = config[:password].to_s if config[:password]
  end

  def firebird_db_string(config)
    FireRuby::Database.db_string_for(config.symbolize_keys)
  end

  def catch_error(type, error, config)
    $stderr.puts *(error.backtrace)
    $stderr.puts error.inspect
    case type
    when :create
      $stderr.puts "Couldn't create database for #{config.inspect}"
    when :drop
      $stderr.puts "Couldn't drop #{config[:database]}"
    end
  end

  def migrate_as(type)
    version = env_migration_version
    fail "MIGRATION_VERSION is required" unless version

    if less_than_active_record_5_2?
      ActiveRecord::Migrator.run(type, "db/migrate/", version)
    elsif less_than_active_record_6_0?
      ActiveRecord::MigrationContext.new('db/migrate/').run(type, version)
    else
      ActiveRecord::MigrationContext.new('db/migrate/', ActiveRecord::SchemaMigration).run(type, version)
    end

    dump_schema
  end

  def move_as(type)
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1

    if less_than_active_record_5_2?
      ActiveRecord::Migrator.send(type, 'db/migrate/', step)
    elsif less_than_active_record_6_0?
      ActiveRecord::MigrationContext.new('db/migrate/').send(type, step)
    else
      ActiveRecord::MigrationContext.new('db/migrate/', ActiveRecord::SchemaMigration).send(type, step)
    end

    dump_schema
  end

  def dump_schema
    Rake::Task["ar:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
  end

  def resolve_structure_sql
    "#{Padrino.root}/db/#{Padrino.env}_structure.sql"
  end

  def less_than_active_record_5_2?
    ActiveRecord.version < Gem::Version.create("5.2.0")
  end

  def less_than_active_record_6_0?
    ActiveRecord.version < Gem::Version.create("6.0.0")
  end

  def less_than_active_record_6_1?
    ActiveRecord.version < Gem::Version.create("6.1.0")
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

  def with_all_databases
    if less_than_active_record_6_0?
      ActiveRecord::Base.configurations.each_value do |config|
        yield config
      end
    else
      ActiveRecord::Base.configurations.configs_for.each do |db_config|
        yield configuration_hash(db_config)
      end
    end
  end

  def configuration_hash(configuration)
    return configuration if less_than_active_record_6_0?
    config = less_than_active_record_6_1? ? configuration.config : configuration.configuration_hash
    config.with_indifferent_access
  end

  task 'db:migrate' => 'ar:migrate'
  task 'db:create'  => 'ar:create'
  task 'db:drop'    => 'ar:drop'
  task 'db:reset'   => 'ar:reset'
  task 'db:setup'   => 'ar:setup'
end
