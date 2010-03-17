module Padrino
  module Generators
    module Components
      module Renderers

        module HamlGen

          def setup_renderer
            require_dependencies 'haml'
          end
        end

      end
    end
  end
end
