module Padrino
  module Cache
    module Store
      ##
      # File based Cache Store
      #
      class File
        ##
        # Initialize File store with File root
        #
        # @param [String] root
        #   path to cache file
        #
        # @example
        #   Padrino.cache = Padrino::Cache::Store::File.new("path/to")
        #   # or from your app
        #   set :cache, Padrino::Cache::Store::File.new("path/to")
        #
        # @api public
        def initialize(root)
          @root = root
        end

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
          init
          if ::File.exist?(path_for_key(key))
            contents = ::File.read(path_for_key(key))
            expires_in, body = contents.split("\n", 2)
            expires_in = expires_in.to_i
            if expires_in == -1 or Time.new.to_i < expires_in
              Marshal.load(body) if body
            else
              delete(key)
              nil
            end
          else
            nil
          end
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
        #   MyApp.cache.set('records', records, :expires_in => 30) # => 30 seconds
        #
        # @api public
        def set(key, value, opts = nil)
          init
          if opts && opts[:expires_in]
            expires_in = opts[:expires_in].to_i
            expires_in = Time.new.to_i + expires_in if expires_in < EXPIRES_EDGE
          else
            expires_in = -1
          end
          value = Marshal.dump(value) if value
          ::File.open(path_for_key(key), 'w') { |f| f << expires_in.to_s << "\n" << value } if value
        end

        ##
        # Delete the value for a given key
        #
        # @param [String] key
        #   cache key
        # @param value
        #   value of cache key
        #
        # @example
        #   # with: MyApp.cache.set('records', records)
        #   MyApp.cache.delete('records')
        #
        # @api public
        def delete(key)
          init
          Array(key).each { |k| FileUtils.rm_rf(path_for_key(k)) }
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
          FileUtils.rm_rf(@root)
        end

        private

        # @api private
        def path_for_key(key)
          ::File.join(@root, Rack::Utils.escape(key.to_s))
        end

        # @api private
        def init
          FileUtils.mkdir_p(@root) unless ::File.exist?(@root)
        end
      end # File
    end # Store
  end # Cache
end # Padrino
