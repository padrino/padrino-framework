module Haml
  module Helpers
    include XssMods
    include ActionViewExtensions
  end

  module Util
    def self.rails_xss_safe?
      true
    end
  end
end

module Padrino
  module Rendering
    class HamlTemplate < Tilt::HamlTemplate
      include SafeTemplate
    end
  end
end

Tilt.prefer(Padrino::Rendering::HamlTemplate, :haml)

Padrino::Rendering.engine_configurations[:haml] = {
  :escape_html => true,
}
