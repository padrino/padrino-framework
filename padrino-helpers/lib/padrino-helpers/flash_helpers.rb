module Padrino
  module Helpers
    module FlashHelpers
      def self.included(base)
        base.before { @_flash, session[:_flash] = session[:_flash], nil if settings.sessions? && session[:_flash] }
        base.alias_method_chain :redirect, :flash
      end

      def flash
        @_flash ||= {}
      end

      def redirect_with_flash(uri, *args)
        session[:_flash] = flash if settings.sessions? && flash.present?
        redirect_without_flash(uri, *args)
      end
    end # FlashHelpers
  end # Helpers
end # Padrino
