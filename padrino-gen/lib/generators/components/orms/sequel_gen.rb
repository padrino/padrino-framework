module Padrino
  module Generators
    module Components
      module Orms

        module SequelGen

          SEQUEL = (<<-SEQUEL).gsub(/^ {10}/, '')
          module DatabaseSetup
            def self.registered(app)
              Sequel::Model.plugin(:schema)
              app.configure(:development) { Sequel.connect("sqlite://your_dev_db_here", :loggers => [logger]) }
              app.configure(:production)  { Sequel.connect("sqlite://your_production_db_here", :loggers => [logger]) }
              app.configure(:test)        { Sequel.connect("sqlite://your_test_db_here", :loggers => [logger]) }
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
            model_path = app_root_path('app/models/', "#{name.to_s.underscore}.rb")
            return false if File.exist?(model_path)
            model_contents = SQ_MODEL.gsub(/!NAME!/, name.to_s.downcase.camelize)
            create_file(model_path, model_contents)
          end

          SQ_MIGRATION = (<<-MIGRATION).gsub(/^ {10}/, '')
          class !FILENAME! < Sequel::Migration
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

          def create_model_migration(filename, name, fields)
            model_name = name.to_s.pluralize
            field_tuples = fields.collect { |value| value.split(":") }
            field_tuples.collect! { |field, kind| kind =~ /datetime/i ? [field, 'DateTime'] : [field, kind] } # fix datetime
            column_declarations = field_tuples.collect { |field, kind| "#{kind.camelize} :#{field}" }.join("\n      ")
            migration_contents = SQ_MIGRATION.gsub(/\s{4}!UP!\n/m, SQ_MODEL_UP_MG).gsub(/!DOWN!\n/m, SQ_MODEL_DOWN_MG)
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
            tuples.collect! { |field, kind| kind =~ /datetime/i ? [field, 'DateTime'] : [field, kind] } # fix datetime
            add_cols = tuples.collect { |field, kind| "add_column :#{field}, #{kind.camelize}" }.join("  \n      ")
            add_cols = "alter_table :#{table_name} do\n      #{add_cols}\n    end" if tuples.any?
            remove_cols = tuples.collect { |field, kind| "drop_column :#{field}" }.join("  \n      ")
            remove_cols = "alter_table :#{table_name} do\n      #{remove_cols}\n    end" if tuples.any?
            migration_contents = SQ_MIGRATION.dup
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
