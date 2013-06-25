---
date: 2010-03-01
author: Nathan
email: nesquena@gmail.com
title: Controllers
---

Suppose we wanted to add routes to our Padrino application, and we want to organize a set of related routes within a more structured grouping. Padrino has the notion of a ‘controller’ block which can group related routes and make URL generation much easier. Simply add a `controllers.rb` file or `app/controllers` folder and create a file as such:

    # app/controllers/main.rb or controllers.rb
    SimpleApp.controller do
      get "/test" do
        "Text to return"
      end

      get "/sample" do
        "Sample Route"
      end
    end

In this case, the controller merely acts as a structured grouping mechanism to allow better organization of routes. Controllers actually have other benefits as well when used in conjunction with the enhanced Padrino routing system.

 

## Enhanced Routing

Padrino provides advanced routing definition support to make routes and URL generation much easier. This routing system supports named route aliases and easy access to url paths. The benefits of this is that instead of having to hard-code route URLs into every area of your application, now we can just define the URLs in a single spot and then attach an alias which can be used to refer to the URL throughout the application.

 

## Basic Routing Aliases

The routing system supports named aliases by using symbols instead of strings for your routes:

    # app/app.rb
    class Demoer < Padrino::Application
      get :index do
        # url is generated as '/'
        # url_for(:index) => "/"
      end

      get :account, :with => :id do
         # url is generated as '/account/:id' 
         # url_for(:account, :id => 5) => "/account/5"
         # access params[:id]
      end
    end

These routes can then be referenced anywhere in the application:

    # app/views/example.haml
    <%= link_to "Index", url_for(:index) %>
    <%= link_to "Account", url_for(:account, :id => 1) %>

 

## Inline Route Alias Definitions

The routing plugin also supports inline route definitions in which the explicit URL and the named alias are both defined:

    # app/main.rb
    class Demoer < Padrino::Application
      get :index, :map => '/index/example' do
        # url_for(:index) => "/index/example"
      end

      get :account, :map => '/the/accounts/:name/and/:id' do
        # url_for(:account, :name => "John", :id => 5) => "/the/accounts/John/and/5"
        # access params[:name] and params[:id]
      end
    end

Routes defined inline this way can be accessed and treated the same way as traditional named aliases:

    # app/views/example.haml
    <%= link_to "Index Page", url_for(:index)%>
    <%= link_to "Account Page", url_for(:account, :id => 1) %>

 

## Namespaced Route Aliases

There is also support for namespaced routes which are organized into a named controller group:

    # app/controllers/admin.rb
    SimpleApp.controllers :admin do
      get :index do
        # url is generated as '/admin/' 
        # url_for(:admin, :index) => "/admin"
      end

      get :show, :map => "/admin/:id" do
         # url is generated as "/admin/#{params[:id]}"
         # url_for(:admin, :show, :id => 5) => "/admin/5"
      end
    end

You can then reference these routes using the same url\_for method:

     # app/views/admin.haml
    <%= link_to 'admin show page', url_for(:admin, :index) %>
    <%= link_to 'admin index page', url_for(:admin, :show, :id => 25) %>

If you prefer explicit URLs to named aliases, that is also supported within a specified controller group:

    # app/controllers/example.rb
    SimpleApp.controllers "/admin" do
      get "/show" do
        # url is generated as "/admin/show"
      end

      get "/other/:id" do
        # url is generated as "/admin/#{params[:id]}"
      end
    end

 

## Named Parameters

With Padrino you can also specify named parameters within your route definition:

    # app/controllers/example.rb
    SimpleApp.controllers :admin do
      get :show, :with => :id do
        # url is generated as "/admin/show/#{params[:id]}"
        # url_for(:admin, :show, :id => 5) => "/admin/show/5"
      end

      get :other, with => [:id, :name]  do
        # url is generated as "/admin/other/#{params[:id]}/#{params[:name]}"
        # url_for(:admin, :other, :id => 5, :name => "hey") => "/admin/other/5/hey"
      end
    end

You can then reference the URLs using the same url\_for method:

    <%= link_to 'admin show page', url_for(:admin_show, :id => 25) %>
    <%= link_to 'admin other page', url_for(:admin_other, :id => 25, :name => :foo) %>

 

## Nested Routes

