require 'securerandom'

module Padrino
  module Helpers
    module FormHelpers
      ##
      # Helpers to generate form security tags for csrf protection.
      #
      module Security
        ##
        # Constructs a hidden field containing a CSRF token.
        #
        # @param [String] token
        #   The token to use. Will be read from the session by default.
        #
        # @return [String] The hidden field with CSRF token as value.
        #
        # @example
        #   csrf_token_field
        #
        def csrf_token_field
          hidden_field_tag csrf_param, :value => csrf_token
        end

        ##
        # Constructs meta tags `csrf-param` and `csrf-token` with the name of the
        # cross-site request forgery protection parameter and token, respectively.
        #
        # @return [String] The meta tags with the CSRF token and the param your app expects it in.
        #
        # @example
        #   csrf_meta_tags
        #
        def csrf_meta_tags
          if is_protected_from_csrf?
            meta_tag(csrf_param, :name => 'csrf-param') <<
            meta_tag(csrf_token, :name => 'csrf-token')
          end
        end

        protected

        ##
        # Returns whether the application is being protected from CSRF. Defaults to true.
        #
        def is_protected_from_csrf?
          defined?(settings) ? settings.protect_from_csrf : true
        end

        ##
        # Returns the current CSRF token (based on the session). If it doesn't exist,
        # it will create one and assign it to the session's `csrf` key.
        #
        def csrf_token
          session[:csrf] ||= SecureRandom.hex(32) if defined?(session)
        end

        ##
        # Returns the param/field name in which your CSRF token should be expected by your
        # controllers. Defaults to `authenticity_token`.
        #
        # Set this in your application with `set :csrf_param, :something_else`.
        #
        def csrf_param
          defined?(settings) && settings.respond_to?(:csrf_param) ? settings.csrf_param : :authenticity_token
        end
      end
    end
  end
end
