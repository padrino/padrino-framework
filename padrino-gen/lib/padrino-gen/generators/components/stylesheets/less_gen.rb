module Padrino
  module Generators
    module Components
      module Stylesheets
        module LessGen
          LESS_INIT = (<<-LESS).gsub(/^ {10}/, '')
          # Enables support for Less template reloading for rack.
          # Store Less files by default within 'app/stylesheets/'
          # See http://github.com/kelredd/rack-less for more details.

          module LessInitializer
            def self.registered(app)
              require 'rack/less'
              # optional - use as necessary
              Rack::Less.configure do |config|
                config.compress = true
                # other configs ...
              end
              app.use Rack::Less,
              :root      => app.root,
              :source    => 'stylesheets/',
              :public    => 'public/',
              :hosted_at => '/stylesheets'
            end
          end

          LESS

          LESS_REGISTER = (<<-LESSR).gsub(/^ {10}/, '')
              register LessInitializer\n
          LESSR

          def setup_stylesheet
            require_dependencies 'less', 'rack-less'
            create_file destination_root('/lib/less_plugin.rb'), LESS_INIT
            inject_into_file destination_root('/app/app.rb'), LESS_REGISTER, :after => "configure do\n"
            empty_directory destination_root('/app/stylesheets')
          end
        end # LessGen
      end # Stylesheets
    end # Components
  end # Generators
end # Padrino