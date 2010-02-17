module Padrino
  module Generators
    module Components
      module Tests

        module ShouldaGen
          SHOULDA_SETUP = (<<-TEST).gsub(/^ {10}/, '')
          class Test::Unit::TestCase
            include Rack::Test::Methods

            def app
              # Sinatra < 1.0 always disable sessions for test env
              # so if you need them it's necessary force the use 
              # of Rack::Session::Cookie
              CLASS_NAME.tap { |app| app.use Rack::Session::Cookie }
              # You can hanlde all padrino applications using instead:
              #   Padrino.application
            end
          end
          TEST

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

          SHOULDA_RAKE = (<<-TEST).gsub(/^ {10}/, '')
          require 'rake/testtask'

          Rake::TestTask.new(:test) do |test|
            test.pattern = '**/*_test.rb'
            test.verbose = true
          end
          TEST

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

          def setup_test
            require_dependencies 'shoulda', :group => 'test'
            insert_test_suite_setup SHOULDA_SETUP
            create_file destination_root("test/test.rake"), SHOULDA_RAKE
          end

          # Generates a controller test given the controllers name
          def generate_controller_test(name)
            shoulda_contents = SHOULDA_CONTROLLER_TEST.gsub(/!NAME!/, name.to_s.camelize)
            create_file destination_root("test/controllers/#{name}_controller_test.rb"), shoulda_contents, :skip => true
          end

          def generate_model_test(name)
            shoulda_contents = SHOULDA_MODEL_TEST.gsub(/!NAME!/, name.to_s.camelize).gsub(/!DNAME!/, name.downcase.underscore)
            create_file destination_root("test/models/#{name.to_s.downcase}_test.rb"), shoulda_contents, :skip => true
          end

        end

      end
    end
  end
end
