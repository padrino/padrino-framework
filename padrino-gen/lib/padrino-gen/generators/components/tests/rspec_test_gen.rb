module Padrino
  module Generators
    module Components
      module Tests

        module RspecGen
          RSPEC_SETUP = (<<-TEST).gsub(/^ {10}/, '')
          Spec::Runner.configure do |conf|
            conf.include Rack::Test::Methods
          end

          def app
            CLASS_NAME.tap { |app| app.set :environment, :test }
          end
          TEST

          # TODO move to spec directory to follow convention
          def setup_test
            require_dependencies 'rspec', :group => :testing, :require => 'spec'
            insert_test_suite_setup RSPEC_SETUP
          end

          RSPEC_CONTROLLER_TEST = (<<-TEST).gsub(/^ {10}/, '')
          require File.dirname(__FILE__) + '/../test_config.rb'

          describe "!NAME!Controller" do
            setup { get('/') }
            it "returns hello world" do
              last_response.body.should == "Hello World"
            end
          end
          TEST

          # TODO move to spec directory to follow convention
          # Generates a controller test given the controllers name
          def generate_controller_test(name)
            rspec_contents = RSPEC_CONTROLLER_TEST.gsub(/!NAME!/, name.to_s.camelize)
            create_file destination_root("test/controllers/#{name}_controller_spec.rb"), rspec_contents, :skip => true
          end

          RSPEC_MODEL_TEST = (<<-TEST).gsub(/^ {10}/, '')
          require File.dirname(__FILE__) + '/../test_config.rb'

          describe "!NAME! Model" do
            it 'can be created' do
              @!DNAME! = !NAME!.new
              @!DNAME!.should.not.be nil
            end
          end
          TEST

          def generate_model_test(name)
            rspec_contents = RSPEC_MODEL_TEST.gsub(/!NAME!/, name.to_s.camelize).gsub(/!DNAME!/, name.downcase.underscore)
            create_file destination_root("test/models/#{name.to_s.downcase}_spec.rb"), rspec_contents, :skip => true
          end

        end
      end
    end
  end
end
