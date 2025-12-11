begin
  using_modern_haml = false
  require 'haml/helpers/xss_mods'
  require 'haml/helpers/action_view_extensions'

  module Haml
    Helpers.include(Helpers::XssMods)
    Helpers.include(Helpers::ActionViewExtensions)

    def Util.rails_xss_safe?
      true
    end
  end
rescue LoadError
  using_modern_haml = true
end

module Padrino
  module Rendering
    class HamlTemplate < Tilt::HamlTemplate
      include SafeTemplate
    end
  end
end

Tilt.prefer(Padrino::Rendering::HamlTemplate, :haml)

Padrino::Rendering.engine_configurations[:haml] =
  if using_modern_haml
    {
      buffer_class: 'SafeBuffer.new',
      use_html_safe: true,
      disable_capture: true
    }
  else
    { escape_html: true }
  end
