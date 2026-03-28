module Padrino
  module Helpers
    module OutputHelpers
      if defined?(Haml) && defined?(Haml::VERSION) && Gem::Version.new(Haml::VERSION) >= Gem::Version.new('6')
        ##
        # Handler for Haml 6+ templates (uses Hamlit internally).
        #
        class HamlitHandler < AbstractHandler
          ##
          # Returns true if the block is for Hamlit.
          #
          def engine_matches?(block)
            block.binding.eval('defined? __in_hamlit_template')
          end
        end
        OutputHelpers.register(:haml, HamlitHandler)
      elsif defined?(Haml) && Tilt.template_for('.haml').to_s == 'Padrino::Rendering::HamlTemplate'
        ##
        # Handler for Haml 5 templates.
        #
        class HamlHandler < AbstractHandler
          ##
          # Returns true if the block is for Haml
          #
          def engine_matches?(block)
            template.block_is_haml?(block)
          end

          ##
          # Captures the html from a block of template code for this handler.
          #
          def capture_from_template(*args, &block)
            engine_matches?(block) ? template.capture_haml(*args, &block) : yield(*args)
          end
        end
        OutputHelpers.register(:haml, HamlHandler)
      else
        ##
        # Handler for standalone Hamlit templates.
        #
        class HamlitHandler < AbstractHandler
          ##
          # Returns true if the block is for Hamlit.
          #
          def engine_matches?(block)
            block.binding.eval('defined? __in_hamlit_template')
          end
        end
        OutputHelpers.register(:haml, HamlitHandler)
      end
    end
  end
end
