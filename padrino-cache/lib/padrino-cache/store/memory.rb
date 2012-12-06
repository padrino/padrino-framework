module Padrino
  module Cache
    module Store
      ##
      # Memory Cache Store
      #
      class Memory
        ##
        # Initialize Memory Store with memory size
        #
        # @param [Integer] size
        #   Size of memory cache
        #
        # @example
        #   Padrino.cache = Padrino::Cache::Store::Memory.new(10000)
        #   # or from your app
        #   set :cache, Padrino::Cache::Store::Memory.new(10000)
        #
        # @api public
        def initialize(size = 5000)
          @size, @entries, @index = size, [], {}
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
          if @index.key?(key) and value = @index[key]
            expires_in, body = value
            if expires_in == -1 or Time.new.to_i < expires_in
              set(key, body, :expires_in => expires_in)
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
        # @api public
        def set(key, value, opts = nil)
          delete(key) if @index.key?(key)
          if opts && opts[:expires_in]
            expires_in = opts[:expires_in].to_i
            expires_in = Time.new.to_i + expires_in if expires_in < EXPIRES_EDGE
          else
            expires_in = -1
          end
          @entries.push(key)
          @index[key] = [expires_in, value]

          while @entries.size > @size
            delete(@entries.shift)
          end
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
          @index.delete(key)
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
          @index = Hash.new
        end
      end # Memory
    end # Store
  end # Cache
end # Padrino
