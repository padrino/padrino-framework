begin
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
  # Haml 6+ does not have these modules
end

module Padrino
  module Rendering
    if defined?(Haml::VERSION) && Gem::Version.new(Haml::VERSION) >= Gem::Version.new('6')
      class HamlOutputBuffer < Temple::Generators::StringBuffer
        define_options buffer_class: 'SafeBuffer'

        def call(exp)
          [preamble, compile(exp), postamble].flatten.compact.join('; '.freeze)
        end

        def create_buffer
          "__in_hamlit_template = true; #{buffer} = #{options[:buffer_class]}.new"
        end

        def concat(str)
          "#{buffer}.safe_concat((#{str}))"
        end
      end
    end

    class HamlTemplate < Tilt::HamlTemplate
      include SafeTemplate
    end
  end
end

Tilt.prefer(Padrino::Rendering::HamlTemplate, :haml)

Padrino::Rendering.engine_configurations[:haml] =
  if defined?(Haml::VERSION) && Gem::Version.new(Haml::VERSION) >= Gem::Version.new('6')
    {
      generator: Padrino::Rendering::HamlOutputBuffer,
      buffer: '@_out_buf',
      use_html_safe: true,
      disable_capture: true
    }
  else
    { escape_html: true }
  end
