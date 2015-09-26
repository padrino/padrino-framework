module Padrino
  module Cache
    module Helpers
      ##
      # Whereas page-level caching, described in the first section of this document, works by
      # grabbing the entire output of a route, fragment caching gives the developer fine-grained
      # control of what gets cached. This type of caching occurs at whatever level you choose.
      #
      # Possible uses for fragment caching might include:
      #
      # - a 'feed' of some items on a page
      # - output fetched (by proxy) from an API on a third-party site
      # - parts of your page which are largely static/do not need re-rendering every request
      # - any output which is expensive to render
      #
      module Fragment
        include Padrino::Helpers::OutputHelpers

        ##
        # This helper is used anywhere in your application you would like to associate a fragment
        # to be cached. It can be used in within a route:
        #
        # @param [String] key
        #   cache key
        # @param [Hash] opts
        #   cache options, e.g :expires
        # @param [Proc]
        #   Execution result to store in the cache
        #
        # @example
        #   # Caching a fragment
        #   class MyTweets < Padrino::Application
        #     enable :caching          # turns on caching mechanism
        #
        #     controller '/tweets' do
        #       get :feed, :map => '/:username' do
        #         username = params[:username]
        #
        #         @feed = cache( "feed_for_#{username}", :expires => 3 ) do
        #           @tweets = Tweet.all( :username => username )
        #           render 'partials/feedcontent'
        #         end
        #
        #         # Below outputs @feed somewhere in its markup.
        #         render 'feeds/show'
        #       end
        #     end
        #   end
        #
        # @api public
        def cache(key, opts = {}, &block)
          if settings.caching?
            began_at = Time.now
            if settings.cache.key?(key.to_s)
              value = settings.cache[key.to_s]
              logger.debug "GET Fragment", began_at, key.to_s if defined?(logger)
              concat_content(value.to_s.html_safe)
            else
              value = capture_html(&block)
              settings.cache.store(key.to_s, value, opts)
              logger.debug "SET Fragment", began_at, key.to_s if defined?(logger)
              concat_content(value)
            end
          else
            value = capture_html(&block)
            concat_content(value)
          end
        end
      end
    end
  end
end
