module Padrino
  class JamlTemplate < Tilt::ERBTemplate
    def evaluate(scope, locals, &block)
      output = super(scope, locals, &block)
      Padrino::ExtJs::Config.load(output).to_json
    end
  end
  Tilt.register 'jml', JamlTemplate
  Tilt.register 'jaml', JamlTemplate
end

# For compatibility with sinatra 0.9.4
if Sinatra::Templates.private_method_defined?(:render_erb)
  Sinatra::Templates.class_eval do
    def render_jml(template, data, options, locals, &block)
      if block_given?
        template = Padrino::JamlTemplate.new(nil, options, &block)
      else
        template = Padrino::JamlTemplate.new(nil, options) { data }
      end
      template.render(self, locals)
    end
    alias :render_jaml :render_jml
  end
end