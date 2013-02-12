---
author: Foo Bar
tags: padrino, release
categories: Ruby, Update
title: Padrino 0.9.29 - Stability, compatibility and bug fix release
---

## Upgrade Steps for 0.9.29

When upgrading to this latest release, you should take advantage of project-wide configurations and apply the following
snippet to `apps.rb`:


    pre[ruby]. # config/apps.rb
    Padrino.configure_apps do
    enable :sessions
    # $ padrino rake gen
    # $ rake secret
    set :session_secret, "long secret key pasted here"
    end


Adding this to the top of your `app.rb` will enable sessions in all applications within the project and use a secret
session key to persist the session properly across all these apps. Make sure to run the 'rake secret' command and put
the session key into the `:session_secret` setting. Not doing this can create session related issues in your project.


## Major improvements to Development Reloading

Over the last few releases, we have been experiencing a number of issues with our development reloader.  Certain files
weren't detected or reloaded properly, the reloader would hang up during a reload, certain files would be unloaded
causing exceptions, et al.


In this release, we have worked closely with several users experiencing issues and in many ways completely rewrote the
development code reloading system. We think the reloader is much more stable now and this also means faster boot and
reloading times as well because the new reloader has been greatly streamlined.


Thanks specifically to


    `daddye of our core team for addressing these problems in the rewrite. Commits
    "here":https://github.com/padrino/padrino-framework/commit/7c59e2ae060246a1aa3cbe0f4cb598e7ed90033c,
    "here":https://github.com/padrino/padrino-framework/commit/42bdac70516df094fc639644dbbd9d0a1339e0e3, and
    ["here":https://github.com/padrino/padrino-framework/commit/b41bf1e21cf7a8b911c691e504a4178993c9fae5]. Let's
    not forget even more commits
    "here":https://github.com/padrino/padrino-framework/commit/0122a24347402d9fd16e9c714ba890b54b1f5548,
    "here":https://github.com/padrino/padrino-framework/commit/47c1aba3207316fca92ecf46095f42cc5491c796 and
    finally "here":https://github.com/padrino/padrino-framework/commit/e0c8b3939a7ea6724d5da1e6ec2ab180855b63c4.
    Big thanks to "bernerdschaefer":https://github.com/bernerdschaefer for his help debugging and patching the
    reloader as well!


## Core Cleanup

In addition to the development reloader, we have also cleaned and refactored several other modules within padrino-core.
In particular we have cleaned up and refactored our `SupportLite`, `Padrino::Application`, Gemfile generation, and the
`Padrino::Server`:


- Refactored and cleaned up Padrino::Server:
  [commit](https://github.com/padrino/padrino-framework/commit/bd89dc4540a974cb26e4feeef51a08643a5bf0f8)
- Removed old stuff from support_lite:
  [commit](https://github.com/padrino/padrino-framework/commit/30e7c4a69ffc135bcc5afc9bdea21ffc2591823e)
- Cleanup Gemfile to simplify loading:
  [commit](https://github.com/padrino/padrino-framework/commit/aa3a73d3de44fda32e64a65471ba448c9b8d53ab)
- Cleanup support lite and improved compatiblity with jruby:
  [commit](https://github.com/padrino/padrino-framework/commit/1852a47d4406ed31cc2defd6b96516c5760c9b1f)


This cleanup is part of a larger effort as we work towards solidifying our internals.


## Routing Speed Improvements

Our routing core [http_router](https://github.com/joshbuddy/http_router/commits/master) has been significantly optimized
in the last few point versions for speed. We will be doing several benchmarks soon and will post them but for now
suffice to say we have been making a lot of strides to make our routing even faster then before and this will be an
ongoing effort. Thanks to Joshua Hull of our core team for creating probably the best Ruby request router available and
it work [for plain Sinatra](https://github.com/joshbuddy/http_router_sinatra) too!


## Truncate Words Helper

A new helper has been added called `truncate_words`. This is an alternative to the existing `truncate` method which
shortens a string by characters, this helper shortens a string by words:


```ruby
truncate_words("Once upon a time in a world far far away",
:length => 4) => "Once upon a time…"
```


Commit is [here](https://github.com/padrino/padrino-framework/commit/2b6778389e6b1ff9c8139b8c459b882762e2e538) and
thanks to [cearls](https://github.com/cearls) for contributing this helper for us!


## Better Dependency Handling

We have simplified dependency handling and the approach for adding new dependencies and load_paths to a Padrino
application.


```ruby
# config/boot.rb
Padrino.before_load
MyApp.load_paths << Padrino.root('app', 'observers')
MyApp.dependencies << Padrino.root('other_app', 'controllers.rb')
end
```


Commits [here](https://github.com/padrino/padrino-framework/commit/1852a47d4406ed31cc2defd6b96516c5760c9b1f) and
[[here](https://github.com/padrino/padrino-framework/commit/1852a47d4406ed31cc2defd6b96516c5760c9b1f]).


## Bug and Compatibility Fixes

- Compatibility with CouchRest::Model 1.1:
  [commit](https://github.com/padrino/padrino-framework/commit/826077086eddf1ec3479e7e28aa033a05cfb7ba3)
- Fix bug with render and local vars:
  [commit](https://github.com/padrino/padrino-framework/commit/5aeaa36ef7bd437ef05ba525288bab553ee24ca0)
- Honor **/** in Accept headers correctly -
  [commit](https://github.com/padrino/padrino-framework/commit/f1fdc23b14e2b7885235319a7df971bf4a345be3)
- Rake 0.9 Compatibility:
  [commit](https://github.com/padrino/padrino-framework/commit/117803feaf2ab1c61659b89364115e923f37ec75)
- `Rack::Flash` now sweeps on every request by default:
  [commit](https://github.com/padrino/padrino-framework/commit/d433e19483dcfa63b74065b7141641c0492c5241)
- Supports skipping `Padrino::Render` with constant:
  [commit](https://github.com/padrino/padrino-framework/commit/a9dc6f30e2e2b688a71df182c396a9fef9e71816)

