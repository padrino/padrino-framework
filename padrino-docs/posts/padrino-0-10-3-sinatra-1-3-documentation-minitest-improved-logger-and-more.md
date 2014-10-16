---
date: 2011-09-27
author: Arthur
email: mr.arthur.chiu@gmail.com
categories: Ruby, Update
tags: padrino, release
title: Padrino 0.10.3 - Sinatra 1.3, Documentation, Minitest, Improved Logger, and
  More
---

This month and the next is a great time for the Sinatra community at large. [Sinatra 1.3](https://github.com/sinatra/sinatra/tree/v1.3.0) has been [released](http://www.sinatrarb.com/2011/09/30/sinatra-1.3.0) with a lot of exciting changes. Alongside the official release, the [sinatra-contrib](https://github.com/sinatra/sinatra-contrib) project is also slowly maturing and will be semi-officially supported by the Sinatra team. The [sinatra-recipes](http://sinatra-book-contrib.com) resource is a great reference to using components with Sinatra. In addition, Kyle Drake has come along and released [sinatra-synchrony](http://kyledrake.net/sinatra-synchrony) which allows for evented concurrent Sinatra applications with almost no code changes and no callbacks.

Thankfully, because Padrino is just Sinatra at its core, our framework and our users can benefit from all the great things being introduced recently for Sinatra. Today we have pushed our Padrino 0.10.3 release which contains a lot of major updates. 0.10.3 upgrades our core to Sinatra 1.3, upgrades our entire test suite to minitest, and upgrades our entire source code documentation to YARD. We have also been hard at work fixing bugs, upgrading our logger, and improving compatibility with JRuby and Rubinius wherever possible. There is also a **deprecation** you should be aware of in regards to rack-flash. Details for this release are below.

<break>

## Sinatra 1.3 Upgrade

[Sinatra 1.3](https://github.com/sinatra/sinatra/tree/v1.3.0) has been [released](http://www.sinatrarb.com/2011/09/30/sinatra-1.3.0) with a lot of exciting changes. Be sure to checkout the changes in 1.3.0 in the [Sinatra Changelog](https://github.com/sinatra/sinatra/blob/v1.3.0/CHANGES).

In this release, we have happily upgraded our core to Sinatra 1.3.0. Don’t worry as there weren’t any breaking changes and upgrading your Padrino projects should be painless. Now all of Padrino is Sinatra 1.3 compatible and taking advantage of the updates including the default enabled [rack-protection](https://github.com/rkh/rack-protection).

One interesting feature of Sinatra 1.3 to note is the new streaming API:

    # app.rb
    get '/' do
      stream do |out|
        out << "It's gonna be legen -\n"
        sleep 0.5
        out << " (wait for it) \n"
        sleep 1
        out << "- dary!\n"
      end
    end

As explained by RKH, the cool thing about this is that it abstracts away the differences between all the different Rack servers taking into account their capabilities. Be sure to read the [official announcement](http://www.sinatrarb.com/2011/09/30/sinatra-1.3.0) to see other new features.

Related 1.3 integration commits are [here](https://github.com/padrino/padrino-framework/commit/6304d1ed4c3b5308917500c43e888433b0695e6d), [here](https://github.com/padrino/padrino-framework/commit/3acbdb24b0cbbdc331b94baf01bfc3a198645feb), and [here](https://github.com/padrino/padrino-framework/commit/1029a40f943f82aaad4f417aa7e1e1445df930b4).

## Rack-Flash Deprecation

The [rack-flash](https://github.com/nakajima/rack-flash) gem has been a dependency of Padrino since early versions of our framework. The gem provides the `flash` functionality that most of us depend on in our controllers. Unfortunately, this gem is not compatible with the latest versions of Rack or Sinatra. This gem also depends on private APIs and is not actively maintained. For this reason, Sinatra and Padrino developers are **advised to replace** `rack-flash` in their projects before upgrading to 0.10.3.

Fortunately, upgrading your project and replacing `rack-flash` is easy thanks to several viable alternatives that provide the same functionality. First and foremost is the new Padrino default for flash, the [sinatra-flash](https://github.com/SFEley/sinatra-flash) gem. This gem is essentially a drop-in replacement that works in nearly the same way while maintaining a cleaner codebase and leveraging only stable Sinatra public APIs. This gem is likely to work consistently with Sinatra going forward.

New projects in Padrino now automatically include this replacement and upgrading to `sinatra-flash` is as easy as replacing `rack-flash` in your Gemfile:

    # Gemfile
    gem "sinatra-flash" # Replaces gem "rack-flash"

In addition, daddye has contributed a [slimmer and faster flash](https://github.com/padrino/padrino-contrib/blob/master/lib/padrino-contrib/helpers/flash.rb) in padrino-contrib. Usage is described in the file itself but is as easy as `register Padrino::Contrib::Helpers::Flash`. Either solution should make upgrading a snap.

For more information about the switch be sure to read the [Github Issue](https://github.com/padrino/padrino-framework/issues/679) on the subject or see the [related commit](https://github.com/padrino/padrino-framework/commit/cad9e8f62025736146f5f13d3ead2424c2b1d3aa).

## Testing and Minitest

We have been using test-unit and [shoulda](https://github.com/thoughtbot/shoulda) in Padrino as long as the framework has been around. I am a personal fan of test-unit + shoulda and have been using the combination successfully in many projects. However, times change and the fact that Ruby 1.9 seems to recommend [minitest](http://www.rubyinside.com/a-minitestspec-tutorial-elegant-spec-style-testing-that-comes-with-ruby-5354.html) over test-unit encouraged us to take a look at the pain of upgrading.

We wanted a faster test suite and less external dependencies. So we decided to bite the bullet and convert our entire test suite over to the `minitest` test library. Built into 1.9 but available as a gem for 1.8.X, this library is quite stable and fast. The best part is that it has a lot of the great parts of shoulda built in. Thanks to the magic of a few [strategic aliases](https://github.com/padrino/padrino-framework/blob/master/padrino-core/test/mini_shoulda.rb), we can even keep the same shoulda syntax we know and love. Thanks to [Ken Collins](http://metaskills.net/2011/03/26/using-minitest-spec-with-rails) for making our path from Test::Unit to MiniTest a painless one. We are excited to have a leaner, faster test suite going forward.

Commits are [here](https://github.com/padrino/padrino-framework/commit/f2a88af060f49ac6c8145cc4b2be93fbb6944e08), [here](https://github.com/padrino/padrino-framework/commit/cf1496e30521f08a276e4e9e4b917e28437fdb66), [here](https://github.com/padrino/padrino-framework/commit/406d08355319a464c205ae76fcd38587f54ff80d), and [here](https://github.com/padrino/padrino-framework/commit/08c18df8aafac3d8ee817fad90e31a5b9d1a7a8e).

## Documentation

Since the creation of Padrino, we have always aspired to have good documentation, guides, and release notes that make getting started with our framework that much easier. That said, we had always used RDoc for our inline source docs and we felt the generated APIs and our documentation coverage left something to be desired.

In this release, we are happy to announce that we have converted the entire source code documentation to YARD and
 in the process did a better job of documenting the public and semipublic interfaces for our framework. We are excited about this release and continuing to improve our documentation. Thanks to [postmodern](https://github.com/postmodern) for helping us get the ball rolling.

Converting this documentation was a team effort with lots of commits: [1](https://github.com/padrino/padrino-framework/commit/9ae898fdbd1381839acc334ec3ed376ab72d9a66), [2](https://github.com/padrino/padrino-framework/commit/2fd8ca7eddec897d3c40188cc30a3658f563ec7e), [3](https://github.com/padrino/padrino-framework/commit/e3f5ad1bdd4f14ab1a69c2df1c215dbb1f5f4162), [4](https://github.com/padrino/padrino-framework/commit/1680307328e8c2f2dc8b129bca41999331107379), [5](https://github.com/padrino/padrino-framework/commit/a5e542d181a2ab13c81effe0e136cbcf0a5eb2ee), [6](https://github.com/padrino/padrino-framework/commit/6676fda49ee3133989e0f33852c375826dd68cb9), [7](https://github.com/padrino/padrino-framework/commit/e218f09a089efa9119efbd01aed8693d8244f135), [8](https://github.com/padrino/padrino-framework/commit/60e1681fa5029c5baf568cd92ebeed6c3f6ca745), [9](https://github.com/padrino/padrino-framework/commit/8f0f1cee12de50b9816f6f25e4feac0d3904d121).

You can checkout the newly generated YARD docs for Padrino at our [API Docs](http://www.padrinorb.com/api/index.html) page. We would appreciate any patches to help us improve our docs even further! Speaking of which, a few more documentation fixes:

-   Fix issue with generator for template runner on https paths (Thanks [xavierRiley](https://github.com/xavierRiley)): [commit](https://github.com/padrino/padrino-framework/commit/e5fc1a60a9b60f46f5916d1ce88bbf6a98918aee).
-   Removes unnecessary commas in doc example (Thanks [ugisozols](https://github.com/ugisozols)): [commit](https://github.com/padrino/padrino-framework/commit/366fd117ac9fe44da82a11967c3edf4ad00b45bf).
-   Document better example of Padrino::Admin::AccessControl (Thanks [Benjamin Oakes](https://github.com/benjaminoakes)): [commit](https://github.com/padrino/padrino-framework/commit/4841a6cb6129ff65e5c1d301ee51bbc64b75874e).
-   Fix typos and inaccuracies related to \`time\_ago\_in\_words\` helpers: [commit](https://github.com/padrino/padrino-framework/commit/3984c59aea91ad10705ddc51b21b19901990a7d0)

Also, be sure to check out our entirely new [Getting Started](http://www.padrinorb.com/guides/getting-started) guide geared towards newcomers to the Sinatra / Padrino community. The guide is intended to provide you the necessary basics and resources to become familiar with the Ruby, Rinatra and Padrino ecosystem.

## Components

We have also made a few improvements and updates to our components:

-   Adds minitest test component to project generator: commits [here](https://github.com/padrino/padrino-framework/commit/27843a1a145ed7f6229e096c11211440da406f64), and [here](https://github.com/padrino/padrino-framework/commit/426df4538c60a88766bceb9c34e017e9edcf270d).
-   Remove less dependency for less generation: [commit](https://github.com/padrino/padrino-framework/commit/8640a06e7f18131951c2f6c36e811e8dd57da204).
-   Added content\_for? method to test for content (Thanks [mlightner](https://github.com/mlightner)): [commit](https://github.com/padrino/padrino-framework/commit/2d6e623c76ceb927bf48ea1b8a02c894ddd5cc7e).
-   Make YAML locale files Psych compliant for JRuby 1.9 support (Thanks [skade](https://github.com/skade)): [commit](https://github.com/padrino/padrino-framework/commit/6d81ce0e8468e0507bb2089ad39d404fbb3acc8b).
-   Improved logger with much nicer colors and formatted output: [[commit](https://github.com/padrino/padrino-framework/commit/c3b05abc79457ecd6ab4302adfec35054bf974d4) [here](https://github.com/padrino/padrino-framework/commit/54c6de0a92eb3a051a88366f0c0acb2938d73d80), [here](https://github.com/padrino/padrino-framework/commit/c0b24769487b872de34eef7aeac94aa9eab3cd29) and [here](https://github.com/padrino/padrino-framework/commit/94405a863814768fb2be43edf45780bfbaa060f2)].
-   Adds Latvian locale translation (Thanks [ugisozols](https://github.com/ugisozols)): [commit](https://github.com/padrino/padrino-framework/commit/e5fc2860128ea81a7f602db0f5d03be3bae2b502).

## Asset Compression

One final bonus feature to this post is a quick discussion about asset compression / pipelines. Since the release of that feature as a default in Rails 3.1, we have been fielding a lot of questions regarding an equivalent module for Sinatra and Padrino. In the spirit of addressing these concerns, a few early options for Sinatra:

-   [Jammit Sinatra](https://github.com/railsjedi/jammit-sinatra) – Excellent sinatra wrapper for Jammit
-   [padrino-sprockets](https://github.com/nightsailer/padrino-sprockets) – Still a young project but looks promising.
-   [assets\_compressor](https://github.com/padrino/padrino-contrib/blob/master/lib/padrino-contrib/helpers/assets_compressor.rb) – Padrino-contrib recipe for simple compression of assets.
-   [Sinatra AssetPack](https://github.com/rstacruz/sinatra-assetpack) – Great asset compilation for Sinatra
-   [Middleman](https://github.com/tdreyno/middleman) – Interesting Padrino-powered alternative for asset handling

These options should get you started if you are interested in bringing asset pipelining to your Sinatra applications. None of these quite match the comprehensive Rails solution just yet but well on their way.

That concludes the changelog for this release. As always if you want to keep up with Padrino updates, be sure to follow us on twitter: [@padrinorb](http://twitter.com/#!/padrinorb), join us on IRC at “\#padrino” on freenode or [open an issue](https://github.com/padrino/padrino-framework/issues) on GitHub.