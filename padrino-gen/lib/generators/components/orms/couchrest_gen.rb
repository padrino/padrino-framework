module Padrino
  module Generators
    module Components
      module Orms

        module CouchrestGen

          COUCHREST = (<<-COUCHREST).gsub(/^ {10}/, '')
          module DatabaseSetup
            def self.registered(app)
              app.configure(:development) { set :couchdb, CouchRest.database!('your_dev_db_here') }
              app.configure(:production)  { set :couchdb, CouchRest.database!('your_production_db_here') }
              app.configure(:test)        { set :couchdb, CouchRest.database!('your_test_db_here') }
            end
          end
          COUCHREST


          def setup_orm
            require_dependencies 'couchrest'
            create_file("config/database.rb", COUCHREST)
          end

          CR_MODEL = (<<-MODEL).gsub(/^ {10}/, '')
          class !NAME! < CouchRest::ExtendedDocument
            include CouchRest::Validation

            use_database app { couchdb }

            unique_id :id
            # property <name>
            !FIELDS!
          end
          MODEL

          def create_model_file(name, fields)
            model_path = app_root_path('app/models/', "#{name.to_s.underscore}.rb")
            return false if File.exist?(model_path)
            field_tuples = fields.collect { |value| value.split(":") }
            column_declarations = field_tuples.collect { |field, kind| "property :#{field}" }.join("\n  ")
            model_contents = CR_MODEL.gsub(/!NAME!/, name.to_s.camelize)
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
