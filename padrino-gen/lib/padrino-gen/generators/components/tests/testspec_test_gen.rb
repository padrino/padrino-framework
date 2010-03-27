module Padrino
  module Generators
    module Components
      module Tests

        module TestspecGen
          TESTSPEC_SETUP = (<<-TEST).gsub(/^ {10}/, '')
          PADRINO_ENV = 'test' unless defined?(PADRINO_ENV)
          require File.expand_path(File.dirname(__FILE__) + "/../config/boot")

          class Test::Unit::TestCase
            include Rack::Test::Methods

            def app
              ##
              # You can hanlde all padrino applications using instead:
              #   Padrino.application
              CLASS_NAME.tap { |app|  }
            end
          end
          TEST

          TESTSPEC_CONTROLLER_TEST = (<<-TEST).gsub(/^ {10}/, '')
          require File.expand_path(File.dirname(__FILE__) + '/../test_config.rb')

          context "!NAME!Controller" do
            setup { get('/') }
            specify "returns hello world" do
              last_response.body.should.equal "Hello World"
            end
          end
          TEST

          TESTSPEC_RAKE = (<<-TEST).gsub(/^ {10}/, '')
          require 'rake/testtask'

          Rake::TestTask.new(:test) do |test|
            test.pattern = '**/*_test.rb'
            test.verbose = true
          end
          TEST

          TESTSPEC_MODEL_TEST = (<<-TEST).gsub(/^ {10}/, '')
          require File.expand_path(File.dirname(__FILE__) + '/../test_config.rb')

          context "!NAME! Model" do
            specify 'can be created' do
              @!DNAME! = !NAME!.new
              @!DNAME!.should.not.be.nil
            end
          end
          TEST

          def setup_test
            require_dependencies 'test-spec', :require => 'test/spec', :group => 'test'
            insert_test_suite_setup TESTSPEC_SETUP
            create_file destination_root("test/test.rake"), TESTSPEC_RAKE
          end

          # Generates a controller test given the controllers name
          def generate_controller_test(name)
            testspec_contents = TESTSPEC_CONTROLLER_TEST.gsub(/!NAME!/, name.to_s.camelize)
            create_file destination_root("test/controllers/#{name}_controller_test.rb"), testspec_contents, :skip => true
          end

          def generate_model_test(name)
            tests_contents = TESTSPEC_MODEL_TEST.gsub(/!NAME!/, name.to_s.camelize).gsub(/!DNAME!/, name.downcase.underscore)
            create_file destination_root("test/models/#{name.to_s.downcase}_test.rb"), tests_contents, :skip => true
          end
        end # TestspecGen
      end # Tests
    end # Components
  end # Generators
end # Padrino