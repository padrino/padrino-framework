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
            require_dependencies 'riot', :group => 'test'
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
          def generate_controller_test(name)
            riot_contents = RIOT_CONTROLLER_TEST.gsub(/!NAME!/, name.to_s.camelize)
            create_file destination_root("test/controllers/#{name}_controller_test.rb"), riot_contents, :skip => true
          end

          RIOT_MODEL_TEST = (<<-TEST).gsub(/^ {10}/, '')
          require File.dirname(__FILE__) + '/../test_config.rb'

          context "!NAME! Model" do
            context 'can be created' do
              setup { @!DNAME! = !NAME!.new }
              asserts("that record is not nil") { !@!DNAME!.nil? }
            end
          end
          TEST

          def generate_model_test(name)
            riot_contents = RIOT_MODEL_TEST.gsub(/!NAME!/, name.to_s.camelize).gsub(/!DNAME!/, name.downcase.underscore)
            create_file destination_root("test/models/#{name.to_s.downcase}_test.rb"), riot_contents, :skip => true
          end

        end

      end
    end
  end
end
