module Padrino
  module Generators
    module Components
      module Scripts
        
        module JqueryGen
          def setup_script
            copy_file('templates/scripts/jquery.js', "public/javascripts/jquery.js")
            create_file('public/javascripts/application.js', "// Put your application scripts here")
          end
        end
        
      end
    end
  end
end