---
date: 2011-08-01
author: Nathan
email: nesquena@gmail.com
categories: Update
tags: padrino, sinatra, ruby
title: Padrino 0.10.1 - Mongo Cache Store, Routing, Translation, and Bug Fixes
---

On July 8th, we released Padrino 0.10.0 which was the biggest release in a series of releases that are paving the way towards a 1.0 version. Fortunately, the release was well received without many serious issues cropping up during the upgrade process from 0.9.X.

Today, we are releasing 0.10.1 which is mostly a cleanup and bug fix release. Originally, we were hoping for this release to align with Sinatra 1.3 but that will likely happen in the next release now. This release adds a new mongo adapter for padrino-cache, applies some important fixes to routing, cleans up our translation files and has several compatibility and bug fixes reported since our last version. Details for this release are below.

<break>

## Mongo Cache Store

[aliem](https://github.com/aliem) sent us a pull request for a Mongo-based cache store that plugs into our existing [padrino-cache](http://www.padrinorb.com/guides/padrino-cache) system. Thanks to his work, all the caching goodness can now be stored with Mongo. If you see a missing adapter to our caching solution, please consider sending us a pull request. Commits [here](https://github.com/padrino/padrino-framework/commit/2d69af735367879bcd65b85c994c235d1d68e244), [here](https://github.com/padrino/padrino-framework/commit/a6da03ca2e1311dd7a8b8f1175be39009b0ecccb), and [here](https://github.com/padrino/padrino-framework/commit/80a74af0231496904d09ab715d81105f158c738f).

## Routing Fixes

There are a handful of important routing fixes in this release, thanks to [joshbuddy](https://github.com/joshbuddy).

-   Parent support restful routing: [commit](https://github.com/padrino/padrino-framework/commit/44870a8cd5a047478378b71f94d3d9feba801141)
-   Before filters are called regardless of matching: [commit](https://github.com/padrino/padrino-framework/commit/4afab7c7385d74a6c44801cb12c20981f23059c8)

Be sure to [raise an issue](https://github.com/padrino/padrino-framework/issues) if you experience any routing problems.

## Translation Fixes

We have made an effort to improve the reliability and completeness of our translations in this release largely thanks to [TweeKane](https://github.com/TweeKane) who brought these issues to our attention. We have corrected the known issues with the translations and also added locale tests to prevent these problems in the future.

-   Added Missing IT translations: [commit](https://github.com/padrino/padrino-framework/commit/b3edab9b62c8a7fee248184c26757d5380a1e39e)
-   Adds missing CS, DE, NL locales: commits [here](https://github.com/padrino/padrino-framework/commit/db78dc2ae482ebd7217568afcef3e8a48506607b) and [here](https://github.com/padrino/padrino-framework/commit/a71bff4ef5b346b62bc6d5c259c3fcef46f08a61)
-   Fixes to FR, CN, RU locales (Thanks [TweeKane](https://github.com/TweeKane)): commits [here](https://github.com/padrino/padrino-framework/commit/38a2d1b5a7ae8d33f7b51d79a406e8708e547a65), [here](https://github.com/padrino/padrino-framework/commit/7dd6dfde011515f0824d206983bcb78865644ab4), and [here](https://github.com/padrino/padrino-framework/commit/0da9c06ecd9b5679c585376177acb4931cbc8c38)
-   Adds unit tests for locales: commits [here](https://github.com/padrino/padrino-framework/commit/17873849d0a70f4087155b035ece523df10131be), and [here](https://github.com/padrino/padrino-framework/commit/2fd84e43933163f282ecedbfd76a1bc6c1677628)

## Compatibility and Bug Fixes

-   Padrino is now fully compatible with Slim 1.0 and Ruby 1.9.3: [commit](https://github.com/padrino/padrino-framework/commit/b6dcc164607a77eb3242ed61fc5fd1e1a33c52df)
-   Padrino is now compatible with bundler \~\> 1.0: [commit](https://github.com/padrino/padrino-framework/commit/cb5927ba3e829cb14e943b6cb447945553f1c676)
-   Admin generator now properly destroys access control when removed: [commit](https://github.com/padrino/padrino-framework/commit/3f6fb6b5bca23a1f99eb8f944c557cdc159490d4)
-   Fixes admin generator with namespaced models: [commit](https://github.com/padrino/padrino-framework/commit/cdca24436826676edac530c1a15fe5d2ba74402b)
-   Cleanup Rake::DSL inclusion causing errors on 1.9.2: [commit](https://github.com/padrino/padrino-framework/commit/af8aa97cf5fb9702f50e6e57223de60e0f603b72)
-   Quick fix for hiding ‘padrino.instance’ environment data: [commit](https://github.com/padrino/padrino-framework/commit/20eb22907dc97cfdb8d3d8af1903d5165bef5250)
-   Allow configuring of logger ahead of load: commits [here](https://github.com/padrino/padrino-framework/commit/2d877931fcdb7902dd126b5e164d52e12964cf89), [here](https://github.com/padrino/padrino-framework/commit/e3ff9ca75888cb6fa052a3b24131f0c2542337a4), and [here](https://github.com/padrino/padrino-framework/commit/cce0719d2fff58e518788c639b7d15f4b66e633c)
-   Cleanup error message (Thanks [mariozig](https://github.com/mariozig)): [commit](https://github.com/padrino/padrino-framework/commit/cd2b14345f97794806293c8317bb6ff5570e1891)
-   Fix minor doc bug in logger (Thanks [xylakant](https://github.com/Xylakant)): [commit](https://github.com/padrino/padrino-framework/commit/d9926a59dcb7c2526ba760143f5c0b5a1cb80273)
-   Add host parameters in DM postgres adapter (Thanks [Aigeruth](https://github.com/Aigeruth)): [commit](https://github.com/padrino/padrino-framework/commit/7e35bdecc19e1f32f974ae6103cd6a504a91fc03)

That concludes the changelog for this release. As always if you want to keep up with Padrino updates, be sure to follow us on twitter: [@padrinorb](http://twitter.com/#!/padrinorb), join us on IRC at “\#padrinorb” on freenode or contact us on [GitHub](https://github.com/padrino/padrino-framework/issues).