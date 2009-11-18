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
            require_dependencies 'test/spec', :path => "test/test_config.rb"
            insert_test_suite_setup TESTSPEC_SETUP
          end
        end

      end
    end
  end
end
