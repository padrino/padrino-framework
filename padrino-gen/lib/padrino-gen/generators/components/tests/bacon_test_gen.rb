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
            require_dependencies 'bacon', :group => 'test'
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
          def generate_controller_test(name)
            bacon_contents = BACON_CONTROLLER_TEST.gsub(/!NAME!/, name.to_s.camelize)
            create_file destination_root("test/controllers/","#{name}_controller_test.rb"), bacon_contents, :skip => true
          end

          BACON_MODEL_TEST = (<<-TEST).gsub(/^ {10}/, '')
          require File.dirname(__FILE__) + '/../test_config.rb'

          describe "!NAME! Model" do
            it 'can be created' do
              @!DNAME! = !NAME!.new
              @!DNAME!.should.not.be.nil
            end
          end
          TEST

          def generate_model_test(name)
            bacon_contents = BACON_MODEL_TEST.gsub(/!NAME!/, name.to_s.camelize).gsub(/!DNAME!/, name.downcase.underscore)
            create_file destination_root("test/models/#{name.to_s.downcase}_test.rb"), bacon_contents, :skip => true
          end

        end

      end
    end
  end
end
