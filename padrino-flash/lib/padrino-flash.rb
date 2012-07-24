# encoding: utf-8
require 'padrino-core'
require 'padrino-helpers'

FileSet.glob_require('padrino-flash/**/*.rb', __FILE__)

module Padrino
  module Flash
    class << self
      # @private
      def registered(app)
        app.helpers Helpers
        app.enable :sessions
        app.enable :flash

        app.after do
          session[:_flash] = @_flash.next if @_flash && app.flash?
        end
      end
    end # self
  end # Flash
end # Padrino