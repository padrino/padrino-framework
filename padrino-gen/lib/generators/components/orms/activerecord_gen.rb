module Padrino
  module Generators
    module Components
      module Orms

        module ActiverecordGen

          AR = (<<-AR).gsub(/^ {10}/, '')
          module DatabaseSetup
            def self.registered(app)
              app.configure :development do
                ActiveRecord::Base.establish_connection(
                  :adapter => 'sqlite3',
                  :database => 'your_dev_db_here'
                )
              end

              app.configure :production do
                ActiveRecord::Base.establish_connection(
                  :adapter => 'sqlite3',
                  :database => 'your_production_db_here'
                )
              end

              app.configure :test do
                ActiveRecord::Base.establish_connection(
                  :adapter => 'sqlite3',
                  :database => 'your_test_db_here'
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
              load 'config/boot.rb'
              ActiveRecord::Base.logger = Logger.new(STDOUT)
              ActiveRecord::Migration.verbose = true
              ActiveRecord::Migrator.migrate("db/migrate")
            end
          end
          RAKE


          def setup_orm
            require_dependencies 'activerecord'
            create_file("config/database.rb", AR)
            create_file("Rakefile", RAKE)
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
              create_table :!TABLE! do |t|
                # t.column <name>, <type>
                # t.column :age, :integer
                !FIELDS!
              end
            end

            def self.down
              drop_table :!TABLE!
            end
          end
          MIGRATION

          def create_migration_file(filename, name, fields)
            model_name = name.to_s.pluralize
            field_tuples = fields.collect { |value| value.split(":") }
            column_declarations = field_tuples.collect { |field, kind| "t.column :#{field}, :#{kind}" }.join("\n      ")
            migration_contents = AR_MIGRATION.gsub(/!NAME!/, model_name.camelize).gsub(/!TABLE!/, model_name.underscore)
            migration_contents.gsub!(/!FILENAME!/, filename.camelize)
            migration_contents.gsub!(/!FIELDS!/, column_declarations)
            migration_filename = "#{Time.now.to_i}_#{filename}.rb"
            create_file(app_root_path('db/migrate/', migration_filename), migration_contents)
          end

        end
      end
    end
  end
end
