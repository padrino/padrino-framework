module Padrino
  module Generators
    module Components
      module Tests

        module TestspecGen
          TESTSPEC_SETUP = (<<-TEST).gsub(/^ {10}/, '')
          class Test::Unit::TestCase
            include Rack::Test::Methods

            def app
              CLASS_NAME.tap { |app| app.set :environment, :test }
            end
          end
          TEST

          def setup_test
            require_dependencies 'test/spec', :env => :testing
            insert_test_suite_setup TESTSPEC_SETUP
          end

          TESTSPEC_CONTROLLER_TEST = (<<-TEST).gsub(/^ {10}/, '')
          require File.dirname(__FILE__) + '/../test_config.rb'

          context "!NAME!Controller" do
            setup { get('/') }
            specify "returns hello world" do
              last_response.body.should.equal "Hello World"
            end
          end
          TEST

          # Generates a controller test given the controllers name
          def generate_controller_test(name, root)
            testspec_contents = TESTSPEC_CONTROLLER_TEST.gsub(/!NAME!/, name.to_s.camelize)
            create_file File.join(root, "test/controllers/#{name}_controller_test.rb"), testspec_contents
          end

          TESTSPEC_MODEL_TEST = (<<-TEST).gsub(/^ {10}/, '')
          require File.dirname(__FILE__) + '/../test_config.rb'

          context "!NAME! Model" do
            specify 'can be created' do
              @!DNAME! = !NAME!.new
              @!DNAME!.should.not.be.nil
            end
          end
          TEST

          def generate_model_test(name)
            tests_contents = TESTSPEC_MODEL_TEST.gsub(/!NAME!/, name.to_s.camelize).gsub(/!DNAME!/, name.downcase.underscore)
            create_file app_root_path("test/models/#{name.to_s.downcase}_test.rb"), tests_contents
          end

        end

      end
    end
  end
end
