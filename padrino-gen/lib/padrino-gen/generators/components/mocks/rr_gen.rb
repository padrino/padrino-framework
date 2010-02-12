module Padrino
  module Generators
    module Components
      module Mocks

        module RrGen
          def setup_mock
            require_dependencies 'rr', :group => 'test'
            if options[:test] == 'riot'
              inject_into_file "test/test_config.rb","  Riot.rr\n", :after => "class Riot::Situation\n"
            else
              insert_mocking_include "RR::Adapters::RRMethods", :path => "test/test_config.rb"
            end
          end
        end

      end
    end
  end
end
