---
date: 2011-03-10
author: Nathan
email: nesquena@gmail.com
title: Padrino Cache
---

 

## Overview

This component enables caching of an application’s response contents on both page- and fragment-levels.
 Output cached in this manner is persisted, until it expires or is actively expired, in a configurable store of your choosing. Several common caching stores are supported out of the box.

 

## Caching Quickstart

Padrino-cache can reduce the processing load on your site very effectively with minimal configuration.

By default, the component caches pages in a file store at `tmp/cache` within your project root. Entries in this store correspond directly to the request issued to your server. In other words, responses are cached based on request URL, with one cache entry per URL.

This behavior is referred to as “page-level caching.” If this strategy meets your needs, you can enable it very easily:

    # Basic, page-level caching
    class SimpleApp < Padrino::Application
      register Padrino::Cache
      enable :caching

      get '/foo', :cache => true do
        expires_in 30 # expire cached version at least every 30 seconds
        'Hello world'
      end
    end

By default the “cache\_key” in these instances is the `request.path_info` and the query string is not considered. You can also provide a custom `cache_key` for any route:

    class SimpleApp < Padrino::Application
      register Padrino::Cache
      enable :caching

      get '/post/:id', :cache => true do
        @post = Post.find(params[:id])
        cache_key :my_name
      end
    end

In this way you can manually expire cache with CachedApp.cache.delete(:my\_name) for example from the Post model after an update.

You can also cache on a controller-wide basis:

    # Controller-wide caching example
    class SimpleApp < Padrino::Application
      register Padrino::Cache
      enable :caching

      get '/' do
        'Hello world'
      end

      # Requests to routes within '/admin'
      controller '/admin', :cache => true do
        expires_in 60

        get '/foo' do
          'Url is /admin/foo'
        end

        get '/bar' do
          'Url is /admin/bar'
        end
      
        post '/baz' do # We cache only GET and HEAD request
          'This will not be cached'
        end
      end
    end

If you specify `:cache => true` but do not invoke `expires_in`, the response will be cached indefinitely. Most of the time, you will want to specify the expiry of a cache entry by `expires_in`. Even a relatively low value—1 or 2 seconds—can greatly increase application efficiency, especially when enabled on a very active part of your domain.

 

## Caching Helpers

### Page Caching

As described above in the “Caching Quickstart” section, page caching is very easy to integrate into your application. To turn it on, simply provide the `:cache => true` option on either a controller or one of its routes.

By default, cached content is persisted with a “file store”—that is, in a subdirectory of your application root.

#### expires\_in(seconds)

This helper is used within a controller or route to indicate how often cached *page-level* content should persist in the cache.

After `seconds` seconds have passed, content previously cached will be discarded and re-rendered. Code associated with that route will *not* be executed; rather, its previous output will be sent to the client with a 200 OK status code.

    # Setting content expiry time
    class CachedApp < Padrino::Application
      register Padrino::Cache  # includes helpers
      enable :caching          # turns on caching

      controller '/blog', :cache => true do
        expires_in 15

        get '/entries' do
          'just broke up eating twinkies lol'
        end
      end
    end

Note that the “latest” method call to `expires_in` determines its value: if called within a route, as opposed to a controller definition, the route’s value will be assumed.

#### cache\_key(name)

If set, the cache key used to store the response will be `name`. If this is not specified the default `cache_key` for a request is `request.path_info`. One use of `cache_key` is when you’d like to include query string parameters as part of the key:

    class SimpleApp < Padrino::Application
      get '/post/:id', :cache => true do
        cache_key request.path_info + "?" + params.slice("name", "page").to_param 
        @post = Post.find(params[:id])
      end
    end

This will modify the cache key to include the “name” and “page” query parameters.

### Fragment Caching

Whereas page-level caching, described in the first section of this document, works by grabbing the entire output of a route, fragment caching gives the developer fine-grained control of what gets cached. This type of caching occurs at whatever level you choose.

Possible uses for fragment caching might include:

