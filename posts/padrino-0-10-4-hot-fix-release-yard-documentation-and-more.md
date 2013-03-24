---
date: 2011-10-06
author: Nathan
email: nesquena@gmail.com
categories: Update
tags: padrino, release
title: Padrino 0.10.4 - Hot Fix Release, YARD Documentation, and more
---

Following the recent [release of 0.10.3](http://www.padrinorb.com/blog/padrino-0-10-3-sinatra-1-3-documentation-minitest-improved-logger-and-more), we got a handful of bug reports that we wanted to address in a quick follow up release. This release is primarily composed of several important bug fixes and also improved YARD documentation coverage. Anyone using 0.10.X is recommended to upgrade to this release ASAP. Full details for this release are below.

We have also subsequently released one more minor fix in 0.10.5.

<break>

## Two important fixes

Recently, [Etienne Lemay](https://github.com/EtienneLem) brought two important bug reports to our attention after the 0.10.3 release. Both of them were issues affecting newcomers and were addressed in this release:

-   Fixes issue with new “sinatra-flash” dependency in generated Gemfile: [commit](https://github.com/padrino/padrino-framework/commit/f4014fca5a6e706e88d110e9321459c208c06582)
-   Fix exception when template rendering is logged in certain cases: [commit](https://github.com/padrino/padrino-framework/commit/fc7fbe92a994f2687fe8bce1dbdf13b3c01fd641)

Glad these were reported quickly so we could fix them as soon as possible. Regression tests were put in place to ensure these issues cannot happen again.

## Documentation

Additional work has been put in to reach 100% documentation coverage for all the Padrino subgems according to YARD’s documentation analysis tools. Commits are listed below:

[1](https://github.com/padrino/padrino-framework/commit/c629aac866e489442ad5b13728eac7ff6b056daa), [2](https://github.com/padrino/padrino-framework/commit/980f527095efb8cc4a4926a391328f9870b9b675), [3](https://github.com/padrino/padrino-framework/commit/615608965d4045d1745a736ac3a37abc0c7462c7), [4](https://github.com/padrino/padrino-framework/commit/a1f68550bd2eb4154b919086aa8fcf6901c98996), [5](https://github.com/padrino/padrino-framework/commit/cf866abc015762f9fd311330346e4904f1ede8ef), [6](https://github.com/padrino/padrino-framework/commit/eb797b188dfb40edfe73304716ae5b92864f98b3), [7](https://github.com/padrino/padrino-framework/commit/10ff22f1990b3e31e4229546a406a61b970b6a1f), [8](https://github.com/padrino/padrino-framework/commit/746de950c4326771d3a7fe99f0e53b9f3200ae90)

There is still a lot of documentation work to be done both for the code and for our guides. We would very much appreciate any [help with docs](http://www.padrinorb.com/pages/contribute#want-to-help-with-documentation).

## Miscellaneous

-   Ensures that static\_cache\_control is respected when serving static files: [commit](https://github.com/padrino/padrino-framework/commit/da0201aecf76d39fbbd8f056e8e87c55164174e2)
-   Improved logger for cache calls: [commit](https://github.com/padrino/padrino-framework/commit/f5e9fe6c2ffaa6488fafda023b1c42526a211436)
-   Added status code to request logs [Thanks [udzura](https://github.com/udzura)] [commit](https://github.com/padrino/padrino-framework/commit/d7d3e5619b31fba63572dc8a438edea48a4694fc)

That concludes the changelog for this release. As always if you want to keep up with Padrino updates, be sure to follow us on twitter: [@padrinorb](http://twitter.com/#!/padrinorb), join us on IRC at “\#padrinorb” on freenode or [open an issue](https://github.com/padrino/padrino-framework/issues) on GitHub.