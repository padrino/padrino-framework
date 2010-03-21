module Padrino
  module Generators
    module Components
      module Mocks

        module MochaGen
          def setup_mock
            require_dependencies 'mocha', :group => 'test'
            case options[:test].to_s
              when 'rspec'
                inject_into_file 'spec/spec_helper.rb', "  conf.mock_with :mocha\n", :after => "Spec::Runner.configure do |conf|\n"
              else
                insert_mocking_include "Mocha::API"
            end
          end
        end # MochaGen
      end # Mocks
    end # Components
  end # Generators
end # Padrino