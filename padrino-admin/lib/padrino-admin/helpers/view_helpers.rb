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
        #   t_admin(:profile)
        #
        #   # => t("padrino.admin.profile",  :default => "My Profile")
        #   t_admin(:profile, "My Profile")
        #
        def padrino_admin_translate(word, default=nil)
          t("padrino.admin.#{word}", :default => (default || word.to_s.humanize))
        end
        alias :t_admin :padrino_admin_translate
        alias :pat :t_admin

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
        #   # => t("models.account.attributes.email", :default => "Email")
        #   mat(:account, :email)
        #
        def model_attribute_translate(model, attribute)
          t("models.#{model}.attributes.#{attribute}", :default => attribute.to_s.humanize)
        end
        alias :t_attr :model_attribute_translate
        alias :mat :t_attr

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
        #   t_model(:account)
        #
        def model_translate(model)
          t("models.#{model}.name", :default => model.to_s.humanize)
        end
        alias :t_model :model_translate
        alias :mt :t_model

        ##
        # Replace true or false with relative image
        #
        def tof(status)
          status ? (image_tag "buttons/tick.png") : (image_tag "buttons/cross.png")
        end

        ##
        # Icon's Bootstrap helper
        #
        # @param [String] icon
        #  The specified icon type
        #
        # @param [Symbol] tag
        #   The HTML tag.
        #
        # @return [String] html tag with prepend icon
        #
        # @example
        #   ti( "edit", t_admin(:list))
        #
        def tag_icon(icon,tag)
          content = content_tag(:i, "", :class=> "icon-#{icon}")
          content << tag
        end
        alias :t_icon :tag_icon
        alias :ti :tag_icon

      end # ViewHelpers
    end # Helpers
  end # Admin
end # Padrino
