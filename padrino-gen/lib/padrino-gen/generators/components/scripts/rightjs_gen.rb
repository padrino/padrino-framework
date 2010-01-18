module Padrino
  module Generators
    module Components
      module Scripts
        
        module RightjsGen
          def setup_script
            copy_file('templates/scripts/right.js', app_root_path("/app/public/javascripts/right.js"))
            create_file(app_root_path('/app/public/javascripts/application.js'), "// Put your application scripts here")
          end
        end
        
        
      end
    end
  end
end