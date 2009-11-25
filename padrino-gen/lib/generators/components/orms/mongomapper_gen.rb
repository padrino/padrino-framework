module Padrino
  module Generators
    module Components
      module Orms

        module MongomapperGen

          MONGO = (<<-MONGO).gsub(/^ {10}/, '')
          class MongoDBConnectionFailure < RuntimeError; end

          module DatabaseSetup
            def self.registered(app)
              app.configure :development do
                MongoMapper.connection = Mongo::Connection.new('localhost', nil, :logger => logger)
                MongoMapper.database = 'your_dev_db_here'
              end

              app.configure :production do
                MongoMapper.connection = Mongo::Connection.new('localhost', nil, :logger => logger)
                MongoMapper.database = 'your_production_db_here'
              end

              app.configure :test do
                MongoMapper.connection = Mongo::Connection.new('localhost', nil, :logger => logger)
                MongoMapper.database = 'your_test_db_here'
              end
            end
          end
          MONGO

          def setup_orm
            require_dependencies 'mongo_mapper'
            create_file("config/database.rb", MONGO)
            empty_directory('app/models')
          end

          MM_MODEL = (<<-MODEL).gsub(/^ {10}/, '')
          class !NAME!
            include MongoMapper::Document

            # key <name>, <type>
            !FIELDS!
          end
          MODEL

          def create_model_file(name, fields)
            model_path = app_root_path('app/models/', "#{name.to_s.underscore}.rb")
            return false if File.exist?(model_path)
            field_tuples = fields.collect { |value| value.split(":") }
            column_declarations = field_tuples.collect { |field, kind| "key :#{field}, #{kind.camelize}" }.join("\n  ")
            model_contents = MM_MODEL.gsub(/!NAME!/, name.to_s.camelize)
            model_contents.gsub!(/!FIELDS!/, column_declarations)
            create_file(model_path, model_contents)
          end

          def create_migration_file(filename, name, fields)
            # NO MIGRATION NEEDED
          end
        end

      end
    end
  end
end
