module Padrino
  module Generators
    module Components
      module Scripts
        
        module PrototypeGen
          def setup_script
            copy_file('templates/scripts/protopak.js', app_root_path("/app/public/javascripts/protopak.js"))
            copy_file('templates/scripts/lowpro.js', app_root_path("/app/public/javascripts/lowpro.js"))
            create_file(app_root_path('/app/public/javascripts/application.js'), "// Put your application scripts here")
          end
        end
        
      end
    end
  end
end