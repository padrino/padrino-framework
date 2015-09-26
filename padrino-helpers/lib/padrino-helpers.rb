require 'padrino-support'
require 'i18n'
require 'enumerator'
require 'active_support/time_with_zone'               # next extension depends on this
require 'active_support/core_ext/string/conversions'  # to_date
require 'active_support/option_merger'                # with_options
require 'active_support/core_ext/object/with_options' # with_options
require 'active_support/inflector'                    # humanize
require 'active_support/core_ext/hash/except'         # Hash#except
require 'padrino/rendering'

FileSet.glob_require('padrino-helpers/**/*.rb', __FILE__)
I18n.load_path += Dir["#{File.dirname(__FILE__)}/padrino-helpers/locale/*.yml"]
I18n.enforce_available_locales = true

module Padrino
  ##
  # This component provides a variety of view helpers related to html markup generation.
  # There are helpers for generating tags, forms, links, images, and more.
  # Most of the basic methods should be very familiar to anyone who has used rails view helpers.
  #
  module Helpers
    class << self
      ##
      # Registers these helpers into your application:
      #
      #   Padrino::Helpers::OutputHelpers
      #   Padrino::Helpers::TagHelpers
      #   Padrino::Helpers::AssetTagHelpers
      #   Padrino::Helpers::FormHelpers
      #   Padrino::Helpers::FormatHelpers
      #   Padrino::Helpers::RenderHelpers
      #   Padrino::Helpers::NumberHelpers
      #
      # @param [Sinatra::Application] app
      #   The specified Padrino application.
      #
      # @example Register the helper module
      #   require 'padrino-helpers'
      #   class Padrino::Application
      #     register Padrino::Helpers
      #   end
      #
      def registered(app)
        app.register Padrino::Rendering
        app.set :default_builder, 'StandardFormBuilder'
        included(app)
      end

      def included(base)
        base.send :include, Padrino::Helpers::OutputHelpers
        base.send :include, Padrino::Helpers::TagHelpers
        base.send :include, Padrino::Helpers::AssetTagHelpers
        base.send :include, Padrino::Helpers::FormHelpers
        base.send :include, Padrino::Helpers::FormatHelpers
        base.send :include, Padrino::Helpers::RenderHelpers
        base.send :include, Padrino::Helpers::NumberHelpers
        base.send :include, Padrino::Helpers::TranslationHelpers
      end
    end
  end
end
