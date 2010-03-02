module Padrino
  module Generators
    module Components
      module Renderers

        module ErbGen
          def setup_renderer
            require_dependencies 'erubis'
          end
        end
      end
    end
  end
end