-   a ‘feed’ of some items on a page
-   output fetched (by proxy) from an API on a third-party site
-   parts of your page which are largely static/do not need re-rendering every request
-   any output which is expensive to render

#### cache(key, opts, &block)

This helper is used anywhere in your application you would like to associate a fragment to be cached. It can be used in within a route:

    # Caching a fragment
    class MyTweets < Padrino::Application
      register Padrino::Cache  # includes helpers
      enable :caching          # turns on caching

      controller '/tweets' do
        get :feed, :map => '/:username' do
          username = params[:username]
          
          @feed = cache( "feed_for_#{username}", :expires_in => 3 ) do
            @tweets = Tweet.all( :username => username )
            render 'partials/feedcontent'
          end
          
          # Below outputs @feed somewhere in its markup
          render 'feeds/show'
        end
      end
    end

This example adds a key to the cache of format `feed_for_#{username}` which contains the contents of that user’s feed. Any subsequent action within the next 3 seconds will fetch the pre-rendered version of `feed_for_#{username}` from the cache instead of re-rendering it. The rest of the page code will, however, be re-executed.

Note that any other action will reference the same content if it uses the same key:

    # Multiple routes sharing the same cached fragment
    class MyTweets < Padrino::Application
      register Padrino::Cache  # includes helpers
      enable :caching          # turns on caching

      controller :tweets do
        get :feed, :map => '/:username' do
          username = params[:username]
          
          @feed = cache( "feed_for_#{username}", :expires_in => 3 ) do
            @tweets = Tweet.all( :username => username )
            render 'partials/feedcontent'
          end
          
          # Below outputs @feed somewhere in its markup
          render 'feeds/show'
        end
        
        get :mobile_feed, :map => '/:username.iphone' do
          username = params[:username]
          
          @feed = cache( "feed_for_#{username}", :expires_in => 3 ) do
            @tweets = Tweet.all( :username => username )
            render 'partials/feedcontent'
          end
          
          render 'feeds/show.iphone'
        end
      end
    end

The `opts` argument is actually passed to the underlying store. All stores included with Padrino support the `:expires_in` option out of the box.

Finally, to DRY up things a bit, we might do:

    # Multiple routes sharing the same cached fragment
    class MyTweets < Padrino::Application
      register Padrino::Cache  # includes helpers
      enable :caching          # turns on caching

      controller :tweets do
        # This works because all routes in this controller specify :username
        before do
          @feed = cache( "feed_for_#{params[:username]}", :expires_in => 3 ) do
            @tweets = Tweet.all( :username => params[:username] )
            render 'partials/feedcontent'
          end
        end
        
        get :feed, :map => '/:username' do
          render 'feeds/show'
        end
        
        get :mobile_feed, :map => '/:username.iphone' do
          render 'feeds/show.iphone'
        end
      end
    end

Of course, this example assumes the markup generated by rendering `partials/feedcontent` would be suitable for both feed formats. This may or may not be the case in your application, but the principle applies: fragments are shared between all code which accesses the cache using the same key.

### Expiring Cached Content

In certain circumstances, cached content becomes stale. The `expire`
 helper removes content associated with a key or keys, which your app is then
 free to re-generate.

#### expire(\*key)

#### Fragment-level expiration

Using the example above of a tweet server, let’s suppose our users have a tendency to post things they quickly regret. When we query our database for new tweets, let’s check to see if any have been deleted. If so, we’ll do our user a favor and instantly re-render the feed.

    # Expiring fragment-level cached content
    class MyTweets < Padrino::Application
      register Padrino::Cache # includes helpers
      enable :caching         # turns on caching
      enable :session         # we'll use this to store last time visited 
      
      COMPANY_FOUNDING = Time.utc( 2010, "April" )
      
      controller :tweets do
        get :feed, :map => '/:username' do
          last_visit = session[:last_visit] || params[:since] || COMPANY_FOUNDING

          username = params[:username]
          @tweets = Tweet.since( last_visit, :username => username ).limit( 100 )
          
          expire( "feed since #{last_visit}" ) if @tweets.any? { |t| t.deleted_since?( last_visit ) }
          
          session[:last_visit] = Time.now
          @feed = cache( "feed since #{last_visit}", :expires_in => 60 ) do
            @tweets = @tweets.find_all { |t| !t.deleted? }
            render 'partials/feedcontent'
          end
          
          render 'feeds/show'
        end
      end
    end

