module Padrino
  module Generators
    module Components
      module Mocks
        
        module RrGen
          def setup_mock
            require_dependencies 'rr', :only => :testing
            insert_mocking_include "RR::Adapters::RRMethods", :path => "test/test_config.rb"
          end
        end
        
      end
    end
  end
end