---
author: Foo Bar
tags: ruby, sinatra, padrino, benches
categories: Ruby, Update
title: Padrino 0.9.10 Released - Built for speed!
---

## Performance Optimizations

Right after announcing Padrino, many developers began to request benchmarks to give them a better understanding of how
our framework compared in terms of performance with the existing ruby web frameworks.


Personally, no one on our team is a big fan of benchmarks since they can often be misleading and real world usage is
generally quite different. However, we thought that providing a set of simple benchmarking results would help people get
at least a basic sense of Padrino’s speed.


According to our [benchmarks](http://github.com/DAddYE/web-frameworks-benchmark]), **Padrino** is now about as fast as
Sinatra (and in some cases actually a bit faster!).


For our benchmarks, we chose to test three different sample applications. The
[first test](http://github.com/DAddYE/web-frameworks-benchmark/tree/text_render]) was a bare minimum app as a
baseline where a response is just rendered with a short inline string. The
[second test](http://github.com/DAddYE/web-frameworks-benchmark/tree/template_render]) is a simple app where we render a
small erb template. The [third test](http://github.com/DAddYE/web-frameworks-benchmark/tree/more_advanced]) was the
most comprehensive with a more ‘full-stack’ application including sessions, haml, layouts, templates, flash, and
helpers.


    # Rendering a string inline
    Merb 1.1.0 => 1749.97 rps
    Padrino 0.9.10 => 1629.15 rps
    Sinatra 1.0.0 => 1537.78 rps
    Rails 3.beta3 => 381.76 rps
    Ramaze 2010.04.04 => 270.08 rps

    # Rendering a basic erb template
    Merb 1.1.0 => 1490.8 rps
    Padrino 0.9.10 => 1416.84 rps
    Sinatra 1.0.0 => 1157.89 rps
    Rails 3.0.beta3 => 330.58 rps
    Ramaze 2010.04.04 => 254.23 rps

    # Rendering a simulated simple app
    Padrino 0.9.10 => 675.79 rps
    Sinatra 1.0.0 => 652.0 rps
    Merb 1.1.0 => 642.29 rps
    Rails 3.0.beta3 => 201.86 rps
    Ramaze 2010.04.04 => 130.62 rps


*rps = requests per second* (higher is better)


As you can see Padrino is very competitive in terms of speed in 0.9.10!  In every case, Padrino is on par speed-wise
with the equivalent Sinatra application. Be sure to check out the code for our benchmarks and let us know how we can
improve them!


## New Localized Translations

We added four new languages to the admin, helpers and error message translations:

- Danish [Thanks to [Molte](http://github.com/molte])
- French [Thanks to [Mickey](http://github.com/mickey])
- Russian [Thanks to [Imm](http://github.com/imm])
- Brazilian [Thanks to [Deminew](http://github.com/deminew])


If you want to contribute a translation for another language, please follow the
[translation guide](/guides/localization) and fork/send us your translations.


## New Persistence Adapters

We are very very glad to announce that **Padrino** can now build the
admin interface with these orm adapters:


- Couchdb [Thanks to [Ghostm](http://github.com/ghostm])
- Sequel [Thanks to [Aemadrid](http://github.com/aemadrid])


This means **Padrino** now fully supports the following persistence engines: MongoMapper, MongoId, CouchDb, ActiveRecord
and Sequel.


In the future, we are also planning to integrate: [OHM](http://github.com/soveran/ohm) (for redis) and
[Friendly](http://github.com/jamesgolick/friendly) as well among others.


If you want to contribute a component, be sure to checkout the [guide for adding
components](http://www.padrinorb.com/guides/adding-new-components) which explains how to add a component to the
generator and admin.


## Enhanced Router Capabilities

In this version of **Padrino**, we have introduced the
[Padrino#router](http://github.com/padrino/padrino-framework/blob/master/padrino-core/lib/padrino-core/router.rb)


This class is an extended version of [Rack::URLMap](http://github.com/rack/rack/blob/master/lib/rack/urlmap.rb) which is
responsible for:


- Mapping a path to the specified App (like URLMap)
- Ignoring server names (this solve several issues with virtual hosts
  and domain aliases)
- Using hosts instead of server name for match mappings (this help us
  with our vhost and domain aliases)


Padrino is principally designed to support [mountable applications](/pages/why#mountable-applications) and now with
`Padrino#router` things are much simpler because you can match for a host pattern:


```ruby
Padrino.mount_core(“Blog”).host(“blog.example.org”)
Padrino.mount(“Admin”).host(“admin.example.org”)
Padrino.mount(“WebSite”).host(/.**.?example.org/)
Padrino.mount.to.host
```


In addition to these changes,**Padrino** has also been improved to work out of the box (with no special configuration)
when deploying projects on [Passenger](http://www.modrails.com) and even when
[deploying to Sub-URIs](http://www.modrails.com/documentation/Users%20guide%20Nginx.html#deploying_rails_to_sub_uri]).


## Route Provides and Conditions

Now controllers accept Sinatra `conditions` and that means `respond_to` can work together with Sinatra `provides`.


Our `provides/respond_to` auto sets the `content_type` looking for the request format (aka extension ex: .js, .json) and
can set it according to the `request.accept`


```ruby
get :foo, :provides => [:js, :json] do … end
# older respond_to is still supported
get :foo, :respond_to => [:js, :json] do … end
```


Or you can write:


```ruby
provides :js, :json
get :foo do … end
```

Remember that now you also can build your custom conditions (like in Sinatra):


```ruby
def protect(**args)
  condition {
    unless username  "foo" && password  “bar”
    halt 403, “go away”
    end
  }
end

get “/”, :protect => true do
  “Only foo can see this”
end
```


## Scoped Filters and Layouts

Padrino now scopes both filters and layouts for each controller. This means that layouts and/or route filters
defined in a `controller` do not interfere with those defined in the main application or in other controllers.


```ruby
SimpleApp.controllers :posts do
  # Apply a layout for routes in this controller
  # Layout file would be in ‘app/views/layouts/posts.haml’
  layout :posts
  before { `foo = "bar" }
  get("/posts") { render :haml, "Uses posts layout and `foo = #{@foo}" }
end

SimpleApp.controllers :accounts do
  # Padrino allows you to apply a different layout for this controller
  # Layout file would be in ‘app/views/layouts/accounts.haml’
  layout :accounts
  before { `bar = "foo" }
  get("/accounts") { render :haml, "Uses accounts layout and `bar = #{@bar}" }
end
```


As you can see each controller is now scoped allowing for easy grouping of layouts and filters for all routes within a
particular controller.


## Default Values

In certain scenarios like `I18n` apps, we need to repeat given values for multiple routes like:


    get :show, :with => [:id, :lang] do ... end


and repeat this option multiple times with `:lang => I18n.locale` like:


    url(:show, :lang => I18n.locale, :id => 123)


Now you can easily save yourself time with:


    controller :lang => I18n.locale do
      get :show, :with => [:id, :lang] do ... end
    end


and in this way you can build urls like:


    url(:show, :id => 123)


and the default controller settings will be automatically appended to
the route.


## Minor Features

Padrino 0.9.10 also features support for a host of minor improvements:

- Added support for *ext-core* as javascript engine [Thanks to [Imm](http://github.com/imm])
- Mailer now supports explicitly setting the template path to render for a mail method
- Beautiful colorized logging support
- Ruby 1.9.2-head compatibility
- Now sessions (like Sinatra) are disabled as default
- Updated jquery to v1.4.2
- Added `padrino rake routes`


## Bug Fixes

- Removed always “index” from our routes name
- Fixes SASS reload plugin issue on 1.9.X
- Fixes an issue with generator not casing controller / model names
- Fixed `padrino g` and `padrino gen` aliases
- Fixes issue with mounter and locating the app file
- Removed VERSION files. This prevent problems described here:
  [http://github.com/nex3/haml/issues/issue/24](http://github.com/nex3/haml/issues/issue/24)
- Fixed a bug with layouts that prevent double rendering
- ActiveSupport 3.0 Compatibility fixes


## Summary

As you can see there are some important fixes and new features but we want to point out a few things:


- Padrino is already quite stable (remember that since version 0.7 our team has been using it in the real world)
- This project is very actively contributed to and our team is committed to this framework and fix bugs quickly.


And what is next for Padrino?


We can anticipate right now that our team will soon be completing **padrino templates and plugins**, the **tiny app
generator** and the **padrino-cache** gem.


After we complete these items and fix any bugs that crop up, Padrino can be ready for ONE-DOT-ZERO release!

