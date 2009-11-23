module Padrino
  module Generators
    module Components
      module Renderers

        module HamlGen

          SASS_INIT = (<<-SASS).gsub(/^ {10}/, '')
          # Enables support for SASS template reloading for rack.
          # See http://nex-3.com/posts/88-sass-supports-rack for more details.

          module SassInitializer
            def self.registered(app)
              require 'sass/plugin/rack'
              app.use Sass::Plugin::Rack
            end
          end
          SASS

          def setup_renderer
            require_dependencies 'haml'
            create_file 'config/initializers/sass.rb', SASS_INIT
            empty_directory 'public/stylesheets/sass'
          end
        end

      end
    end
  end
end
