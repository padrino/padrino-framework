module Padrino
  module Generators
    module Components
      module Scripts

        module MootoolsGen
          def setup_script
            copy_file('templates/scripts/mootools-core.js', destination_root("/public/javascripts/mootools-core.js"))
            create_file(destination_root('/public/javascripts/application.js'), "// Put your application scripts here")
          end
        end
      end
    end
  end
end