module Padrino
  module Admin
    ##
    # Contains all admin related helpers.
    #
    module Helpers
      ##
      # Admin helpers
      #
      module ViewHelpers
        ##
        # Icon's Bootstrap helper
        #
        # @param [Symbol] icon
        #  The specified icon type
        #
        # @param [Symbol] tag
        #   The HTML tag.
        #
        # @return [String] html tag with prepend icon
        #
        # @example
        #   tag_icon(:edit, :list)
        #
        def tag_icon(icon, tag = nil)
          content = content_tag(:i, '', :class=> "icon-#{icon.to_s}")
          content << " #{tag.to_s}"
        end
      end # ViewHelpers
    end # Helpers
  end # Admin
end # Padrino
