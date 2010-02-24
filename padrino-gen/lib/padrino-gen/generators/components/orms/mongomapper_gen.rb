module Padrino
  module Generators
    module Components
      module Orms

        module MongomapperGen

          MONGO = (<<-MONGO).gsub(/^ {10}/, '')
          MongoMapper.connection = Mongo::Connection.new('localhost', nil, :logger => logger)

          case Padrino.env
            when :development then MongoMapper.database = '!NAME!_development'
            when :production  then MongoMapper.database = '!NAME!_production'
            when :test        then MongoMapper.database = '!NAME!_test'
          end
          MONGO

          def setup_orm
            require_dependencies 'mongo_ext', :require => 'mongo'
            require_dependencies 'mongo_mapper'
            create_file("config/database.rb", MONGO.gsub(/!NAME!/, name.underscore))
            empty_directory('app/models')
          end

          MM_MODEL = (<<-MODEL).gsub(/^ {10}/, '')
          class !NAME!
            include MongoMapper::Document

            # key <name>, <type>
            !FIELDS!
            timestamps!
          end
          MODEL

          def create_model_file(name, fields)
            model_path = destination_root('app/models/', "#{name.to_s.underscore}.rb")
            field_tuples = fields.collect { |value| value.split(":") }
            column_declarations = field_tuples.collect { |field, kind| "key :#{field}, #{kind.camelize}" }.join("\n  ")
            model_contents = MM_MODEL.gsub(/!NAME!/, name.to_s.camelize)
            model_contents.gsub!(/!FIELDS!/, column_declarations)
            create_file(model_path, model_contents)
          end

          def create_model_migration(filename, name, fields)
            # NO MIGRATION NEEDED
          end

          def create_migration_file(migration_name, name, columns)
            # NO MIGRATION NEEDED
          end
        end

      end
    end
  end
end
