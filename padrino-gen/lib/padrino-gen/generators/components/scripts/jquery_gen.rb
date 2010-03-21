module Padrino
  module Generators
    module Components
      module Scripts

        module JqueryGen
          def setup_script
            copy_file('templates/scripts/jquery.js', destination_root("/public/javascripts/jquery.js"))
            create_file(destination_root('/public/javascripts/application.js'), "// Put your application scripts here")
          end
        end # JqueryGen
      end # Scripts
    end # Components
  end # Generators
end # Padrino