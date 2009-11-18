module Padrino
  module Generators
    module Components
      module Scripts
        
        module PrototypeGen
          def setup_script
            get("http://prototypejs.org/assets/2009/8/31/prototype.js", "public/javascripts/prototype.js")
            get('http://github.com/nesquena/lowpro/raw/master/dist/lowpro.js', "public/javascripts/lowpro.js")
          end
        end
        
      end
    end
  end
end