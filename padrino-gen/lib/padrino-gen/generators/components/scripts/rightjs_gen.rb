module Padrino
  module Generators
    module Components
      module Scripts
        
        module RightjsGen
          def setup_script
            copy_file('templates/scripts/right.js', "public/javascripts/right.js")
            create_file('public/javascripts/application.js', "// Put your application scripts here")
          end
        end
        
        
      end
    end
  end
end