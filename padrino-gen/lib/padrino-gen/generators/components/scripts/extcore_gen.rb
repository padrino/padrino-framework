module Padrino
  module Generators
    module Components
      module Scripts

        module ExtcoreGen
          def setup_script
            copy_file('templates/scripts/ext-core.js', destination_root("/public/javascripts/ext-core.js"))
            create_file(destination_root('/public/javascripts/application.js'), "// Put your application scripts here")
          end
        end # ExtCoreGen
      end # Scripts
    end # Components
  end # Generators
end # Padrino
