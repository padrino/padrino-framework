module Padrino
  module Generators
    module Components
      module Scripts
        
        module JqueryGen
          def setup_script
            copy_file('templates/scripts/jquery.js', destination_root("/app/public/javascripts/jquery.js"))
            create_file(destination_root('/app/public/javascripts/application.js'), "// Put your application scripts here")
          end
        end
        
      end
    end
  end
end