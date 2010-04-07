module Padrino
  module Generators
    module Components
      module Orms

        module SequelGen

          SEQUEL = (<<-SEQUEL).gsub(/^ {10}/, '')
          Sequel::Model.plugin(:schema)
          DB = case Padrino.env
            when :development then Sequel.connect("sqlite://" + Padrino.root('db', "development.db"), :loggers => [logger])
            when :production  then Sequel.connect("sqlite://" + Padrino.root('db', "production.db"),  :loggers => [logger])
            when :test        then Sequel.connect("sqlite://" + Padrino.root('db', "test.db"),        :loggers => [logger])
          end
          SEQUEL

          def setup_orm
            require_dependencies 'sequel', 'sqlite3-ruby'
            create_file("config/database.rb", SEQUEL)
            empty_directory('app/models')
            empty_directory('db/migrate')
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
                   :column_format => Proc.new { |field, kind| "#{kind.camelize} :#{field}" },
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
                  :add => Proc.new { |field, kind| "add_column :#{field}, #{kind.camelize}"  },
                  :remove => Proc.new { |field, kind| "drop_column :#{field}" }
                  )
          end
        end # SequelGen
      end # Orms
    end # Components
  end # Generators
end # Padrino