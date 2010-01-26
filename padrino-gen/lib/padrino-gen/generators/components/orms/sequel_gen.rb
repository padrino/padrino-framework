module Padrino
  module Generators
    module Components
      module Orms

        module SequelGen

          SEQUEL = (<<-SEQUEL).gsub(/^ {10}/, '')
          module DatabaseSetup
            def self.registered(app)
              Sequel::Model.plugin(:schema)
              app.configure(:development) { Sequel.connect("sqlite3://" + Padrino.root('db', "development.db"), :loggers => [logger]) }
              app.configure(:production)  { Sequel.connect("sqlite3://" + Padrino.root('db', "production.db"), :loggers => [logger]) }
              app.configure(:test)        { Sequel.connect("sqlite3://" + Padrino.root('db', "test.db"), :loggers => [logger]) }
            end
          end
          SEQUEL

          def setup_orm
            require_dependencies 'sequel'
            create_file("config/database.rb", SEQUEL)
            empty_directory('app/models')
          end

          SQ_MODEL = (<<-MODEL).gsub(/^ {10}/, '')
          class !NAME! < Sequel::Model

          end
          MODEL

          def create_model_file(name, fields)
            model_path = destination_root('app/models/', "#{name.to_s.underscore}.rb")
            model_contents = SQ_MODEL.gsub(/!NAME!/, name.to_s.downcase.camelize)
            create_file(model_path, model_contents)
          end

          SQ_MIGRATION = (<<-MIGRATION).gsub(/^ {10}/, '')
          class !FILECLASS! < Sequel::Migration
            def up
              !UP!
            end

            def down
              !DOWN!
            end
          end
          MIGRATION


          SQ_MODEL_UP_MG = (<<-MIGRATION).gsub(/^ {6}/, '')
          create_table :!TABLE! do
            primary_key :id
            # <type> <name>
            !FIELDS!
          end
          MIGRATION

          SQ_MODEL_DOWN_MG = (<<-MIGRATION).gsub(/^ {10}/, '')
          drop_table :!TABLE!
          MIGRATION

          def create_model_migration(migration_name, name, columns)
            output_model_migration(migration_name, name, columns,
                   :column_format => lambda { |field, kind| "#{kind.camelize} :#{field}" },
                   :base => SQ_MIGRATION, :up => SQ_MODEL_UP_MG, :down => SQ_MODEL_DOWN_MG)
          end

          SQ_CHANGE_MG = (<<-MIGRATION).gsub(/^ {6}/, '')
          alter_table :!TABLE! do
            !COLUMNS!
          end
          MIGRATION

          def create_migration_file(migration_name, name, columns)
            output_migration_file(migration_name, name, columns,
                  :base => SQ_MIGRATION, :change_format => SQ_CHANGE_MG,
                  :add => lambda { |field, kind| "add_column :#{field}, #{kind.camelize}"  },
                  :remove => lambda { |field, kind| "drop_column :#{field}" }
                  )
          end
        end

      end
    end
  end
end
