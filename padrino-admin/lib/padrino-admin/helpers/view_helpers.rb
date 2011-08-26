module Padrino
  module Admin
    module Helpers
      module ViewHelpers
        ##
        # Translate a given word for padrino admin
        #
        # ==== Examples
        #
        #   # => t("padrino.admin.profile",  :default => "Profile")
        #   pat(:profile)
        #
        #   # => t("padrino.admin.profile",  :default => "My Profile")
        #   pat(:profile, "My Profile")
        #
        def padrino_admin_translate(word, default=nil)
          t("padrino.admin.#{word}", :default => (default || word.to_s.humanize))
        end
        alias :pat :padrino_admin_translate

        ##
        # Translate attribute name for the given model
        #
        # ==== Examples
        #
        #   # => t("models.account.email", :default => "Email")
        #   mat(:account, :email)
        #
        def model_attribute_translate(model, attribute)
          t("models.#{model}.attributes.#{attribute}", :default => attribute.to_s.humanize)
        end
        alias :mat :model_attribute_translate

        ##
        # Translate model name
        #
        # ==== Examples
        #
        #   # => t("models.account.name", :default => "Account")
        #   mt(:account)
        #
        def model_translate(model)
          t("models.#{model}.name", :default => model.to_s.humanize)
        end
        alias :mt :model_translate
      end # ViewHelpers
    end # Helpers
  end # Admin
end # Padrino
