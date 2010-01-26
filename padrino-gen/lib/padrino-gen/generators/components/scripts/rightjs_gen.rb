module Padrino
  module Generators
    module Components
      module Scripts
        
        module RightjsGen
          def setup_script
            copy_file('templates/scripts/right.js', destination_root("/app/public/javascripts/right.js"))
            create_file(destination_root('/app/public/javascripts/application.js'), "// Put your application scripts here")
          end
        end
      end
    end
  end
end