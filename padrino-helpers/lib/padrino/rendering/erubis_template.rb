module Padrino
  module Rendering
    ##
    # SafeBufferEnhancer is an Erubis Enhancer that compiles templates that
    # are fit for using SafeBuffer as a Buffer.
    #
    # @api private
    module SafeBufferEnhancer
      def add_expr_literal(src, code)
        src << " @__in_ruby_literal = true; #{@bufvar}.concat((" << code << ').to_s); @__in_ruby_literal = false;'
      end

      def add_stmt(src, code)
        code = code.sub('end', 'nil;end') if code =~ /\A\s*end\s*\Z/
        src << code
        src << ';' unless code[-1] == ?\n
      end

      def add_expr_escaped(src, code)
        src << " #{@bufvar}.safe_concat " << code << ';'
      end

      def add_text(src, text)
        src << " #{@bufvar}.safe_concat '" << escape_text(text) << "';" unless text.empty?
      end
    end

    ##
    # SafeBufferTemplate is the Eruby engine, augmented with SafeBufferEnhancer.
    #
    # @api private
    class SafeEruby < ::Erubis::Eruby
      include SafeBufferEnhancer
    end

    ##
    # Modded ErubisTemplate that doesn't insist in an String as output
    # buffer.
    #
    # @api private
    class ErubisTemplate < Tilt::ErubisTemplate
      def render(*args)
        app       = args.first
        app_class = app.class
        @is_padrino_app = (defined?(Padrino::Application) && app.kind_of?(Padrino::Application)) || 
                          (app_class.respond_to?(:erb) && app_class.erb[:engine_class] == Padrino::Rendering::SafeEruby)
        super
      end

      ##
      # In preamble we need a flag `__in_erb_template` and SafeBuffer for padrino apps.
      #
      def precompiled_preamble(locals)
        original = super
        return original unless @is_padrino_app
        "__in_erb_template = true\n" << original.rpartition("\n").first << "#{@outvar} = _buf = SafeBuffer.new\n"
      end
    end
  end
end

Tilt.prefer(Padrino::Rendering::ErubisTemplate, :erb)

Padrino::Rendering.engine_configurations[:erb] = {
  :engine_class => Padrino::Rendering::SafeEruby,
}
