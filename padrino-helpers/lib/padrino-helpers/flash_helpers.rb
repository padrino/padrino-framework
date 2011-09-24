module Padrino
  module Helpers
    module FlashHelpers
      def self.included(base)
        base.before { @_flash, session[:_flash] = session[:_flash], nil if settings.sessions? && session[:_flash]; true }
      end

      def flash
        @_flash ||= {}
      end

      def redirect(uri, *args)
        session[:_flash] = flash if settings.sessions? && flash.present?
        super(uri, *args)
      end
    end # FlashHelpers
  end # Helpers
end # Padrino
