module Padrino
  module Admin
    ##
    # Contains all admin related helpers.
    #
    module Helpers
      ##
      # i18n translation helpers for admin to retrieve words based on locale.
      #
      module ViewHelpers
        ##
        # Translates a given word for padrino admin
        #
        # @param [String] word
        #  The specified word to admin translate.
        # @param [String] default
        #   The default fallback if no word is available for the locale.
        #
        # @return [String] The translated word for the current locale.
        #
        # @example
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
        # Translates attribute name for the given model.
        #
        # @param [Symbol] model
        #  The model name for the translation.
        # @param [Symbol] attribute
        #  The attribute name in the model to translate.
        #
        # @return [String] The translated attribute name for the current locale.
        #
        # @example
        #   # => t("models.account.email", :default => "Email")
        #   mat(:account, :email)
        #
        def model_attribute_translate(model, attribute)
          t("models.#{model}.attributes.#{attribute}", :default => attribute.to_s.humanize)
        end
        alias :mat :model_attribute_translate

        ##
        # Translates model name
        #
        # @param [Symbol] attribute
        #  The attribute name in the model to translate.
        #
        # @return [String] The translated model name for the current locale.
        #
        # @example
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
