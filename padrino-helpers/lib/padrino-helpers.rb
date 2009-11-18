require 'padrino-core/support_lite'
Dir[File.dirname(__FILE__) + '/padrino-helpers/**/*.rb'].each {|file| require file }

module Padrino
  module Helpers
    def self.registered(app)
      app.set :default_builder, 'StandardFormBuilder'
      app.helpers Padrino::Helpers::OutputHelpers
      app.helpers Padrino::Helpers::TagHelpers
      app.helpers Padrino::Helpers::AssetTagHelpers
      app.helpers Padrino::Helpers::FormHelpers
      app.helpers Padrino::Helpers::FormatHelpers
      app.helpers Padrino::Helpers::RenderHelpers
    end
  end
end