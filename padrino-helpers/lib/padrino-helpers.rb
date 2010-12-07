require 'padrino-core/support_lite' unless defined?(SupportLite)
require 'cgi'
require 'i18n'

FileSet.glob_require('padrino-helpers/**/*.rb', __FILE__)

# Load our locales
I18n.load_path += Dir["#{File.dirname(__FILE__)}/padrino-helpers/locale/*.yml"]

module Padrino
  ##
  # This component provides a great deal of view helpers related to html markup generation.
  # There are helpers for generating tags, forms, links, images, and more.
  # Most of the basic methods should be very familiar to anyone who has used rails view helpers.
  #
  module Helpers
    ##
    # Register these helpers:
    #
    #   Padrino::Helpers::OutputHelpers
    #   Padrino::Helpers::TagHelpers
    #   Padrino::Helpers::AssetTagHelpers
    #   Padrino::Helpers::FormHelpers
    #   Padrino::Helpers::FormatHelpers
    #   Padrino::Helpers::RenderHelpers
    #   Padrino::Helpers::NumberHelpers
    #
    # for Padrino::Application
    #
    class << self
      def registered(app)
        app.set :default_builder, 'StandardFormBuilder'
        app.helpers Padrino::Helpers::DomHelpers
        app.helpers Padrino::Helpers::OutputHelpers
        app.helpers Padrino::Helpers::TagHelpers
        app.helpers Padrino::Helpers::AssetTagHelpers
        app.helpers Padrino::Helpers::FormHelpers
        app.helpers Padrino::Helpers::FormatHelpers
        app.helpers Padrino::Helpers::RenderHelpers
        app.helpers Padrino::Helpers::NumberHelpers
        app.helpers Padrino::Helpers::TranslationHelpers
      end
      alias :included :registered
    end
  end # Helpers
end # Padrino
