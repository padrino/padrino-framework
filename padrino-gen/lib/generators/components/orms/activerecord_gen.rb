module Padrino
  module Generators
    module Components
      module Orms

        module ActiverecordGen

          AR = (<<-AR).gsub(/^ {10}/, '')
          module DatabaseSetup
            def self.registered(app)
              app.configure { ActiveRecord::Base.logger = logger }
              app.configure :development do
                ActiveRecord::Base.establish_connection(
                  :adapter => 'sqlite3',
                  :database => "your_dev_db_here"
                )
              end

              app.configure :production do
                ActiveRecord::Base.establish_connection(
                  :adapter => 'sqlite3',
                  :database => "your_production_db_here"
                )
              end

              app.configure :test do
                ActiveRecord::Base.establish_connection(
                  :adapter => 'sqlite3',
                  :database => "your_test_db_here"
                )
              end
            end
          end
          AR

          RAKE = (<<-RAKE).gsub(/^ {10}/, '')
          require 'sinatra/base'
          require 'active_record'

          namespace :db do
            desc "Migrate the database"
            task(:migrate) do
              load File.dirname(__FILE__) + '/config/boot.rb'
              APP_CLASS.new
              ActiveRecord::Base.logger = Logger.new(STDOUT)
              ActiveRecord::Migration.verbose = true
              ActiveRecord::Migrator.migrate( File.dirname(__FILE__) + "/db/migrate")
            end
          end
          RAKE


          def setup_orm
            require_dependencies 'activerecord'
            create_file("config/database.rb", AR)
            create_file("Rakefile", RAKE.gsub(/APP_CLASS/, @class_name))
            empty_directory('app/models')
          end

          AR_MODEL = (<<-MODEL).gsub(/^ {10}/, '')
          class !NAME! < ActiveRecord::Base

          end
          MODEL

          def create_model_file(name, fields)
            model_path = app_root_path('app/models/', "#{name.to_s.underscore}.rb")
            return false if File.exist?(model_path)
            model_contents = AR_MODEL.gsub(/!NAME!/, name.to_s.downcase.camelize)
            create_file(model_path, model_contents)
          end

          AR_MIGRATION = (<<-MIGRATION).gsub(/^ {10}/, '')
          class !FILENAME! < ActiveRecord::Migration
            def self.up
              !UP!
            end

            def self.down
              !DOWN!
            end
          end
          MIGRATION

          AR_MODEL_UP_MG = (<<-MIGRATION).gsub(/^ {6}/, '')
          create_table :!TABLE! do |t|
            # t.column <name>, <type>
            # t.column :age, :integer
            !FIELDS!
          end
          MIGRATION

          AR_MODEL_DOWN_MG = (<<-MIGRATION).gsub(/^ {10}/, '')
          drop_table :!TABLE!
          MIGRATION

          def create_model_migration(filename, name, fields)
            model_name = name.to_s.pluralize
            field_tuples = fields.collect { |value| value.split(":") }
            column_declarations = field_tuples.collect { |field, kind| "t.column :#{field}, :#{kind}" }.join("\n      ")
            migration_contents = AR_MIGRATION.gsub(/\s{4}!UP!\n/m, AR_MODEL_UP_MG).gsub(/!DOWN!\n/m, AR_MODEL_DOWN_MG)
            migration_contents.gsub!(/!NAME!/, model_name.camelize)
            migration_contents.gsub!(/!TABLE!/, model_name.underscore)
            migration_contents.gsub!(/!FILENAME!/, filename.camelize)
            migration_contents.gsub!(/!FIELDS!/, column_declarations)
            migration_filename = "#{Time.now.to_i}_#{filename}.rb"
            create_file(app_root_path('db/migrate/', migration_filename), migration_contents)
          end

          def create_migration_file(migration_name, name, columns)
            migration_scan = migration_name.camelize.scan(/(Add|Remove)(?:.*?)(?:To|From)(.*?)$/).flatten
            direction, table_name = migration_scan[0].downcase, migration_scan[1].downcase.pluralize if migration_scan.any?
            tuples = direction ? columns.collect { |value| value.split(":") } : []
            add_cols    = tuples.collect { |field, kind| "add_column :#{table_name}, :#{field}, :#{kind}" }.join("\n    ")
            remove_cols = tuples.collect { |field, kind| "remove_column :#{table_name}, :#{field}" }.join("\n    ")
            migration_contents = AR_MIGRATION.dup
            migration_contents.gsub!(/!FILENAME!/, migration_name.camelize)
            migration_contents.gsub!(/!UP!/m,   (direction == 'add' ? add_cols : remove_cols))
            migration_contents.gsub!(/!DOWN!/m, (direction == 'add' ? remove_cols : add_cols))
            migration_filename = "#{Time.now.to_i}_#{migration_name.underscore}.rb"
            create_file(app_root_path('db/migrate/', migration_filename), migration_contents)
          end

        end
      end
    end
  end
end
