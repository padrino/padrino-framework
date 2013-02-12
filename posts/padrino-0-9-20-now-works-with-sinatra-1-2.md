---
author: Foo Bar
tags: padrino, sinatra, ruby
categories: Update
title: Padrino 0.9.20 - now works with Sinatra 1.2
---

There are no breaking changes from the previous version. Other than Sinatra 1.1.X and 1.2 support, the following are the
major changes in 0.9.20:


## Middleware Management

You can now easily manage middleware in front of the Padrino application stack. To add middleware simply do:


```ruby
Padrino.use(Some::Middleware)
```


You can also clear all middleware with:


```ruby
Padrino.clear_middleware!
```


See [this commit](https://github.com/padrino/padrino-framework/commit/0a9d11a01c51b5c351bb98b310cff55e4b659c1f) for more
information about this.


## New Rendering Components

Padrino now supports *slim* and *erubis* rendering engines out of the box. To use slim or erubis, just use the
generators:


`$ padrino g project example --renderer=slim # or erubis`


This will generate the project to use those templates by default and properly include them in the Gemfile!


## Namespaced Mounter Support

Padrino's project mounter now supports namespaced applications properly as follows:


```ruby
module ::SomeNamespace
class AnApp < Padrino::Application; end
end

Padrino.mount("some_namespace/an_app").to("/")
```


See [this commit](https://github.com/padrino/padrino-framework/commit/b7f5bb94d7a4e7264fcc8be5bc0b245f996ee60f) for more
details. Thanks mcmire!


There were also a lot of other bug fixes in this release as we try to become more and more stable towards a 1.0 release.


## Next Step

We are already working towards a 0.9.21 release and will likely include more bug fixes, more components, etc.  If you run
into a problem please do let us know on [Github Issues](https://github.com/padrino/padrino-framework/issues) or better
yet with a [Pull Request](https://github.com/padrino/padrino-framework/pulls) .


You can also check out the [full changelog](http://www.padrinorb.com/changes) as well.

