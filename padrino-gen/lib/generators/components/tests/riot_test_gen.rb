module Padrino
  module Generators
    module Components
      module Tests

        module RiotGen
          RIOT_SETUP = (<<-TEST).gsub(/^ {10}/, '')
          class Riot::Situation
            include Rack::Test::Methods

            def app
              CLASS_NAME.tap { |app| app.set :environment, :test }
            end
          end
          TEST

          def setup_test
            require_dependencies 'riot', :env => :testing
            insert_test_suite_setup RIOT_SETUP
          end

          RIOT_CONTROLLER_TEST = (<<-TEST).gsub(/^ {10}/, '')
          require File.dirname(__FILE__) + '/../test_config.rb'

          context "!NAME!Controller" do
            context "description here" do
              setup { get '/' }
              asserts("the response body") { last_response.body }.equals "Hello World"
            end
          end
          TEST

          # Generates a controller test given the controllers name
          def generate_controller_test(name, root)
            riot_contents = RIOT_CONTROLLER_TEST.gsub(/!NAME!/, name.to_s.camelize)
            create_file File.join(root, "test/controllers/#{name}_controller_test.rb"), riot_contents
          end

        end

      end
    end
  end
end
