---
author: Foo Bar
tags: ruby, updates
categories: Update
title: Padrino 0.9.25 - Slim and Erubis, Caching, and Fixes
---

## Padrino Cache

The [padrino-cache](https://github.com/padrino/padrino-framework/tree/master/padrino-cache) gem has had a long journey
and has traditionally been the neglected and abandoned sibling in the Padrino framework family.


This is no longer the case with this release. The padrino-cache gem has now been added as a first-class member of the
Padrino framework.


The functionality includes a variety of caching types and stores including **memcached** and **redis** support.  Adding
new adapters in the future will be very easy as the gem was designed for extensibility in mind. This is the caching
solution you always hoped to have when using Sinatra.


For more information, check out the
[README](https://github.com/padrino/padrino-framework/blob/master/padrino-cache/README.rdoc) as well as the
[Padrino Cache Guide](http://www.padrinorb.com/guides/padrino-cache) for a solid overview of this new addition to our framework.


Thanks to core member Joshua Hull for the majority of the caching implementation and Joshua Morris , Arthur Chiu, and
DAddYE for the Caching documentation.


Here’s an example of the caching gem usage:


```ruby
# app/app.rb
class Sample < Padrino::Application
register Padrino::Helpers
register Padrino::Mailer
register Padrino::Cache
…
end

# lib/awesome.rb
Padrino.cache.set # => this is shared between apps
Sample.cache.set“).first) # => this is used only by Sample app

# app/controllers.rb
Sample.controllers do
get :background do
cache.get(:background)
end
…
end

# demo/controllers.rb
Demo.controllers :cache => true do
get :foo do
render :some_thing_longer
end

get :bar, :cache => false do
Padrino.get(:categories)
end
…
end
```

You can start using this now in your Padrino and Sinatra applications.  Let us know what you think.


## UJS Adapters

Padrino has been waiting on unobtrusive JavaScript handling for a while now as well. This enables support for ‘remote’
links and forms as well as setting link ‘methods’ and having the unobtrusive JavaScript adapters make that ‘just work’.


For more information on these unobtrusive JavaScript handlers, check out the
[Helpers Guide](http://www.padrinorb.com/guides/application-helpers#unobtrusive-javascript-helpers)
which will give you a good overview of what’s now available once the ujs adapter is included in your project.


Not all of the adapters are finished for each JavaScript framework yet, but we intend on getting them integrated soon.
Of course, we could always **use your help!** jquery and prototype UJS adapters are complete but the others are only in
partial states of completion.


Check out the [padrino-static](https://github.com/padrino/padrino-static)
project to see all of the files associated with this effort. Please fork and help us improve this adapters.


You can read about how to add a new JavaScript component or add UJS support in the
[Adding Components](http://www.padrinorb.com/guides/adding-new-components#javascript-library)
guide.


An example code:


```ruby
# /app/views/users/new.html.haml
- form_for :user, url(:create, :format => :js), :remote => true do
|f|
.content=partial”/users/form"
```


which will generate the following unobtrusive markup:


```html
<form data-remote=“true” action=“/items/create.js”
method=“post”>
<div class=“content”>
<input type="text" id="post_title" name="post[title]">
<input type="submit" value="Create">
</div>
</form>
```


```ruby
# /app/controllers/users.rb
post :create, :provides => :js do
`user = User.new(params[:user])
if `user.save
“$(‘form.content’).html(‘#{partial(“/users/form”)}’);”
else
“alert(‘User is not valid’);”
end
end
```


This feature should make JavaScript and Ajax handling in Sinatra / Padrino easier then ever before.


## Routing Enhancements

In this release, **Joshua Hull** has also completely rewrote [http_router](https://github.com/joshbuddy/http_router),
the router library that powers **Padrino** under the hood.


This rewrite does **not** break compatibility with previous padrino releases and does not break the existing routing
syntax.


The changes are mostly abstracted away from usage in Padrino, but the router is now leaner, faster and easier to extend.


Since it was designed to be more flexible, it also supports multiple named parameter captures and other things that
weren’t support in the previous release of Padrino.


Some examples:


```ruby
# app/controllers.rb
get :show, :map => ‘/pictures/*path.html’ do
…
end

get :index do
# Generates: “/?account[name]=foo&account[surname]=bar”
url
end

get “/email/:email”, :format => :json do |email|
# => [foo@bar.com](mailto:foo@bar.com)
email
end
```


Our new router is still under continued development but should not cause any breaking changes when you upgrade your
applications. If you run into any issues please .


## Erubis and Slim Helper Support

In the past few versions, we have had partial [Slim](https://github.com/stonean/slim) and
[Erubis](https://github.com/kwatch/erubis) support but not full compatibility with our various helpers.


This was because of broken implementations of capture and concat for those template engines .


Thankfully with the help of [Makoto Kuwata](https://github.com/kwatch) of Erubis and
[Andrew Stone](https://github.com/stonean) of Slim, and a
[couple](https://github.com/rtomayko/tilt/commit/623811e72df0bc20f3e9d6925241927ff76b6f2c)
[patches](https://github.com/rtomayko/tilt/commit/e894029970498829051ab3400af2fa7ab8956e30) to
[Tilt](https://github.com/rtomayko/tilt), we have been able to correct this and bring about full support for our helpers
in Slim and Erubis bringing them in line with the existing support for Haml and ERB. The template engines are also
supported by the Padrino generator now as well.


As for tilt and sinatra, Erubis is the new standard engine for processing erb files. Another enhancement allows Padrino
to use **mixed** templates combining templates and partials from multiple engines.


For example:


```haml
# views/yours.haml
%p=partial ‘show/an/erb/partial.erb’
```


```ruby
# partial.erb
<%= some code in erb here %>
```


This has been a tremendous effort getting these engines to work together and to provide full helper support for Slim,
Erubis, ERB, and HAML. Thanks specifically to **DAddYE** of our core team for the implementation. Also **RKH** from the
Sinatra team for his help.


## Sessions and Flash

`Rack::Flash` is no longer dependent on rack’s default sessions, so you are able to use `Rack::Flash` with other session
engines such as memcached, datamapper, mongomapper etc…


Unfortunately you’ll now need to update your projects to specifically enable sessions inside your `app.rb` to use
`Rack::Flash`, otherwise an error will be returned.


```ruby
class PadrinoWeb < Padrino::Application
enable :sessions
end
```


## Select Tag Enhancements

Thanks to ActiveStylus, the select tag also sports a number of improvements. You can now specify the options as a range
directly:


```ruby
select_tag
```


or pass in a grouped options set:


```ruby
grouped_options =
select_tag
```


All previous select tag options should work without any breaking compatibility issues.


## Secret key for sessions

Now according to the new Sinatra we have a `session_secret` and rake task to generate new keys. In projects generated
with **Padrino 0.9.25** this will be generated in your `app.rb` as default, if you upgrade from an older project you can
use our rake task.


Some code:


```ruby
# app/app.rb
class Sample < Padrino::Application
set :session_secret,
“6ca7e9fd7b1eb5a447ae3ba55495621c9169e8ec236ef19829a7684cf86f2404”
…
end
```


    # Generate a secret key
    $ padrino-dev rake secret
    => Executing Rake secret …
    7043bc560e73c46f0d5eabedbabd217f9f5277e6935047bb9430296ab7b47a44


## Logger Improvements

Our logger got several major readability enhancements and now logs *cache set* and *cache get* with the amount of time
spent.


An example:


    # First request
    DEBUG~~ “MONGODB
    padrino_www_development[‘accounts’].find({:_id=>nil})”
    DEBUG~~ [08/Apr/2011 22:02:17] “GET (0.0121ms) 127.0.0.1 - - /admin/
    HTTP/1.1 - 302 ~~"
    DEBUG~~ [08/Apr/2011 22:02:17]”MONGODB
    padrino_www_development[‘accounts’].find({:_id=>nil})"
    DEBUG - [08/Apr/2011 22:02:17] “GET (0.0269ms) 127.0.0.1 - -
    /admin/sessions/new HTTP/1.1 - 200 1749”
    DEBUG - [08/Apr/2011 22:02:17] “GET (0.0010ms) 127.0.0.1 - -
    /admin/stylesheets/themes/default/style.css?1268092944 HTTP/1.1 - 200
    6741”
    DEBUG - [08/Apr/2011 22:02:17] “MONGODB
    padrino_www_development[‘accounts’].find({:_id=>nil})”
    DEBUG - [08/Apr/2011 22:02:17] “GET (0.0023ms) 127.0.0.1 - -
    /admin/stylesheets/override.css?1302292937
    HTTP/1.1 - 302 ~~"
    DEBUG~~ [08/Apr/2011 22:02:17]”GET (0.0008ms) 127.0.0.1 - -
    /admin/stylesheets/base.css?1269259073 HTTP/1.1 -
    200 4774"
    DEBUG - [08/Apr/2011 22:02:17] “MONGODB
    padrino_www_development[‘accounts’].find({:_id=>nil})”
    DEBUG - [08/Apr/2011 22:02:17] “GET (0.0097ms) 127.0.0.1 - -
    /admin/sessions/new HTTP/1.1 - 200 1749”
    DEBUG - [08/Apr/2011 22:02:20] “Resolving layout
    /src/padrino-web/app/views/layouts/application”

    # Second request
    DEBUG - [08/Apr/2011 22:03:10] “GET Cache (0.0002ms) /”
    DEBUG - [08/Apr/2011 22:03:10] “GET (0.0083ms) 127.0.0.1 - - / HTTP/1.1
    - 200 18475”


## Other significant changes

- Padrino logger can now be disabled -
  [commit](https://github.com/padrino/padrino-framework/commit/99df83fc83f75c4da901dad23bcb7478a0e3159b)
- Uses official mongomapper release -
  [commit](https://github.com/padrino/padrino-framework/commit/e777d29fe62260e3a626a892db439e2a5f98460a)
- Fixes issue with ERB capture support in certain edge cases -
  [commit](https://github.com/padrino/padrino-framework/commit/ab6f2cb33d659b63702db0ce15bdec8aaa5f59db)
- Fixes ajax jquery detection
  [commit](https://github.com/padrino/padrino-framework/commit/b1448586f1cbaa81bf6b89bc0e1624a7ad033f31)
- Added Lib to folders to be reloaded in development -
  [commit](https://github.com/padrino/padrino-framework/commit/39a08b2878801cf5d8570c6ad2c5313d31a56e7e)
- Added mounted app name to the log for debugging -
  [commit](https://github.com/padrino/padrino-framework/commit/a7796bd0b037c6f50d408f908e05a9e9af79bf69)
- Fixes to Form Builder and object name generation [Thanks funny-falcon)]
  [commit](https://github.com/padrino/padrino-framework/commit/99fb4a71bc9cd3c7e4c2327e35d161ba202559e3)
- `stylesheet_link_tag` and `javascript_include_tag` (allow array input) -
  [pull](https://github.com/padrino/padrino-framework/pull/465)

