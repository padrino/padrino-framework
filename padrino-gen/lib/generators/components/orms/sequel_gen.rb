module Padrino
  module Generators
    module Components
      module Orms

        module SequelGen

          SEQUEL = (<<-SEQUEL).gsub(/^ {10}/, '')
          module DatabaseSetup
            def self.registered(app)
              Sequel::Model.plugin(:schema)
              app.configure(:development) { Sequel.connect('your_dev_db_here') }
              app.configure(:production)  { Sequel.connect('your_production_db_here') }
              app.configure(:test)        { Sequel.connect('your_test_db_here') }
            end
          end
          SEQUEL

          def setup_orm
            require_dependencies 'sequel'
            create_file("config/database.rb", SEQUEL)
          end

          SQ_MODEL = (<<-MODEL).gsub(/^ {10}/, '')
          class !NAME! < Sequel::Model

          end
          MODEL

          def create_model_file(name, fields)
            model_path = app_root_path('app/models/', "#{name.to_s.underscore}.rb")
            return false if File.exist?(model_path)
            model_contents = SQ_MODEL.gsub(/!NAME!/, name.to_s.downcase.camelize)
            create_file(model_path, model_contents)
          end

          SQ_MIGRATION = (<<-MIGRATION).gsub(/^ {10}/, '')
          class !FILENAME! < Sequel::Migration
            def up
              create_table :!TABLE! do
                primary_key :id
                # <type> <name>
                text :username, :unique => true, :null => false
                !FIELDS!
              end
            end

            def down
              drop_table :!TABLE!
            end
          end
          MIGRATION

          def create_migration_file(filename, name, fields)
            model_name = name.to_s.pluralize
            field_tuples = fields.collect { |value| value.split(":") }
            column_declarations = field_tuples.collect { |field, kind| "#{kind} :#{field}" }.join("\n      ")
            migration_contents = SQ_MIGRATION.gsub(/!NAME!/, model_name.camelize).gsub(/!TABLE!/, model_name.underscore)
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