You can specify parent resources in padrino with the :parent option on the controller:

    # app/controllers/example.rb
    SimpleApp.controllers :product, :parent => :user do
      get :index do
        # url is generated as "/user/#{params[:user_id]}/product"
        # url_for(:product, :index, :user_id => 5) => "/user/5/product"
      end
      get :show, :with => :id do
        # url is generated as "/user/#{params[:user_id]}/product/show/#{params[:id]}"
        # url_for(:product, :show, :user_id => 5, :id => 10) => "/user/5/product/show/10"
      end
    end

If need be the parent resource can also be specified on inline routes in addition:

    # app/controllers/example.rb
    SimpleApp.controllers :product, :parent => :user do
      get :index, :parent => :project do
       # url is generated as "/user/#{params[:user_id]}/project/#{params[:project_id]}/product"
       # url(:product, :index, :user_id => 5, :project_id => 8) => "/user/5/project/8/product"
      end
    end

 

## Layouts

With Padrino, a custom layout can be specified or the layout can be disabled altogether:

    class SimpleApp < Padrino::Application
      # Disable layouts
      disable :layout
       
      # Use the layout located in views/layouts/custom.haml
      layout :custom
    end

Note that layouts are *scoped by controller*, so you can apply different layouts to different controllers:

    SimpleApp.controllers :posts do
      # Apply a layout for routes in this controller
      # Layout file would be in 'app/views/layouts/posts.haml'
      layout :posts 
      get("/posts") { render :haml, "Uses posts layout" }
    end

    SimpleApp.controllers :accounts do
      # Padrino allows you to apply a different layout for this controller
      # Layout file would be in 'app/views/layouts/accounts.haml'
      layout :accounts 
      get("/accounts") { render :haml, "Uses accounts layout" }
    end

If necessary, you also can overwrite the layout for a given route:

    SimpleApp.controllers :admin do
      get :index do
        render "admin/index", :layout => :admin
      end

      get :show, :with => :id do
        render "admin/show", :layout => false
      end
    end

 

## Provides Formats

With Padrino you can simply declare which formats a request will respond to by using the `provides` route configuration:

    # app/controllers/example.rb
    SimpleApp.controllers :admin do
      get :show, :with => :id, :provides => :js do
        # url is generated as "/admin/show/#{params[:id]}.#{params[:format]}"
        # url_for(:admin, :show, :id => 5, :format => :js) => "/admin/show/5.js"
      end

      get :other, :with => [:id, :name], :provides => [:html, :json] do
        case content_type
          when :js    then ... end
          when :json  then ... end
        end
      end
    end

and these formatted route paths can be accessed easily using `url_for` and then `format` option:

    <%= link_to 'admin show page', url_for(:admin, show, :id => 25, :format => :js) %>
    <%= link_to 'admin other page', url_for(:admin, index, :id => 25, :name => :foo) %>
    <%= link_to 'other json', url(:admin, index, :id => 25, :name => :foo, :format => :json) %>

 

## Route Filters

Before filters are evaluated before each request within the context of the request and can modify the request and response. Instance variables set in filters are accessible by routes and templates:

    before do
      @note = 'Hi!'
    end

After filter are evaluated after each request within the context of the request and can also modify the request and response. Instance variables set in before filters and routes are accessible by after filters:

    after do
      puts @note
    end

This is now standard in Sinatra but Padrino adds support for filters being *scoped by controller* which means that unlike Sinatra in which a filter is global, in Padrino you can run different filters for each controller:

    SimpleApp.controllers :posts do
      before { @foo = "bar" }
      get("/posts") { render :haml, "Has access to @foo variable" }
    end

    SimpleApp.controllers :accounts do
      before { @bar = "foo" }
      get("/accounts") { render :haml, "Has access to @bar variable" }
    end

This allows for more fine-grained filters and prevents the need to have unnecessary filters running on every route. As of Padrino 0.10.0, there is also a much more powerful route selection system that has been setup:

    # app/controllers/example_controller.rb
    DemoApp.controller :example do
      # Based on a symbol
      before :index do
        # Code here to be executed
      end

      # Based on a symbol, regexp and string all in one
      before :index, /main/, '/example' do
        # Code here to be executed
      end

      # Also filter by excluding an action
      before :except => :index do
        # Code here to be executed
      end

      get :index do
        # ...
      end
    end

This gives developers a lot more flexibility when running filters and enables much more selective execution in a convenient way.

 

## Prioritized Routes

Padrino (0.10.0+) has added support for respecting route order in controllers and also allows the developer to specify certain routes as less or more “important” then others in the route recognition order. Consider two controllers, the first with a “catch-all” route:

    # app/controllers/pages.rb
    MyApp.controller :pages do
      get :show, :map => '/*page' do
        "Catchall route"
      end
    end

    # app/controllers/projects.rb
    MyApp.controller :projects do
      get :index do
        "Index"
      end
    end