Normally, this example will only re-cache feed content every 60 seconds, but it will do so immediately if any tweets have been deleted.

#### Page-level expiration

Page-level expiration works exactly like the example above by using `expire` in your controller.

The key is typically `env[‘PATH_INFO’]`.

 

## Cache Stores

You can set a global caching option or a per app caching options.

### Global Caching Options

    Padrino.cache = Padrino::Cache::Store::Memcache.new(::Memcached.new('127.0.0.1:11211', :exception_retry_limit => 1))
    Padrino.cache = Padrino::Cache::Store::Memcache.new(::Dalli::Client.new('127.0.0.1:11211', :exception_retry_limit => 1))
    Padrino.cache = Padrino::Cache::Store::Redis.new(::Redis.new(:host => '127.0.0.1', :port => 6379, :db => 0))
    Padrino.cache = Padrino::Cache::Store::Memory.new(50)
    Padrino.cache = Padrino::Cache::Store::File.new(/my/cache/path)

You can manage your cache from anywhere in your app:

    Padrino.cache = Padrino::Cache::Store::Memcache.new(::Memcached.new('127.0.0.1:11211', :exception_retry_limit => 1))
    Padrino.cache = Padrino::Cache::Store::Memcache.new(::Dalli::Client.new('127.0.0.1:11211', :exception_retry_limit => 1))
    Padrino.cache = Padrino::Cache::Store::Redis.new(::Redis.new(:host => '127.0.0.1', :port => 6379, :db => 0))
    Padrino.cache = Padrino::Cache::Store::Memory.new(50)
    Padrino.cache = Padrino::Cache::Store::File.new(/my/cache/path)

### Application Caching Options

    set :cache, Padrino::Cache::Store::Memcache.new(::Memcached.new('127.0.0.1:11211', :exception_retry_limit => 1))
    set :cache, Padrino::Cache::Store::Memcache.new(::Dalli::Client.new('127.0.0.1:11211', :exception_retry_limit => 1))
    set :cache, Padrino::Cache::Store::Redis.new(::Redis.new(:host => '127.0.0.1', :port => 6379, :db => 0))
    set :cache, Padrino::Cache::Store::Memory.new(50)
    set :cache, Padrino::Cache::Store::File.new(Padrino.root('tmp', app_name, 'cache') # default choice

You can manage your cache from anywhere in your app:

    MyApp.cache.set('val', 'test')
    MyApp.cache.get('val') # => 'test'
    MyApp.cache.delete('val')
    MyApp.cache.flush

### Cache Stores

Padrino Cache can be used with various types of stores. At the moment, Padrino Cache
 comes shipped with:

#### Memory

    set :cache, Padrino::Cache::Store::Memory.new(10000)

The Memory Store takes an integer that sets the size to use.

#### File

    set :cache, Padrino::Cache::Store::File.new("/path/to/")

The File Store takes a path to store the cache

#### Memcache

    set :cache, Padrino::Cache::Store::Memcache.new(::Memcached.new)

The Memcache Store takes a Memcache client instance. If you wanted to use another memcached library such as Dalli instead, you would do:

    set :cache, Padrino::Cache::Store::Memcache.new(::Dalli::Client.new)

#### Redis

    set :cache, Padrino::Cache::Store::Redis.new(::Redis.new)

The Redis Store takes a Redis client instance.

##### Mongo

    set :cache, Padrino::Cache::Store::Mongo.new(::Mongo::Connection.new(...))

The Mongo Store takes a Mongo connection instance.