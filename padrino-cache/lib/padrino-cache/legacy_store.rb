module Padrino
  module Cache
    class LegacyStore < Moneta::Proxy
      ##
      # Return the a value for the given key
      #
      # @param [String] key
      #   cache key
      #
      # @example
      #   # with MyApp.cache.set('records', records)
      #   MyApp.cache.get('records')
      #
      # @api public
      def get(key)
        warn 'cache.get(key) has been deprecated in favour of cache[key]'
        self[key]
      end

      ##
      # Set the value for a given key and optionally with an expire time
      # Default expiry time is 86400.
      #
      # @param [String] key
      #   cache key
      # @param value
      #   value of cache key
      #
      # @example
      #   MyApp.cache.set('records', records)
      #   MyApp.cache.set('records', records, :expires => 30) # => 30 seconds
      #
      # @api public
      def set(key, value, opts = nil)
        warn opts ? 'cache.set(key, value, opts) has been deprecated in favour of cache.store(key, value, opts)' :
          'cache.set(key, value) has been deprecated in favour of cache[key] = value'
        store(key, value, opts || {})
      end

      ##
      # Reinitialize your cache
      #
      # @example
      #   # with: MyApp.cache.set('records', records)
      #   MyApp.cache.flush
      #   MyApp.cache.get('records') # => nil
      #
      # @api public
      def flush
        warn 'cache.flush has been deprecated in favour of cache.clear'
        clear
      end

      # (see Moneta::Proxy#store)
      def store(key, value, options = {})
        if options[:expires_in]
          warn 'Option :expires_in has been deprecated in favour of :expires'
          options[:expires] = options.delete(:expires_in).to_i
        end
        if options[:expires] && options[:expires] < 0
          warn 'The use of negative expiration values is deprecated, use :expires => false'
          options[:expires] = false
        end
        adapter.store(key, value, options)
      end
    end
  end
end
