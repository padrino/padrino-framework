module Padrino
  module Generators
    module Components
      module Scripts
        
        module PrototypeGen
          def setup_script
            copy_file('templates/scripts/protopak.js', destination_root("/app/public/javascripts/protopak.js"))
            copy_file('templates/scripts/lowpro.js', destination_root("/app/public/javascripts/lowpro.js"))
            create_file(destination_root('/app/public/javascripts/application.js'), "// Put your application scripts here")
          end
        end
        
      end
    end
  end
end