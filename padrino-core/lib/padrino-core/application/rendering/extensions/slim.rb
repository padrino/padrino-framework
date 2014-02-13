begin
  require 'slim'

  if defined? Padrino::Rendering
    module Temple
      module Generators
        class PadrinoOutputBuffer < RailsOutputBuffer
          def on_dynamic(code)
            concat("__in_slim_template = false; __code_result = (#{code}).to_s; __in_slim_template = true; __code_result")
          end
        end
      end
    end

    Padrino::Rendering.engine_configurations[:slim] = {
      :generator => Temple::Generators::PadrinoOutputBuffer,
      :buffer => "@_out_buf",
      :use_html_safe => true,
      :disable_capture => true,
    }

    class Slim::Template
      include Padrino::Rendering::SafeTemplate

      def precompiled_preamble(locals)
        "__in_slim_template = true\n" << super
      end
    end
  end
rescue LoadError
end
