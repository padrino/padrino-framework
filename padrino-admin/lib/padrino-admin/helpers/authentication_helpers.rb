require_relative '../auth'

module Padrino
  module Admin
    module Helpers
      ##
      # Common helpers used for authorization within an application, the ones of Padrino::Auth
      # plus the project modules of the admin.
      #
      module AuthenticationHelpers
        include Padrino::Auth::Helpers

        ##
        # Returns project modules for the current account.
        #
        def project_modules
          access_control.project_modules(current_account)
        end

        private

        # Defined as a method rather than an alias, so an app that reopens this module to override
        # +admin_model_obj+ is not bypassed.
        def account_model_obj
          admin_model_obj
        end

        def admin_model_obj
          @_admin_model_obj ||= Padrino::Inflections.constantize(settings.admin_model)
        rescue NameError => e
          raise unless Padrino::Auth.missing_constant?(e, settings.admin_model)

          raise Padrino::Admin::AccessControlError, "You must define an #{settings.admin_model} Model"
        end
      end
    end
  end
end