This wouldn’t work by default because the second “/projects” endpoint would be eclipsed by the “/\*page” catch-all route and as such `projects` would not be accessible. To solve this, you can do the following:

    # app/controllers/pages.rb
    MyApp.controller :pages do
      # NOTE that this route is now marked as low priority
      get :show, :map => '/*page', :priority => :low do
        "Catchall route"
      end
    end

    # app/controllers/projects.rb
    MyApp.controller :projects do
      get :index do
        "Index"
      end
    end

When setting a routes priority to `:low`, this route is then recognized lower then all “high” and “normal” priority routes. You are encouraged in cases where there is ambiguity, to mark key routes as `:priority => :high` or catch-all routes as `:priority => :low` in order to guarantee expected behavior.

 

## Custom Conditions

Padrino has support for Sinatra’s custom route conditions as well. This allows you to apply custom condition checks to evaluate before a route is executed for an incoming request:

    # app/controllers/example.rb
    SimpleApp.controllers do
      def protect(*args)
        condition {
          unless username == "foo" && password == "bar"
            halt 403, "Not Authorized"
          end
        }
      end

      get "/", :protect => true do
        "Only foo can see this"
      end
    end

Conditions can also be specified at the controller and route levels:

    # app/controllers/example.rb
    # You can specify conditions to run for all routes:

    SimpleApp.controller :conditions => {:protect => true} do
      def self.protect(protected)
        condition do
          halt 403, "No secrets for you!" unless params[:key] == "s3cr3t"
        end if protected
      end

      # This route will only return "secret stuff" if the user goes to
      # `/private?key=s3cr3t`.
      get("/private") { "secret stuff" }

      # And this one, too!
      get("/also-private") { "secret stuff" }

      # But you can override the conditions for each route as needed.
      # This route will be publicly accessible without providing the
      # secret key.
      get :index, :protect => false do
        "Welcome!"
      end
    end

This gives the developer considerable power to construct arbitrarily complex route conditions and apply them to any route within their application.

 

## Rendering

Unlike Sinatra, Padrino supports automatic template engine lookups with:

    # searches for 'account/index.{erb,haml,...}
    render 'account/index'

It will choose the first one that is discovered, without regards to the type of rendering (erb, haml). Otherwise you can explicitly specify the type of rendering of your choice (erb, haml).

    # example.haml
    render :haml, 'account/index'

Padrino also automatically considers your current locale and/or content\_type.

    # app/controllers/example.rb
    SimpleApp.controllers :admin do
      get :show, :with => :id, :provides => [:html, :js] do
        render "admin/show"
      end
    end

When you visit the `:show` route with `I18n.locale == :ru` enabled, Padrino will first try to look for “admin/show.ru.js.\*” if nothing matches that criteria, it will try “admin/show.ru.\*” then “admin/show.js.\*”. As a last resort, if he finds nothing matching your criteria, it will return “admin/show.erb” (or admin/show.haml)

## Using Sessions

(kindly borrowed from Sinatra's docs :))


### Using Sessions

A session is used to keep state during requests. If activated, you have one
session hash per user session:

``` ruby
enable :sessions

get '/' do
  "value = " << session[:value].inspect
end

get '/:value' do
  session[:value] = params[:value]
end
```

Note that `enable :sessions` actually stores all data in a cookie. This
might not always be what you want (storing lots of data will increase your
traffic, for instance). You can use any Rack session middleware: in order to
do so, do **not** call `enable :sessions`, but instead pull in your
middleware of choice as you would any other middleware:

``` ruby
use Rack::Session::Pool, :expire_after => 2592000

get '/' do
  "value = " << session[:value].inspect
end

get '/:value' do
  session[:value] = params[:value]
end
```

To improve security, the session data in the cookie is signed with a session
secret. A random secret is generated for you by Sinatra. However, since this
secret will change with every start of your application, you might want to
set the secret yourself, so all your application instances share it:

``` ruby
set :session_secret, 'super secret'
```

If you want to configure it further, you may also store a hash with options in
the `sessions` setting:

``` ruby
set :sessions, :domain => 'foo.com'
```

To share your session across other apps on subdomains of foo.com, prefix the
domain with a *.* like this instead:

``` ruby
set :sessions, :domain => '.foo.com'
```
