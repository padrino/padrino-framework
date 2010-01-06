module Padrino
  module Generators
    module Components
      module Tests

        module ShouldaGen
          SHOULDA_SETUP = (<<-TEST).gsub(/^ {10}/, '')
          class Test::Unit::TestCase
            include Rack::Test::Methods

            def app
              CLASS_NAME.tap { |app| app.set :environment, :test }
            end
          end
          TEST

          def setup_test
            require_dependencies 'shoulda', :only => :testing
            insert_test_suite_setup SHOULDA_SETUP
          end

          SHOULDA_CONTROLLER_TEST = (<<-TEST).gsub(/^ {10}/, '')
          require File.dirname(__FILE__) + '/../test_config.rb'

          class !NAME!ControllerTest < Test::Unit::TestCase
            context "!NAME!Controller" do
              setup do
                get '/'
              end

              should "return hello world text" do
                assert_equal "Hello World", last_response.body
              end
            end
          end
          TEST

          # Generates a controller test given the controllers name
          def generate_controller_test(name, root)
            shoulda_contents = SHOULDA_CONTROLLER_TEST.gsub(/!NAME!/, name.to_s.camelize)
            create_file File.join(root, "test/controllers/#{name}_controller_test.rb"), shoulda_contents, :skip => true
          end

          SHOULDA_MODEL_TEST = (<<-TEST).gsub(/^ {10}/, '')
          require File.dirname(__FILE__) + '/../test_config.rb'

          class !NAME!ControllerTest < Test::Unit::TestCase
            context "!NAME! Model" do
              should 'construct new instance' do
                @!DNAME! = !NAME!.new
                assert_not_nil @!DNAME!
              end
            end
          end
          TEST

          def generate_model_test(name)
            shoulda_contents = SHOULDA_MODEL_TEST.gsub(/!NAME!/, name.to_s.camelize).gsub(/!DNAME!/, name.downcase.underscore)
            create_file app_root_path("test/models/#{name.to_s.downcase}_test.rb"), shoulda_contents, :skip => true
          end

        end

      end
    end
  end
end
