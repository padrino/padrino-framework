module Padrino
  module Generators
    module Components
      module Orms
        
        module DatamapperGen

          DM = (<<-DM).gsub(/^ {10}/, '')
          module DatabaseSetup
            def self.registered(app)
              app.configure(:development) { DataMapper.setup(:default, 'your_dev_db_here') }
              app.configure(:production)  { DataMapper.setup(:default, 'your_production_db_here') }
              app.configure(:test)        { DataMapper.setup(:default, 'your_test_db_here') }
            end
          end
          DM

          def setup_orm
            require_dependencies 'dm-core', 'dm-validations'
            create_file("config/database.rb", DM)
          end
        end
        
      end
    end
  end
end