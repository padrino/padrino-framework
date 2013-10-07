begin
  require 'slim'

  if defined? Padrino::Rendering
    Padrino::Rendering.engine_configurations[:slim] =
      {:generator => Temple::Generators::RailsOutputBuffer,
      :buffer => "@_out_buf", :use_html_safe => true}

    class Slim::Template
      include Padrino::Rendering::SafeTemplate

      def precompiled_preamble(locals)
        result = locals.map do |k,v|
          if k.to_s =~ /\A[a-z_][a-zA-Z_0-9]*\z/
            "#{k} = locals[#{k.inspect}]"
          else
            raise "invalid locals key: #{k.inspect} (keys must be variable names)"
          end
        end.join("\n")
        "#{result}; __in_erb_template = true;"
      end
    end
  end
rescue LoadError
end
