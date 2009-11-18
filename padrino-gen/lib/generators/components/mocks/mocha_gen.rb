module Padrino
  module Generators
    module Components
      module Mocks
        
        module MochaGen
          def setup_mock
            require_dependencies 'mocha', :env => :testing
            insert_mocking_include "Mocha::API", :path => "test/test_config.rb"
          end
        end
        
      end
    end
  end
end