module Padrino
  module Helpers
    module DomHelpers 
      ##
      # Create DOM id from given object. You can also specify optional prefix.
      #
      # ==== Examples
      # 
      #   @user = User.new
      #   dom_id(@user, "new")  # => "new_user"
      #
      #   @user.save
      #   @user.id              # => 10
      #   dom_id(@user)         # => user_10
      #   dom_id(@user, "edit") # => edit_user_10
      #   
      def dom_id(object, prefix=nil)
        chain = []
        chain << prefix if prefix
        chain << object.class.to_s.underscore.gsub("/", "_")
        chain << object.id if object.respond_to?('id') && object.id
        chain.join('_')
      end
      
      ##
      # Create DOM class name from given object. You can also specify optional 
      # prefix.
      # 
      # ==== Examples
      #
      #   @user = User.new
      #   dom_class(@user, "new") # => new_user
      #   dom_class(@user)        # => user
      #
      #   @user.save
      #   @user.id                # => 11
      #   dom_class(@user)        # => user
      def dom_class(object, prefix=nil)
        chain = []
        chain << prefix if prefix
        chain << object.class.to_s.underscore.gsub("/", "_")
        chain.join('_')
      end
    end # DomHelpers
  end # Helpers
end # Padrino
