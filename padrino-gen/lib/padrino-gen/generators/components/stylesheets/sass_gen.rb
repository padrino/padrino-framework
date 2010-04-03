module Padrino
  module Generators
    module Components
      module Stylesheets
        module SassGen
          SASS_INIT = (<<-SASS).gsub(/^ {10}/, '')
          # Enables support for SASS template reloading in rack applications.
          # See http://nex-3.com/posts/88-sass-supports-rack for more details.
          # Store SASS files (by default) within 'app/stylesheets'

          module SassInitializer
            def self.registered(app)
              require 'sass/plugin/rack'
              Sass::Plugin.options[:template_location] = Padrino.root("app/stylesheets")
              Sass::Plugin.options[:css_location] = Padrino.root("public/stylesheets")
              app.use Sass::Plugin::Rack
            end
          end
          SASS

          SASS_REGISTER = (<<-SASSR).gsub(/^ {10}/, '')
              register SassInitializer\n
          SASSR

          def setup_stylesheet
            require_dependencies 'haml'
            create_file destination_root('/lib/sass.rb'), SASS_INIT
            inject_into_file destination_root('/app/app.rb'), SASS_REGISTER, :after => "configure do\n"
            empty_directory destination_root('/app/stylesheets')
          end
        end # SassGen
      end # Stylesheets
    end # Components
  end # Generators
end # Padrino