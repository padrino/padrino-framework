module Padrino
  module Generators
    module Components
      module Orms
        
        module SequelGen

          SEQUEL = (<<-SEQUEL).gsub(/^ {10}/, '')
          module DatabaseSetup
            def self.registered(app)
              Sequel::Model.plugin(:schema)
              app.configure(:development) { Sequel.connect('your_dev_db_here') }
              app.configure(:production)  { Sequel.connect('your_production_db_here') }
              app.configure(:test)        { Sequel.connect('your_test_db_here') }
            end
          end
          SEQUEL

          def setup_orm
            require_dependencies 'sequel'
            create_file("config/database.rb", SEQUEL)
          end
        end

      end
    end
  end
end
