module Padrino
  module Rendering
    class SafeERB < ::ERB
      class Compiler < ::ERB::Compiler
        def add_insert_cmd(out, content)
          out.push("@__in_ruby_literal = true")
          super
          out.push("@__in_ruby_literal = false")
        end
      end

      def make_compiler(trim_mode)
        Compiler.new(trim_mode)
      end

      def set_eoutvar(compiler, eoutvar = '_erbout')
        compiler.put_cmd = "#{eoutvar}.safe_concat"
        compiler.insert_cmd = "#{eoutvar}.concat"
        compiler.pre_cmd = ["#{eoutvar} = SafeBuffer.new"]
        compiler.post_cmd = ["#{eoutvar}.force_encoding(__ENCODING__)"]
      end
    end

    class ERBTemplate < Tilt::ERBTemplate
      def render(*args)
        app       = args.first
        app_class = app.class
        @is_padrino_app = (defined?(Padrino::Application) && app.kind_of?(Padrino::Application)) || 
                          (app_class.respond_to?(:erb) && app_class.erb[:safe_buffer])
        super
      end

      def prepare
        @outvar = options[:outvar] || self.class.default_output_variable
        options[:trim] = '<>' if !(options[:trim] == false) && (options[:trim].nil? || options[:trim] == true)
        @engine = SafeERB.new(data, options[:safe], options[:trim], @outvar)
      end

      def precompiled_preamble(locals)
        original = super
        return original unless @is_padrino_app
        "__in_erb_template = true\n" << original
      end
    end
  end
end

Tilt.prefer(Padrino::Rendering::ERBTemplate, :erb)

Padrino::Rendering.engine_configurations[:erb] = {
  :safe_buffer => true
}
