module Padrino
  module Rendering
    class SlimTemplate < Slim::Template
      include SafeTemplate

      def precompiled_preamble(locals)
        "__in_slim_template = true\n" << super
      end
    end
  end
end

Tilt.prefer(Padrino::Rendering::SlimTemplate, :slim)

Padrino::Rendering.engine_configurations[:slim] = {
  :generator => Temple::Generators::RailsOutputBuffer,
  :buffer => "@_out_buf",
  :use_html_safe => true,
  :disable_capture => true,
}
