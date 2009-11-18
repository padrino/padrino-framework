module Padrino
  module Generators
    module Components
      module Tests
        
        module RspecGen
          RSPEC_SETUP = (<<-TEST).gsub(/^ {10}/, '')
          Spec::Runner.configure do |conf|
            conf.include Rack::Test::Methods
          end

          def app
            CLASS_NAME.tap { |app| app.set :environment, :test }
          end
          TEST

          def setup_test
            require_dependencies 'spec', :env => :testing
            insert_test_suite_setup RSPEC_SETUP
          end

        end
      end
    end
  end
end
