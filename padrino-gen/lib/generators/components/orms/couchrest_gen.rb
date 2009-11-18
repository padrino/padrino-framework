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
        end
        
      end
    end
  end
end
        