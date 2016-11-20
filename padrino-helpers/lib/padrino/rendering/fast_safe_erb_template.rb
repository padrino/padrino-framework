require 'tilt/template'
require 'padrino/rendering/fast_safe_erb_engine'

module Padrino
  module Rendering
    class FastSafeErbTemplate < Tilt::Template
      def prepare; end

      def precompiled_template(locals)
        FastSafeErbEngine.new(data).src
      end
    end
  end
end

Tilt.register(Padrino::Rendering::FastSafeErbTemplate, :erb)
