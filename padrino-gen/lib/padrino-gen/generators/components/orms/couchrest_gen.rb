module Padrino
  module Generators
    module Components
      module Orms

        module CouchrestGen

          COUCHREST = (<<-COUCHREST).gsub(/^ {10}/, '')
          case Padrino.env
            when :development then COUCHDB = '!NAME!_name_development'
            when :production  then COUCHDB = '!NAME!_name_production'
            when :test        then COUCHDB = '!NAME!_name_test'
          end
          CouchRest.database!(COUCHDB)
          COUCHREST

          def setup_orm
            require_dependencies 'couchrest'
            require_dependencies 'json_pure'
            create_file("config/database.rb", COUCHREST.gsub(/!NAME!/, name.underscore))
            empty_directory('app/models')
          end

          CR_MODEL = (<<-MODEL).gsub(/^ {10}/, '')
          class !NAME! < CouchRest::ExtendedDocument
            include CouchRest::Validation

            use_database COUCHDB

            unique_id :id
            # property <name>
            !FIELDS!
          end
          MODEL

          def create_model_file(name, fields)
            model_path = destination_root('app/models/', "#{name.to_s.underscore}.rb")
            field_tuples = fields.collect { |value| value.split(":") }
            column_declarations = field_tuples.collect { |field, kind| "property :#{field}" }.join("\n  ")
            model_contents = CR_MODEL.gsub(/!NAME!/, name.to_s.camelize)
            model_contents.gsub!(/!FIELDS!/, column_declarations)
            create_file(model_path, model_contents)
          end

          def create_model_migration(filename, name, fields)
            # NO MIGRATION NEEDED
          end

          def create_migration_file(migration_name, name, columns)
            # NO MIGRATION NEEDED
          end
        end # ActiverecordGen
      end # Orms
    end # Components
  end # Generators
end # Padrino