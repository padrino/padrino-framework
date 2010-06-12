if defined?(ActiveRecord)
  # Fixes for Yardoc YRI Building
  class ActiveRecord; end unless defined?(ActiveRecord)
  class ActiveRecord::Schema; end unless defined?(ActiveRecord::Schema)

  namespace :ar do
    namespace :create do
      desc 'Create all the local databases defined in config/database.yml'
      task :all => :environment do
        ActiveRecord::Base.configurations.each_value do |config|
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

    desc 'Create the database defined in config/database.yml for the current Padrino.env'
    task :create => :environment do
      create_database(ActiveRecord::Base.configurations[Padrino.env])
    end

    def create_database(config)
      begin
        if config[:adapter] =~ /sqlite/
          if File.exist?(config[:database])
            $stderr.puts "#{config[:database]} already exists"
          else
            begin
              # Create the SQLite database
              Dir.mkdir File.dirname(config[:database]) unless File.exist?(File.dirname(config[:database]))
              ActiveRecord::Base.establish_connection(config)
              ActiveRecord::Base.connection
            rescue
              $stderr.puts $!, *($!.backtrace)
              $stderr.puts "Couldn't create database for #{config.inspect}"
            end
          end
          return # Skip the else clause of begin/rescue
        else
          ActiveRecord::Base.establish_connection(config)
          ActiveRecord::Base.connection
        end
      rescue
        case config[:adapter]
        when 'mysql'
          @charset   = ENV['CHARSET']   || 'utf8'
          @collation = ENV['COLLATION'] || 'utf8_unicode_ci'
          creation_options = {:charset => (config[:charset] || @charset), :collation => (config[:collation] || @collation)}
          begin
            ActiveRecord::Base.establish_connection(config.merge(:database => nil))
            ActiveRecord::Base.connection.create_database(config[:database], creation_options)
            ActiveRecord::Base.establish_connection(config)
          rescue Mysql::Error => sqlerr
            if sqlerr.errno == Mysql::Error::ER_ACCESS_DENIED_ERROR
              print "#{sqlerr.error}. \nPlease provide the root password for your mysql installation\n>"
              root_password = $stdin.gets.strip
              grant_statement = "GRANT ALL PRIVILEGES ON #{config[:database]}.* " \
                "TO '#{config[:username]}'@'localhost' " \
                "IDENTIFIED BY '#{config[:password]}' WITH GRANT OPTION;"
              ActiveRecord::Base.establish_connection(config.merge(
                  :database => nil, :username => 'root', :password => root_password))
              ActiveRecord::Base.connection.create_database(config[:database], creation_options)
              ActiveRecord::Base.connection.execute grant_statement
              ActiveRecord::Base.establish_connection(config)
            else
              $stderr.puts sqlerr.error
              $stderr.puts "Couldn't create database for #{config.inspect}, charset: #{config[:charset] || @charset}, collation: #{config[:collation] || @collation}"
              $stderr.puts "(if you set the charset manually, make sure you have a matching collation)" if config[:charset]
            end
          end
        when 'postgresql'
          @encoding = config[:encoding] || ENV['CHARSET'] || 'utf8'
          begin
            ActiveRecord::Base.establish_connection(config.merge(:database => 'postgres', :schema_search_path => 'public'))
            ActiveRecord::Base.connection.create_database(config[:database], config.merge(:encoding => @encoding))
            ActiveRecord::Base.establish_connection(config)
          rescue
            $stderr.puts $!, *($!.backtrace)
            $stderr.puts "Couldn't create database for #{config.inspect}"
          end
        end
      else
        $stderr.puts "#{config[:database]} already exists"
      end
    end

    namespace :drop do
      desc 'Drops all the local databases defined in config/database.yml'
      task :all => :environment do
        ActiveRecord::Base.configurations.each_value do |config|
          # Skip entries that don't have a database key
          next unless config[:database]
          begin
            # Only connect to local databases
            local_database?(config) { drop_database(config) }
          rescue Exception => e
            puts "Couldn't drop #{config[:database]} : #{e.inspect}"
          end
        end
      end
    end

    desc 'Drops the database for the current Padrino.env'
    task :drop => :environment do
      config = ActiveRecord::Base.configurations[Padrino.env || :development]
      begin
        drop_database(config)
      rescue Exception => e
        puts "Couldn't drop #{config[:database]} : #{e.inspect}"
      end
    end

    def local_database?(config, &block)
      if %w( 127.0.0.1 localhost ).include?(config[:host]) || config[:host].blank?
        yield
      else
        puts "This task only modifies local databases. #{config[:database]} is on a remote host."
      end
    end

    desc "Migrate the database through scripts in db/migrate and update db/schema.rb by invoking ar:schema:dump. Target specific version with VERSION=x. Turn off output with VERBOSE=false."
    task :migrate => :environment do
      ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
      ActiveRecord::Migrator.migrate("db/migrate/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
      Rake::Task["ar:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
    end

    namespace :migrate do
      desc  'Rollbacks the database one migration and re migrate up. If you want to rollback more than one step, define STEP=x. Target specific version with VERSION=x.'
      task :redo => :environment do
        if ENV["VERSION"]
          Rake::Task["ar:migrate:down"].invoke
          Rake::Task["ar:migrate:up"].invoke
        else
          Rake::Task["ar:rollback"].invoke
          Rake::Task["ar:migrate"].invoke
        end
      end

      desc 'Resets your database using your migrations for the current environment'
      task :reset => ["ar:drop", "ar:create", "ar:migrate"]

      desc 'Runs the "up" for a given migration VERSION.'
      task :up => :environment do
        version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
        raise "VERSION is required" unless version
        ActiveRecord::Migrator.run(:up, "db/migrate/", version)
        Rake::Task["ar:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
      end

      desc 'Runs the "down" for a given migration VERSION.'
      task :down => :environment do
        version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
        raise "VERSION is required" unless version
        ActiveRecord::Migrator.run(:down, "db/migrate/", version)
        Rake::Task["ar:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
      end
    end

    desc 'Rolls the schema back to the previous version. Specify the number of steps with STEP=n'
    task :rollback => :environment do
      step = ENV['STEP'] ? ENV['STEP'].to_i : 1
      ActiveRecord::Migrator.rollback('db/migrate/', step)
      Rake::Task["ar:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
    end

    desc 'Pushes the schema to the next version. Specify the number of steps with STEP=n'
    task :forward => :environment do
      step = ENV['STEP'] ? ENV['STEP'].to_i : 1
      ActiveRecord::Migrator.forward('db/migrate/', step)
      Rake::Task["ar:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
    end

    desc 'Drops and recreates the database from db/schema.rb for the current environment and loads the seeds.'
    task :reset => [ 'ar:drop', 'ar:setup' ]

    desc "Retrieves the charset for the current environment's database"
    task :charset => :environment do
      config = ActiveRecord::Base.configurations[Padrino.env || :development]
      case config[:adapter]
      when 'mysql'
        ActiveRecord::Base.establish_connection(config)
        puts ActiveRecord::Base.connection.charset
      when 'postgresql'
        ActiveRecord::Base.establish_connection(config)
        puts ActiveRecord::Base.connection.encoding
      else
        puts 'sorry, your database adapter is not supported yet, feel free to submit a patch'
      end
    end

    desc "Retrieves the collation for the current environment's database"
    task :collation => :environment do
      config = ActiveRecord::Base.configurations[Padrino.env || :development]
      case config[:adapter]
      when 'mysql'
        ActiveRecord::Base.establish_connection(config)
        puts ActiveRecord::Base.connection.collation
      else
        puts 'sorry, your database adapter is not supported yet, feel free to submit a patch'
      end
    end

    desc "Retrieves the current schema version number"
    task :version => :environment do
      puts "Current version: #{ActiveRecord::Migrator.current_version}"
    end

    desc "Raises an error if there are pending migrations"
    task :abort_if_pending_migrations => :environment do
      if defined? ActiveRecord
        pending_migrations = ActiveRecord::Migrator.new(:up, 'db/migrate').pending_migrations

        if pending_migrations.any?
          puts "You have #{pending_migrations.size} pending migrations:"
          pending_migrations.each do |pending_migration|
            puts '  %4d %s' % [pending_migration.version, pending_migration.name]
          end
          abort %{Run "rake ar:migrate" to update your database then try again.}
        end
      end
    end

    desc 'Create the database, load the schema, and initialize with the seed data'
    task :setup => [ 'ar:create', 'ar:schema:load', 'seed' ]

    namespace :schema do
      desc "Create a db/schema.rb file that can be portably used against any DB supported by AR"
      task :dump => :environment do
        require 'active_record/schema_dumper'
        File.open(ENV['SCHEMA'] || Padrino.root("db", "schema.rb"), "w") do |file|
          ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
        end
        Rake::Task["ar:schema:dump"].reenable
      end

      desc "Load a schema.rb file into the database"
      task :load => :environment do
        file = ENV['SCHEMA'] || Padrino.root("db", "schema.rb")
        if File.exists?(file)
          load(file)
        else
          raise %{#{file} doesn't exist yet. Run "rake ar:migrate" to create it then try again. If you do not intend to use a database, you should instead alter #{Padrino.root}/config/boot.rb to limit the frameworks that will be loaded}
        end
      end

      desc "Create migration from schema.rb"
      task :to_migration => :environment do
        AutoMigrations.schema_to_migration
      end

      desc "Create migration from schema.rb and reset migrations log"
      task :to_migration_with_reset => :environment do
        AutoMigrations.schema_to_migration(true)
      end
    end

    namespace :structure do
      desc "Dump the database structure to a SQL file"
      task :dump => :environment do
        abcs = ActiveRecord::Base.configurations
        case abcs[Padrino.env][:adapter]
        when "mysql", "oci", "oracle"
          ActiveRecord::Base.establish_connection(abcs[Padrino.env])
          File.open("#{Padrino.root}/db/#{Padrino.env}_structure.sql", "w+") { |f| f << ActiveRecord::Base.connection.structure_dump }
        when "postgresql"
          ENV['PGHOST']     = abcs[Padrino.env][:host] if abcs[Padrino.env][:host]
          ENV['PGPORT']     = abcs[Padrino.env][:port].to_s if abcs[Padrino.env][:port]
          ENV['PGPASSWORD'] = abcs[Padrino.env][:password].to_s if abcs[Padrino.env][:password]
          search_path = abcs[Padrino.env][:schema_search_path]
          unless search_path.blank?
            search_path = search_path.split(",").map{|search_path| "--schema=#{search_path.strip}" }.join(" ")
          end
          `pg_dump -i -U "#{abcs[Padrino.env][:username]}" -s -x -O -f db/#{Padrino.env}_structure.sql #{search_path} #{abcs[Padrino.env][:database]}`
          raise "Error dumping database" if $?.exitstatus == 1
        when "sqlite", "sqlite3"
          dbfile = abcs[Padrino.env][:database] || abcs[Padrino.env][:dbfile]
          `#{abcs[Padrino.env][:adapter]} #{dbfile} .schema > db/#{Padrino.env}_structure.sql`
        when "sqlserver"
          `scptxfr /s #{abcs[Padrino.env][:host]} /d #{abcs[Padrino.env][:database]} /I /f db\\#{Padrino.env}_structure.sql /q /A /r`
          `scptxfr /s #{abcs[Padrino.env][:host]} /d #{abcs[Padrino.env][:database]} /I /F db\ /q /A /r`
        when "firebird"
          set_firebird_env(abcs[Padrino.env])
          db_string = firebird_db_string(abcs[Padrino.env])
          sh "isql -a #{db_string} > #{Padrino.root}/db/#{Padrino.env}_structure.sql"
        else
          raise "Task not supported by '#{abcs[Padrino.env][:adapter]}'"
        end

        if ActiveRecord::Base.connection.supports_migrations?
          File.open("#{Padrino.root}/db/#{Padrino.env}_structure.sql", "a") { |f| f << ActiveRecord::Base.connection.dump_schema_information }
        end
      end
    end

    namespace :auto do
      desc "Use schema.rb to auto-upgrade"
      task :upgrade => :environment do
        AutoMigrations.run
      end
    end

    if defined?(I18n)
      desc "Generates .yml files for I18n translations"
      task :translate => :environment do
        models = Dir["#{Padrino.root}/app/models/**/*.rb"].collect { |m| File.basename(m, ".rb") }

        models.each do |m|
          # Get the model class
          klass = m.camelize.constantize

          # Init the processing
          print "Processing #{m.humanize}: "
          FileUtils.mkdir_p("#{Padrino.root}/app/locale/models/#{m}")
          langs = Array(I18n.locale) # for now we use only one

          # Create models for it and en locales
          langs.each do |lang|
            filename   = "#{Padrino.root}/app/locale/models/#{m}/#{lang}.yml"
            columns    = klass.columns.collect(&:name)
            # If the lang file already exist we need to check it
            if File.exist?(filename)
              locale = File.open(filename).read
              columns.each do |c|
                locale += "\n        #{c}: #{klass.human_attribute_name(c)}" unless locale.include?("#{c}:")
              end
              print "Lang #{lang.to_s.upcase} already exist ... "; $stdout.flush
              # Do some ere
            else
              locale     = "#{lang}:" + "\n" +
                           "  models:" + "\n" +
                           "    #{m}:" + "\n" +
                           "      name: #{klass.human_name}" + "\n" +
                           "      attributes:" + "\n" +
                           columns.collect { |c| "        #{c}: #{klass.human_attribute_name(c)}" }.join("\n")
              print "created a new for #{lang.to_s.upcase} Lang ... "; $stdout.flush
            end
            File.open(filename, "w") { |f| f.puts locale }
          end
          puts
        end
      end
    end
  end

  def drop_database(config)
    case config[:adapter]
    when 'mysql'
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

  ##
  # Padrino plugin for automating migrations
  #
  # Thanks to:: PJ Hyett
  # Original Repo:: http://github.com/pjhyett/auto_migrations
  #
  module AutoMigrations

    def self.run
      # Turn off schema_info code for auto-migration
      class << ActiveRecord::Schema
        alias :old_define :define
        attr_accessor :version
        def define(info={}, &block) @version = Time.now.utc.strftime("%Y%m%d%H%M%S"); instance_eval(&block) end
      end

      load(Padrino.root('db', 'schema.rb'))
      ActiveRecord::Migration.drop_unused_tables
      ActiveRecord::Migration.drop_unused_indexes
      ActiveRecord::Migration.update_schema_version(ActiveRecord::Schema.version) if ActiveRecord::Schema.version

      class << ActiveRecord::Schema
        alias :define :old_define
      end
    end

    def self.schema_to_migration(with_reset = false)
      schema_in = File.read(Padrino.root("db", "schema.rb"))
      schema_in.gsub!(/#(.)+\n/, '')
      schema_in.sub!(/ActiveRecord::Schema.define(.+)do[ ]?\n/, '')
      schema_in.gsub!(/^/, '  ')
      schema = "class InitialSchema < ActiveRecord::Migration\n  def self.up\n"
      schema += "    # We're resetting the migrations database...\n" +
                "    drop_table :schema_migrations\n" +
                "    initialize_schema_migrations_table\n\n" if with_reset
      schema += schema_in
      schema << "\n  def self.down\n"
      schema << (ActiveRecord::Base.connection.tables - %w(schema_info schema_migrations)).map do |table|
                  "    drop_table :#{table}\n"
                end.join
      schema << "  end\nend\n"
      migration_file = Padrino.root("db", "migrate", "001_initial_schema.rb")
      File.open(migration_file, "w") { |f| f << schema }
      puts "Migration created at db/migrate/001_initial_schema.rb"
    end

    def self.included(base)
      base.extend ClassMethods
      class << base
        cattr_accessor :tables_in_schema, :indexes_in_schema
        self.tables_in_schema, self.indexes_in_schema = [], []
        alias_method_chain :method_missing, :auto_migration
      end
    end

    module ClassMethods

      def method_missing_with_auto_migration(method, *args, &block)
        case method
        when :create_table
          auto_create_table(method, *args, &block)
        when :add_index
          auto_add_index(method, *args, &block)
        else
          method_missing_without_auto_migration(method, *args, &block)
        end
      end

      def auto_create_table(method, *args, &block)
        table_name = args.shift.to_s
        options    = args.pop || {}

        (self.tables_in_schema ||= []) << table_name

        # Table doesn't exist, create it
        unless ActiveRecord::Base.connection.tables.include?(table_name)
          return method_missing_without_auto_migration(method, *[table_name, options], &block)
        end

        # Grab database columns
        fields_in_db = ActiveRecord::Base.connection.columns(table_name).inject({}) do |hash, column|
          hash[column.name] = column
          hash
        end

        # Grab schema columns (lifted from active_record/connection_adapters/abstract/schema_statements.rb)
        table_definition = ActiveRecord::ConnectionAdapters::TableDefinition.new(ActiveRecord::Base.connection)
        primary_key = options[:primary_key] || "id"
        table_definition.primary_key(primary_key) unless options[:id] == false
        yield table_definition
        fields_in_schema = table_definition.columns.inject({}) do |hash, column|
          hash[column.name.to_s] = column
          hash
        end

        # Add fields to db new to schema
        (fields_in_schema.keys - fields_in_db.keys).each do |field|
          column  = fields_in_schema[field]
          options = {:limit => column.limit, :precision => column.precision, :scale => column.scale}
          options[:default] = column.default if !column.default.nil?
          options[:null]    = column.null    if !column.null.nil?
          add_column table_name, column.name, column.type.to_sym, options
        end

        # Remove fields from db no longer in schema
        (fields_in_db.keys - fields_in_schema.keys & fields_in_db.keys).each do |field|
          column = fields_in_db[field]
          remove_column table_name, column.name
        end

        (fields_in_schema.keys & fields_in_db.keys).each do |field|
          if field != primary_key #ActiveRecord::Base.get_primary_key(table_name)
            changed  = false  # flag
            new_type = fields_in_schema[field].type.to_sym
            new_attr = {}

            # First, check if the field type changed
            if fields_in_schema[field].type.to_sym != fields_in_db[field].type.to_sym
              changed = true
            end

            # Special catch for precision/scale, since *both* must be specified together
            # Always include them in the attr struct, but they'll only get applied if changed = true
            new_attr[:precision] = fields_in_schema[field][:precision]
            new_attr[:scale]     = fields_in_schema[field][:scale]

            # Next, iterate through our extended attributes, looking for any differences
            # This catches stuff like :null, :precision, etc
            fields_in_schema[field].each_pair do |att,value|
              next if att == :type or att == :base or att == :name # special cases
              if !value.nil? && value != fields_in_db[field].send(att)
                new_attr[att] = value
                changed = true
              end
            end

            # Change the column if applicable
            change_column table_name, field, new_type, new_attr if changed
          end
        end
      end

      def auto_add_index(method, *args, &block)
        table_name = args.shift.to_s
        fields     = Array(args.shift).map(&:to_s)
        options    = args.shift

        index_name = options[:name].to_s if options
        index_name ||= ActiveRecord::Base.connection.index_name(table_name, :column => fields)

        (self.indexes_in_schema ||= []) << index_name

        unless ActiveRecord::Base.connection.indexes(table_name).detect { |i| i.name == index_name }
          method_missing_without_auto_migration(method, *[table_name, fields, options], &block)
        end
      end

      def drop_unused_tables
        (ActiveRecord::Base.connection.tables - tables_in_schema - %w(schema_info schema_migrations)).each do |table|
          drop_table table
        end
      end

      def drop_unused_indexes
        tables_in_schema.each do |table_name|
          indexes_in_db = ActiveRecord::Base.connection.indexes(table_name).map(&:name)
          (indexes_in_db - indexes_in_schema & indexes_in_db).each do |index_name|
            remove_index table_name, :name => index_name
          end
        end
      end

      def update_schema_version(version)
        ActiveRecord::Base.connection.update("INSERT INTO schema_migrations VALUES ('#{version}')")

        schema_file = Padrino.root("db", "schema.rb")
        schema = File.read(schema_file)
        schema.sub!(/:version => \d+/, ":version => #{version}")
        File.open(schema_file, "w") { |f| f << schema }
      end

    end

  end

  ActiveRecord::Migration.send :include, AutoMigrations
end