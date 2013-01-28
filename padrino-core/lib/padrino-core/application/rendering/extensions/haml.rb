begin
  require 'haml'
  require 'haml/helpers/xss_mods'

  module Haml
    module Helpers
      include XssMods
    end

    module Util
      undef :rails_xss_safe? if defined? rails_xss_safe?
      def rails_xss_safe?; true; end
    end
  end

  if defined? Padrino::Rendering
    Padrino::Rendering.engine_configurations[:haml] = 
      {:escape_html => true}
  end
rescue LoadError
end
