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
          class !FILECLASS! < ActiveRecord::Migration
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

          def create_model_migration(migration_name, name, columns)
            output_model_migration(migration_name, name, columns,
                 :base => AR_MIGRATION,
                 :column_format => lambda { |field, kind| "t.column :#{field}, :#{kind.underscore.gsub(/_/, '')}"  },
                 :up => AR_MODEL_UP_MG, :down => AR_MODEL_DOWN_MG)
          end

          AR_CHANGE_MG = (<<-MIGRATION).gsub(/^ {6}/, '')
          change_table :!TABLE! do |t|
            !COLUMNS!
          end
          MIGRATION

          def create_migration_file(migration_name, name, columns)
            output_migration_file(migration_name, name, columns,
                :base => AR_MIGRATION, :change_format => AR_CHANGE_MG,
                :add => lambda { |field, kind| "t.column :#{field}, :#{kind.underscore.gsub(/_/, '')}" },
                :remove => lambda { |field, kind| "t.remove :#{field}" })
          end

        end
      end
    end
  end
end
