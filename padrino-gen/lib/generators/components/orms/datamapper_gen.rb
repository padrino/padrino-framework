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
              create_table(:!TABLE!) do
                column(:id, Integer, :serial => true)
                !FIELDS!
              end
            end

            down do
              drop_table(:!TABLE!)
            end
          end
          MIGRATION

          def create_migration_file(filename, name, fields)
            model_name = name.to_s.pluralize
            field_tuples = fields.collect { |value| value.split(":") }
            column_declarations = field_tuples.collect { |field, kind|"column(:#{field}, #{kind.camelize})" }.join("\n      ")
            migration_contents = DM_MIGRATION.gsub(/!NAME!/, model_name.camelize).gsub(/!TABLE!/, model_name.underscore)
            migration_contents.gsub!(/!FILENAME!/, filename)
            migration_contents.gsub!(/!FIELDS!/, column_declarations)
            migration_filename = "#{Time.now.to_i}_#{filename}.rb"
            create_file(app_root_path('db/migrate/', migration_filename), migration_contents)
          end
        end

      end
    end
  end
end
