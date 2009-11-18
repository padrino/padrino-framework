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

          # Setup the testing configuration helper and dependencies
          def setup_test
            require_dependencies 'bacon', :env => :testing
            insert_test_suite_setup BACON_SETUP
          end
          
          BACON_CONTROLLER_TEST = (<<-TEST).gsub(/^ {10}/, '')
          require File.dirname(__FILE__) + '/../test_config.rb'

          describe "!NAME!Controller" do
            it 'returns text at root' do
              get '/'
              last_response.body.should == "some text"
            end
          end
          TEST
          
          # Generates a controller test given the controllers name
          def generate_controller_test(name, root)
            bacon_contents = BACON_CONTROLLER_TEST.gsub(/!NAME!/, name.to_s.camelize)
            create_file File.join(root, "test/controllers/#{name}_controller_test.rb"), bacon_contents
          end

        end
        
      end
    end
  end
end
