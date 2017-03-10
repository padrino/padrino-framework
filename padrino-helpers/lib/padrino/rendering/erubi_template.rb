module Padrino
  module Rendering
    module Erubi
      module SafeBufferEnhancer
        def add_expression_result(code)
          @src << " @__in_ruby_literal = true; #{bufvar}.concat((" << code << ').to_s); @__in_ruby_literal = false;'
        end

        def add_expression_result_escaped(code)
          @src << " #{bufvar}.safe_concat (" << code << ");"
        end

        def add_text(text)
          @src << " #{bufvar}.safe_concat '" << text.gsub(/['\\]/, '\\\\\&') << "';" unless text.empty?
        end
      end
    end

    class SafeErubi < ::Erubi::Engine
      include Erubi::SafeBufferEnhancer
    end

    class ErubiTemplate < Tilt::ErubiTemplate
      def precompiled_preamble(*)
        "__in_erb_template = true\n" << super
      end
    end
  end
end

Tilt.prefer(Padrino::Rendering::ErubiTemplate, :erb)

Padrino::Rendering.engine_configurations[:erb] = {
  :bufval => "SafeBuffer.new",
  :bufvar => "@_out_buf",
  :engine_class => Padrino::Rendering::SafeErubi
}
