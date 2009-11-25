module Padrino
  module Generators
    module Components
      module Orms

        module DatamapperGen
          DM = (<<-DM).gsub(/^ {10}/, '')
          module DatabaseSetup
            def self.registered(app)
              app.configure               { DataMapper.logger = logger }
              app.configure(:development) { DataMapper.setup(:default, "sqlite3://your_dev_db_here") }
              app.configure(:production)  { DataMapper.setup(:default, "sqlite3://your_production_db_here") }
              app.configure(:test)        { DataMapper.setup(:default, "sqlite3://your_test_db_here") }
            rescue ArgumentError => e
              logger.error "Database options need to be configured within 'config/database.rb'!" if app.logging?
            end
          end
          DM

          def setup_orm
            require_dependencies 'dm-core', 'dm-validations'
            create_file("config/database.rb", DM)
            empty_directory('app/models')
          end

          DM_MODEL = (<<-MODEL).gsub(/^ {10}/, '')
          class !NAME!
            include DataMapper::Resource

            # property <name>, <type>
            property :id,       Serial
            !FIELDS!
          end
          MODEL

          def create_model_file(name, fields)
            model_path = app_root_path('app/models/', "#{name.to_s.underscore}.rb")
            return false if File.exist?(model_path)
            model_contents = DM_MODEL.gsub(/!NAME!/, name.to_s.downcase.camelize)
            field_tuples = fields.collect { |value| value.split(":") }
            field_tuples.collect! { |field, kind| kind =~ /datetime/i ? [field, 'DateTime'] : [field, kind] } # fix datetime
            column_declarations = field_tuples.collect { |field, kind|"property :#{field}, #{kind.camelize}" }.join("\n  ")
            model_contents.gsub!(/!FIELDS!/, column_declarations)
            create_file(model_path, model_contents)
          end

          DM_MIGRATION = (<<-MIGRATION).gsub(/^ {10}/, '')
          migration NUM, :!FILENAME! do
            up do
              !UP!
            end

            down do
              !DOWN!
            end
          end
          MIGRATION

          DM_MODEL_UP_MG =  (<<-MIGRATION).gsub(/^ {6}/, '')
          create_table(:!TABLE!) do
            column(:id, Integer, :serial => true)
            !FIELDS!
          end
          MIGRATION

          DM_MODEL_DOWN_MG =  (<<-MIGRATION).gsub(/^ {10}/, '')
          drop_table(:!TABLE!)
          MIGRATION

          def create_model_migration(filename, name, fields)
            model_name = name.to_s.pluralize
            field_tuples = fields.collect { |value| value.split(":") }
            field_tuples.collect! { |field, kind| kind =~ /datetime/i ? [field, 'DateTime'] : [field, kind] } # fix datetime
            column_declarations = field_tuples.collect { |field, kind|"column(:#{field}, #{kind.camelize})" }.join("\n      ")
            migration_contents = DM_MIGRATION.gsub(/\s{4}!UP!\n/m, DM_MODEL_UP_MG).gsub(/!DOWN!\n/m, DM_MODEL_DOWN_MG)
            migration_contents.gsub!(/!NAME!/, model_name.camelize)
            migration_contents.gsub!(/!TABLE!/, model_name.underscore)
            migration_contents.gsub!(/!FILENAME!/, filename)
            migration_contents.gsub!(/!FIELDS!/, column_declarations)
            migration_filename = "#{Time.now.strftime("%Y%m%d%H%M%S")}_#{filename}.rb"
            create_file(app_root_path('db/migrate/', migration_filename), migration_contents)
          end

          def create_migration_file(migration_name, name, columns)
            migration_scan = migration_name.camelize.scan(/(Add|Remove)(?:.*?)(?:To|From)(.*?)$/).flatten
            direction, table_name = migration_scan[0].downcase, migration_scan[1].downcase.pluralize if migration_scan.any?
            tuples = direction ? columns.collect { |value| value.split(":") } : []
            tuples.collect! { |field, kind| kind =~ /datetime/i ? [field, 'DateTime'] : [field, kind] } # fix datetime
            add_cols = tuples.collect { |field, kind| "add_column :#{field}, #{kind.camelize}" }.join("  \n      ")
            add_cols = "modify_table :#{table_name} do\n      #{add_cols}\n    end" if tuples.any?
            remove_cols = tuples.collect { |field, kind| "drop_column :#{field}" }.join("  \n      ")
            remove_cols = "modify_table :#{table_name} do\n      #{remove_cols}\n   end" if tuples.any?
            migration_contents = DM_MIGRATION.dup
            migration_contents.gsub!(/!FILENAME!/, migration_name.underscore)
            migration_contents.gsub!(/!UP!/m,   (direction == 'add' ? add_cols : remove_cols))
            migration_contents.gsub!(/!DOWN!/m, (direction == 'add' ? remove_cols : add_cols))
            migration_filename = "#{Time.now.strftime("%Y%m%d%H%M%S")}_#{migration_name.underscore}.rb"
            create_file(app_root_path('db/migrate/', migration_filename), migration_contents)
          end
        end

      end
    end
  end
end
