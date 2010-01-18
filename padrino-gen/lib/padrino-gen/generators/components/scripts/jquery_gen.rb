module Padrino
  module Generators
    module Components
      module Scripts
        
        module JqueryGen
          def setup_script
            copy_file('templates/scripts/jquery.js', app_root_path("/app/public/javascripts/jquery.js"))
            create_file(app_root_path('/app/public/javascripts/application.js'), "// Put your application scripts here")
          end
        end
        
      end
    end
  end
end