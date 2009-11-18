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
                MongoMapper.connection = Mongo::Connection.new('localhost')
                MongoMapper.database = 'your_dev_db_here'
              end

              app.configure :production do
                MongoMapper.connection = Mongo::Connection.new('localhost')
                MongoMapper.database = 'your_production_db_here'
              end

              app.configure :test do
                MongoMapper.connection = Mongo::Connection.new('localhost')
                MongoMapper.database = 'your_test_db_here'
              end
            end
          end
          MONGO

          CONCERNED = (<<-CONCERN).gsub(/^ {10}/, '')
          module MongoMapper
            module Document
              module ClassMethods
                # TODO find a cleaner way for it to know where to look for dependencies
                def concerned_with(*concerns)
                  concerns.each { |concern| require_dependency "./app/models/\#{name.underscore}/\#{concern}" }
                end
              end
            end
          end
          CONCERN

          def setup_orm
            require_dependencies 'mongo_mapper'
            create_file("config/database.rb", MONGO)
            create_file("lib/ext/mongo_mapper.rb", CONCERNED)
          end
        end
        
      end
    end
  end
end