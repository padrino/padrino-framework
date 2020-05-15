module Padrino
  module Rendering
    class SlimOutputBuffer < Temple::Generators::StringBuffer
      define_options :buffer_class => 'SafeBuffer'

      def call(exp)
        [preamble, compile(exp), postamble].flatten.compact.join('; '.freeze)
      end

      def create_buffer
        "#{buffer} = #{options[:buffer_class]}.new"
      end

      def concat(str)
        "#{buffer}.safe_concat((#{str}))"
      end
    end

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
  :generator => Padrino::Rendering::SlimOutputBuffer,
  :buffer => "@_out_buf",
  :use_html_safe => true,
  :disable_capture => true,
}
