module Padrino
  module Generators
    module Components
      module Tests

        module RiotGen
          RIOT_SETUP = (<<-TEST).gsub(/^ {10}/, '')
          PADRINO_ENV = 'test' unless defined?(PADRINO_ENV)
          require File.expand_path(File.dirname(__FILE__) + "/../config/boot")

          class Riot::Situation
            include Rack::Test::Methods

            def app
              ##
              # You can handle all padrino applications using instead:
              #   Padrino.application
              CLASS_NAME.tap { |app|  }
            end
          end
          TEST

          RIOT_CONTROLLER_TEST = (<<-TEST).gsub(/^ {10}/, '')
          require File.expand_path(File.dirname(__FILE__) + '/../test_config.rb')

          context "!NAME!Controller" do
            context "description here" do
              setup do
                get "/"
              end

              asserts("the response body") { last_response.body }.equals "Hello World"
            end
          end
          TEST

          RIOT_RAKE = (<<-TEST).gsub(/^ {10}/, '')
          require 'rake/testtask'

          Rake::TestTask.new(:test) do |test|
            test.pattern = '**/*_test.rb'
            test.verbose = true
          end
          TEST

          RIOT_MODEL_TEST = (<<-TEST).gsub(/^ {10}/, '')
          require File.expand_path(File.dirname(__FILE__) + '/../test_config.rb')

          context "!NAME! Model" do
            context 'can be created' do
              setup do
                @!DNAME! = !NAME!.new
              end

              asserts("that record is not nil") { !@!DNAME!.nil? }
            end
          end
          TEST

          def setup_test
            require_dependencies 'riot', :group => 'test'
            insert_test_suite_setup RIOT_SETUP
            create_file destination_root("test/test.rake"), RIOT_RAKE
          end

          # Generates a controller test given the controllers name
          def generate_controller_test(name)
            riot_contents = RIOT_CONTROLLER_TEST.gsub(/!NAME!/, name.to_s.camelize)
            create_file destination_root("test/controllers/#{name.to_s.underscore}_controller_test.rb"), riot_contents, :skip => true
          end

          def generate_model_test(name)
            riot_contents = RIOT_MODEL_TEST.gsub(/!NAME!/, name.to_s.camelize).gsub(/!DNAME!/, name.to_s.underscore)
            create_file destination_root("test/models/#{name.to_s.underscore}_test.rb"), riot_contents, :skip => true
          end
        end # RiotGen
      end # Tests
    end # Components
  end # Generators
end # Padrino