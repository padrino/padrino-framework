module Padrino
  module Cache
    module Store
      ##
      # Moneta Cache Store
      #
      class Moneta
        ##
        # Initialize Moneta Store
        #
        # @example
        #   Padrino.cache = Padrino::Cache::Store::Moneta.new(:Memory, :expires => true)
        #   # or using the Moneta builder
        #   Padrino.cache = Padrino::Cache::Store::Moneta.new do
        #     use :Expires
        #     adapter :Memory
        #   end
        #   # or from your app
        #   set :cache, Padrino::Cache::Store::Moneta.new(:Memory)
        #
        # @api public
        def initialize(*args, &block)
          @backend = block ? ::Moneta.build(&block) : ::Moneta.new(*args)
        end

        ##
        # Return the a value for the given key
        #
        # @param [String] key
        #   cache key to retrieve value
        #
        # @example
        #   # with MyApp.cache.set('records', records)
        #   MyApp.cache.get('records')
        #
        # @api public
        def get(key)
          @backend[key]
        end

        ##
        # Set the value for a given key and optionally with an expire time.
        # Default expiry is 86400.
        #
        # @param [String] key
        #   cache key
        # @param value
        #   value of cache key
        #
        # @example
        #   MyApp.cache.set('records', records)
        #   MyApp.cache.set('records', records, :expires_in => 30) # => 30 seconds
        #
        # @api public
        def set(key, value, opts = nil)
          opts ||= {}
          opts[:expires] = opts.delete(:expires_in).to_i if opts[:expires_in]
          @backend.store(key, value, opts)
        end

        ##
        # Delete the value for a given key
        #
        # @param [String] key
        #   cache key
        #
        # @example
        #   # with: MyApp.cache.set('records', records)
        #   MyApp.cache.delete('records')
        #
        # @api public
        def delete(key)
          @backend.delete(key)
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
          @backend.clear
        end
      end # Moneta
    end # Store
  end # Cache
end # Padrino
