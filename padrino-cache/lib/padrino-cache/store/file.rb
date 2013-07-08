module Padrino
  module Cache
    module Store
      ##
      # File based Cache Store
      #
      class File < Base
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
        #   # you can provide a marshal parser (to store ruby objects)
        #   set :cache, Padrino::Cache::Store::File.new("path/to", :parser => :marshal)
        #
        # @api public
        def initialize(root, options={})
          @root = root
          super(options)
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
            read_method = ::File.respond_to?(:binread) ? :binread : :read
            contents    = ::File.send(read_method, path_for_key(key))
            expiry, body = contents.split("\n", 2)
            if now_before? expiry
              parser.decode(body) if body
            else # expire the key
              delete(key)
              nil
            end
          else # key can't be found
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
          value = parser.encode(value) if value
          ::File.open(path_for_key(key), 'wb') { |f| f << get_expiry(opts).to_s << "\n" << value } if value
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
