---
author: Foo Bar
tags: padrino, sinatra, ruby
categories: Ruby, Update
title: Padrino 0.10.0 - Routing Upgrades, Rbx and JRuby Support, and Minor Breaking Changes
---

## Rendering Module Changes

In this release, we have introduced a breaking change to the way Padrino loads the `Padrino::Rendering` module. Working
with [botanicus](https://github.com/botanicus) recently on [an
issue](https://github.com/padrino/padrino-framework/issues/541), we uncovered a problem with the auto-loading of our
enhanced rendering module.


The issue is that any extension to Sinatra/Padrino that wishes to extend rendering was unable to load before our module.
This produced situations where Padrino rendering is difficult to enhance with outside extensions.  We have decided to
**remove the autoloading** of `Padrino::Rendering`.  For freshly generated applications, no action needs to be taken
because Rendering will be included in the generated application.


For an existing application, all you need to do is add an explicit include to `Padrino::Rendering`:


```ruby
# app/app.rb
class Demo < Padrino::Application
  register Padrino::Rendering # <= Add this line
  # …
  register Padrino::Helper
end
```

on every application within a project. For those that are curious, the `Padrino::Rendering` module is the functionality
that enhances “render” to auto-locate templates and adds support for I18n amongst a variety of other conveniences that
makes template rendering much more powerful and convenient. If you are using `render "index"` in your code then you are
using this module. Commit
[here](https://github.com/padrino/padrino-framework/commit/981f481eee02d16ed206eedf801f831627a2ec37).


## Rubinius and JRuby Compatibility

This release also marks full support for [Rubinius](http://rubini.us) and [JRuby](http://www.jruby.org), two of the
upcoming stable ruby implementations gaining attention. As of [this
tweet](http://twitter.com/#!/DAddYE/status/77857253406932992), we are now 100% compatible with Rubinius and have tested
full support for JRuby. Uchio Kondo, the offical Japanese documentation maintainer for Padrino has also created an
excellent guide for [Running Padrino on JRuby](http://www.padrinorb.com/guides/running-padrino-on-jruby) which gets you
started. Commits [here](https://github.com/padrino/padrino-framework/commit/ecf3968f216cbfb97008b487e34742c5b6f2f4ab),
[here](https://github.com/padrino/padrino-framework/commit/4838791fe7a685179630ad4175a099a800f8626c), and
[here](https://github.com/padrino/padrino-framework/commit/f991ea5376c71ee00f8bdf532c126c162c15dced).


## Routing Speed Improvements

Josh has enabled serious performance gains in `http_router` which has once again allowed Padrino to parallel Sinatra in
performance even in an [more advanced demo](https://github.com/DAddYE/web-frameworks-benchmark/tree/more_advanced)
application. In all our benchmarks, Sinatra and Padrino are generally neck-in-neck:


    # Benchmarks

    System: Linux 2.6.18-xenU-ec2-v1.0
    Processor: Intel® Xeon® CPU E5430 @ 2.66GHz
    Memory: 1740948 kB
    Ruby: ruby 1.9.2p180 (2011-02-18 revision 30909) [i686-linux]

    Using:
    padrino (0.10.0)
    rack (1.3.0)
    sinatra (1.2.6)
    rack (1.2.3)
    rails (3.0.8)
    camping (2.1)

    Results:
    rack => 620.95 rps
    camping => 398.74 rps
    sinatra => 309.78 rps
    padrino => 302.64 rps
    merb => 291.43 rps
    rails => 122.37 rps


Commits [here](https://github.com/padrino/padrino-framework/commit/459c57e16ff8a9d9c27b23c311c3e6bf3e1432aa) to upgrade
`http_router` and take advantage of the optimizations. Thanks again to joshbuddy (Joshua Hull) of our core team for
hacking on these upgrades!


## Route Filters

An oft-requested feature is for [enhanced route filters](https://github.com/padrino/padrino-framework/issues/443). While
Sinatra does have [basic support](http://sinatra-book.gittr.com/#filters) for filters, a heavy user will often find that
it leaves things to be desired. Namely when dealing with namespaces and routes.  Whereas before, a filter looks like
this:


```ruby
# app/controllers/example_controller.rb
DemoApp.controller :example do
  before “/example/**" do
  # Code here to be executed
end

get :index do
  # …
  end
end
```


Now you can have a lot more options related to filters and they work much more intuitively thanks to Joshua and you can
do:


```ruby
# app/controllers/example_controller.rb
DemoApp.controller :example do
  # Based on a symbol
  before :index do
  # Code here to be executed
end

# Based on a symbol, regexp and string all in one
before :index, /main/, ‘/example’ do
  # Code here to be executed
end

# Also filter by excluding an action
before :except => :index do
  # Code here to be executed
end

get :index do
  # …
  end
end
```


This gives developers a lot more flexibility when running filters and enables much more selective execution in a
convenient way. Great to have this feature available as part of our routing enhancements. Commits
[here](https://github.com/padrino/padrino-framework/commit/459c57e16ff8a9d9c27b23c311c3e6bf3e1432aa) and
[here](https://github.com/padrino/padrino-framework/commit/434c4beee4f69fa478b078f704096a88c70290a1).


## Route Ordered Priority

This release has also added support for respecting route order in controllers and also allows the developer to specify
certain routes as less or more "important" then others in the route recognition order. Consider two controllers, the
first with a "catch-all" route that matches any URL and the second below in another controller that is very specific.
This wouldn’t work by default because the second endpoint would be eclipsed by the catch-all route and as such would not
be accessible. To solve this, you can do the following:


```ruby
# app/controllers/pages.rb
MyApp.controller :pages do
  # NOTE that this route is now marked as low priority
  get :show, :map => :map => ‘/*page’, :priority => :low do
    "Catchall route"
  end
end

# app/controllers/projects.rb
MyApp.controller :projects do
  get :index do
    "Important Index"
  end
end
```


When setting a routes priority to `:low`, this route is then recognized in order lower then all "high" and "normal"
priority routes. You are encouraged in cases where there is ambiguity, to mark key routes as `:priority => :high` or
catch-all routes as `:priority => :low` in order to guarantee expected behavior.


Commit [here](https://github.com/padrino/padrino-framework/commit/670185db74bdb10f707229740e27a606862ddb71).


## Reloader Fixes

The reloader has been much improved in the last release, and we are continuing in that tradition improving the reloader
again to be more robust in this release:


- Better support for constant reloading
  [”commit“:[https://github.com/padrino/padrino-framework/commit/e6ee8d34da21291b5d136de29272b10f78bc883b](https://github.com/padrino/padrino-framework/commit/e6ee8d34da21291b5d136de29272b10f78bc883b)]
- Fix Padrino::Reloader reloading also `$LOADED_FEATURES` deps
  [”commit“:[https://github.com/padrino/padrino-framework/commit/fd1c439d99c574e788bbfcee8b5fb2b81af65928](https://github.com/padrino/padrino-framework/commit/fd1c439d99c574e788bbfcee8b5fb2b81af65928)]
- Remove incomplete constants when require fails (Thanks bernerdschaefer)
  [”commit“:[https://github.com/padrino/padrino-framework/commit/a2720b773d6c0dc957f906d4ec70e8b253c47644](https://github.com/padrino/padrino-framework/commit/a2720b773d6c0dc957f906d4ec70e8b253c47644)]


There is also a new way to add files to the reloader manually using the `prerequisites` method:


```ruby
# app/app.rb
MyApp.prerequisites << Padrino.root(‘my_app’, ‘custom_model.rb’)
```


This will autoload those files and watch them for changes. Commit
[here](https://github.com/padrino/padrino-framework/commit/f41d374cdb68d62f812e4f345f37da0ec032053b).


## Other changes and fixes

- Adds support for the Ripple ORM (Thanks pepe)
  [”commit“:[https://github.com/padrino/padrino-framework/commit/916f9502cfe0b2644fe7dac7516b2b36caf004d4](https://github.com/padrino/padrino-framework/commit/916f9502cfe0b2644fe7dac7516b2b36caf004d4)]
- Hungarian translations added (Thanks Kormány Zsolt)
  [”commit“:[https://github.com/padrino/padrino-framework/commit/e59c2e9899ec2aa55b59c4fa37d4eb20d4a3604d](https://github.com/padrino/padrino-framework/commit/e59c2e9899ec2aa55b59c4fa37d4eb20d4a3604d)]
- Controller now supports conditions at multiple levels (Thanks
  ”bernerdschaefer“:[https://github.com/bernerdschaefer](https://github.com/bernerdschaefer))
  [”commit“:[https://github.com/padrino/padrino-framework/commit/6e30adf7788071bb1945f91aca034a9e5b3dc950](https://github.com/padrino/padrino-framework/commit/6e30adf7788071bb1945f91aca034a9e5b3dc950)]
- Gemspecs and config.ru are now executable (Thanks botanicus):
  [”commit“:[https://github.com/padrino/padrino-framework/commit/ceb3d879db8819a030119f5b194056652d89b86a](https://github.com/padrino/padrino-framework/commit/ceb3d879db8819a030119f5b194056652d89b86a),
  ”commit“:[https://github.com/padrino/padrino-framework/commit/07afbd745a8f58740b713b384fc859eed934f434](https://github.com/padrino/padrino-framework/commit/07afbd745a8f58740b713b384fc859eed934f434)]
- Add support for `padrino s` for starting the padrino server
  [”commit“:[https://github.com/padrino/padrino-framework/commit/29d08e8550abffab586344e7557a4393fe4187ec](https://github.com/padrino/padrino-framework/commit/29d08e8550abffab586344e7557a4393fe4187ec)]
- Fix field generation for DataMapper
  [”commit“:[https://github.com/padrino/padrino-framework/commit/b1c949a47266a5482cf1f06a214f4b26d32c28aa](https://github.com/padrino/padrino-framework/commit/b1c949a47266a5482cf1f06a214f4b26d32c28aa)]
- Fixes issue with DM length for strings
  [”commit“:[https://github.com/padrino/padrino-framework/commit/1b79dca7ca51221c79020eff0942dc2c5a3d2077](https://github.com/padrino/padrino-framework/commit/1b79dca7ca51221c79020eff0942dc2c5a3d2077)]
- Fixes double loading for boot.rb in rake tasks
  [”commit“:[https://github.com/padrino/padrino-framework/commit/0ff251405458500820c3a3e85720a88ea140265e](https://github.com/padrino/padrino-framework/commit/0ff251405458500820c3a3e85720a88ea140265e)]
- Cleanup padrino-core dependencies in `support_lite`
  [”commit“:[https://github.com/padrino/padrino-framework/commit/dda2b77ca37b34cb7c1f5cbcc80d13d03fb81b3f](https://github.com/padrino/padrino-framework/commit/dda2b77ca37b34cb7c1f5cbcc80d13d03fb81b3f)]
- Bundler is now auto-loaded in our binaries
  [”commit“:[https://github.com/padrino/padrino-framework/commit/a8ef567a6d74d8df0c0e2da3fa5dccee58830e31](https://github.com/padrino/padrino-framework/commit/a8ef567a6d74d8df0c0e2da3fa5dccee58830e31)]
- Adds access to `current_controller` as part of the public API
  [[commit](https://github.com/padrino/padrino-framework/commit/8f678af970c4d1fb1520da12786a968e02680e97])
- Changes DM instructions to recommend `rake dm:auto:upgrade`
  [[commit](https://github.com/padrino/padrino-framework/commit/67606df1d84c9fcb191debbf113f1931a716d9db])

