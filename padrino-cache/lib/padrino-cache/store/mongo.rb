module Padrino
  module Cache
    module Store
      ##
      # MongoDB Cache Store
      #
      class Mongo < Base
        ##
        # Initialize Mongo store with client connection and optional username and password.
        #
        # @param client
        #   Instance of Mongo connection
        # @param [Hash] opts
        #   optiosn to pass into Mongo connection
        #
        # @example
        #   Padrino.cache = Padrino::Cache::Store::Mongo.new(::Mongo::Connection.new('127.0.0.1', 27017).db('padrino'), :username => 'username', :password => 'password', :size => 64, :max => 100, :collection => 'cache')
        #   # or from your app
        #   set :cache, Padrino::Cache::Store::Mongo.new(::Mongo::Connection.new('127.0.0.1', 27017).db('padrino'), :username => 'username', :password => 'password', :size => 64, :max => 100, :collection => 'cache')
        #   # you can provide a marshal parser (to store ruby objects)
        #   set :cache, Padrino::Cache::Store::Mongo.new(::Mongo::Connection.new('127.0.0.1', 27017).db('padrino'), :parser => :marshal)
        #
        # @api public
        def initialize(client, options={})
          @client = client
          @options = {
            :capped => true,
            :collection => 'cache',
            :size => 64,
            :max => 100
          }.merge(options)

          if @options[:username] && @options[:password]
            @client.authenticate(@options[:username], @options[:password], true)
          end
          @backend = get_collection
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
        def get(key)
          doc = @backend.find_one( :_id => key, '$or' => [ { :expires_at => { '$gt' => Time.now.to_i } }, { :expires_at => -1 } ] )
          return nil if doc.nil?
          expiry = doc['expires_at']
          if now_before? expiry
            parser.decode(doc['value'].to_s)
          else
            delete(key)
            nil
          end
        end

        ##
        # Set or update the value for a given key and optionally with an expire time
        # Default expiry is Time.now + 86400s.
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
          key = key.to_s
          value = BSON::Binary.new(parser.encode(value)) if value
          @backend.update(
            {:_id => key},
            {:_id => key, :value => value, :expires_at => get_expiry(opts) },
            {:upsert => true}
          )
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
          if not @options[:capped]
            @backend.remove({:_id => key})
          else
            # Mongo will overwrite it with a simple object {_id: new ObjectId()}
            @backend.update({:_id => key},{},{:upsert => true})
          end
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
          @backend.drop
          @backend = get_collection
        end

        private

        # @api private
        def get_collection
          if @client.collection_names.include?(@options[:collection]) or !@options[:capped]
            @client.collection @options[:collection]
          else
            @client.create_collection(@options[:collection], { :capped => @options[:capped],
                                                               :size => @options[:size]*1024**2,
                                                               :max => @options[:max] })
          end
        end
      end # Mongo
    end # Store
  end # Cache
end # Padrino
