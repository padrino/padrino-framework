module Padrino
  module Generators
    module Components
      module Tests
        
        module BaconGen
          BACON_SETUP = (<<-TEST).gsub(/^ {10}/, '')
          class Bacon::Context
            include Rack::Test::Methods
          end

          def app
            CLASS_NAME.tap { |app| app.set :environment, :test }
          end
          TEST

          def setup_test
            require_dependencies 'bacon', :env => :testing
            insert_test_suite_setup BACON_SETUP
          end

        end
        
      end
    end
  end
end
