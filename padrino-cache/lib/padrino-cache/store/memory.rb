module Padrino
  module Cache
    module Store
      ##
      # Memory Cache Store
      #
      class Memory < Base
        ##
        # Initialize Memory Store with memory size.
        #
        # @param [Integer] size
        #   Size of memory cache.
        #
        # @example
        #   Padrino.cache = Padrino::Cache::Store::Memory.new(10000)
        #   # or from your app
        #   set :cache, Padrino::Cache::Store::Memory.new(10000)
        #
        def initialize(size = 5000, options={})
          @size, @entries, @index = size, [], {}
          super(options)
        end

        ##
        # Return the value for the given key.
        #
        # @param [String] key
        #   cache key to retrieve value
        #
        # @example
        #   MyApp.cache.get('records')
        #
        def get(key)
          if @index.key?(key) and value = @index[key]
            expiry, body = value
            if now_before? expiry
              body
            else
              delete(key)
              nil
            end
          else
            nil
          end
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
        def set(key, value, opts = nil)
          delete(key)
          @entries.push(key)
          @index[key] = [get_expiry(opts), value]
          while @entries.size > @size
            delete(@entries.shift)
          end
        end

        ##
        # Delete the value for a given key.
        #
        # @param [String] key
        #   cache key
        #
        # @example
        #   MyApp.cache.delete('records')
        #
        def delete(key)
          @index.delete(key)
        end

        ##
        # Reinitialize your cache.
        #
        # @example
        #   MyApp.cache.flush
        #   MyApp.cache.get('records') # => nil
        #
        def flush
          @index = Hash.new
        end
      end
    end
  end
end
