module Padrino
  module Cache
    module Store
      ##
      # MongoDB Cache Store
      #
      class Mongo
        ##
        # Initialize Mongo store with client connection and optional username and password.
        #
        # ==== Examples
        #   Padrino.cache = Padrino::Cache::Store::Mongo.new(::Mongo::Connection.new('127.0.0.1', 27017).db('padrino'), :username => 'username', :password => 'password', :size => 256, :collection => 'cache')
        #   # or from your app
        #   set :cache, Padrino::Cache::Store::Mongo.new(::Mongo::Connection.new('127.0.0.1', 27017).db('padrino'), :username => 'username', :password => 'password', :size => 256, :collection => 'cache')
        #
        def initialize(client, opts=nil)
          if opts && opts[:username]
            client.authenticate(opts[:username], opts[:password], true)
          end
          @backend = client.collection( (opts && opts[:collection])? opts[:collection] : 'cache' )
        end

        ##
        # Return the a value for the given key
        #
        # ==== Examples
        #   # with MyApp.cache.set('records', records)
        #   MyApp.cache.get('records')
        #
        def get(key)
          doc = @backend.find_one(:_id => key, :expires_in => {'$gt' => Time.now.utc})
          return nil if doc.nil?
          Marshal.load(doc['value'].to_s) if doc['value'].present?
        end

        ##
        # Set or update the value for a given key and optionally with an expire time
        # Default expiry is Time.now + 86400s.
        #
        # ==== Examples
        #   MyApp.cache.set('records', records)
        #   MyApp.cache.set('records', records, :expires_in => 30) # => 30 seconds
        #
        def set(key, value, opts = nil)
          key = key.to_s
          value = BSON::Binary.new(Marshal.dump(value)) if value
          if opts && opts[:expires_in]
            expires_in = opts[:expires_in].to_i
            expires_in = Time.now.utc + expires_in if expires_in < EXPIRES_EDGE
          else
            expires_in = Time.now.utc + EXPIRES_EDGE
          end
          @backend.update(
            {:_id => key},
            {:_id => key, :value => value, :expires_in => expires_in },
            {:upsert => true})
        end

        ##
        # Delete the value for a given key
        #
        # ==== Examples
        #   # with: MyApp.cache.set('records', records)
        #   MyApp.cache.delete('records')
        #
        def delete(key)
          @backend.remove({:_id => key})
        end

        ##
        # Reinitialize your cache
        #
        # ==== Examples
        #   # with: MyApp.cache.set('records', records)
        #   MyApp.cache.flush
        #   MyApp.cache.get('records') # => nil
        #
        def flush
          @backend.drop
        end
      end # Mongo
    end # Store
  end # Cache
end # Padrino
