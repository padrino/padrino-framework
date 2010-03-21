module Padrino
  module Generators
    module Components
      module Tests

        module RspecGen
          unless defined?(RSPEC_SETUP)
            RSPEC_SETUP = (<<-TEST).gsub(/^ {12}/, '')
            PADRINO_ENV = 'test' unless defined?(PADRINO_ENV)
            require File.dirname(__FILE__) + "/../config/boot"

            Spec::Runner.configure do |conf|
              conf.include Rack::Test::Methods
            end

            def app
              # Sinatra < 1.0 always disable sessions for test env
              # so if you need them it's necessary force the use
              # of Rack::Session::Cookie
              CLASS_NAME.tap { |app| app.use Rack::Session::Cookie }
              # You can hanlde all padrino applications using instead:
              #   Padrino.application
            end
            TEST
          end

          unless defined?(RSPEC_CONTROLLER_TEST)
            RSPEC_CONTROLLER_TEST = (<<-TEST).gsub(/^ {12}/, '')
            require File.dirname(__FILE__) + '/../spec_helper.rb'

            describe "!NAME!Controller" do
              before do
                get "/"
              end

              it "returns hello world" do
                last_response.body.should == "Hello World"
              end
            end
            TEST
          end

          unless defined?(RSPEC_RAKE)
            RSPEC_RAKE = (<<-TEST).gsub(/^ {12}/, '')
            require 'spec/rake/spectask'

            Spec::Rake::SpecTask.new(:spec) do |t|
              t.spec_files = Dir['**/*_spec.rb']
              t.spec_opts  = %w(-fs --color)
            end
            TEST
          end

          unless defined?(RSPEC_MODEL_TEST)
            RSPEC_MODEL_TEST = (<<-TEST).gsub(/^ {12}/, '')
            require File.dirname(__FILE__) + '/../spec_helper.rb'

            describe "!NAME! Model" do
              it 'can be created' do
                @!DNAME! = !NAME!.new
                @!DNAME!.should_not be_nil
              end
            end
            TEST
          end

          def setup_test
            require_dependencies 'rspec', :require => 'spec', :group => 'test'
            insert_test_suite_setup RSPEC_SETUP, :path => "spec/spec_helper.rb"
            create_file destination_root("spec/spec.rake"), RSPEC_RAKE
          end

          # Generates a controller test given the controllers name
          def generate_controller_test(name)
            rspec_contents = RSPEC_CONTROLLER_TEST.gsub(/!NAME!/, name.to_s.camelize)
            create_file destination_root("spec/controllers/#{name}_controller_spec.rb"), rspec_contents, :skip => true
          end

          def generate_model_test(name)
            rspec_contents = RSPEC_MODEL_TEST.gsub(/!NAME!/, name.to_s.camelize).gsub(/!DNAME!/, name.downcase.underscore)
            create_file destination_root("spec/models/#{name.to_s.downcase}_spec.rb"), rspec_contents, :skip => true
          end
        end # RspecGen
      end # Tests
    end # Components
  end # Generators
end # Padrino