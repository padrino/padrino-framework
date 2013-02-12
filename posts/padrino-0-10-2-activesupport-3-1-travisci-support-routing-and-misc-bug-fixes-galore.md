---
author: Foo Bar
tags: padrino, release
categories: Ruby, Update
title: Padrino 0.10.2 - ActiveSupport 3.1, TravisCI Support, Routing and Misc Bug Fixes Galore
---

## Upgrade to ActiveSupport 3.1

ActiveSupport 3.1 has been officially released and we have upgraded Padrino accordingly! Padrino 0.10.2 and on will
require the latest and greatest ActiveSupport. Upgrading should be painless because there are not many backwards
incompatibilities.


## TravisCI

This release marks the beginning of our use of [Travis CI for
Padrino](http://travis-ci.org/#!/padrino/padrino-framework). TravisCI is a great tool for the open source community and
improves our continuous integration testing for all versions of Ruby.
[commit](https://github.com/padrino/padrino-framework/commit/5e7f244de66bf412e5183b50827019d894eb6e4d)


## Routing

This release is largely pushed out to fix a major route reloading bug recently introduced. Reloading has continuously
been the most error-prone and hardest to test aspect of our system. This has become frustrating for us as well as for
our users. However, thanks to
[Hollin Wilkins & Dave Willett @ TrueCar in San Francisco](https://github.com/chromaticbum), this route issue has been
resolved for now. Please [let us know](https://github.com/padrino/padrino-framework/issues) if you are still
experiencing issues when on 0.10.2!  Check out the
[commit](https://github.com/padrino/padrino-framework/commit/0a09adce5bd84a1d201576fa8046f1d4210d27d6) which fixed the
issue.


We also fixed an issue with routes that contain the word ‘index’. Check out the
[commit](https://github.com/padrino/padrino-framework/commit/506ad5414279d737908d7d97f6c244a31b3a1828).


## Components

- Adds support for mysql2 when using sequel as adapter (Thanks [rafaelss](https://github.com/rafaelss)):
  [commit](https://github.com/padrino/padrino-framework/commit/a447f0d6129a90fa9baa3c8c1dc1e0ecd76bf692)
- Fixes potential issue with libxml-ruby (Thanks [farcaller](https://github.com/farcaller)):
  [commit](https://github.com/padrino/padrino-framework/commit/a492a5bb648827e924c750dc8435dc5b25dc43ea)


## Miscellanious and Bug Fixes

- Default content type for mailer has been corrected:
  [commit](https://github.com/padrino/padrino-framework/commit/8496dca3ce1c1666c72af511287769227c261afb)
- Rendering a hash i.e render :json => obj is now properly set as json:
  [commit](https://github.com/padrino/padrino-framework/commit/807658be63d9b391d72d8482586e1402a2107d1a)
- Protect admin login from XSS attacks:
  [commit](https://github.com/padrino/padrino-framework/commit/9f4c3158c23daa8140f917d9210aefda8467df7f)
- Escape certain html entities when writing html tags:
  [commit](https://github.com/padrino/padrino-framework/commit/7a3d0b38b3a4b5e71c553248d149bab38d8338ae)
- Fixes error block handling for ::Exception:
  [commit](https://github.com/padrino/padrino-framework/commit/8daec1d3fcf69e6ce8ca95d09c12f06c037acd79)
- Fix model `test_config` require when not using default top level:
  [commit](https://github.com/padrino/padrino-framework/commit/b44b5ac49db9a7b3fa2d3abc76ce40ab3345781e)
- Outputs the partials that are rendered in development mode (Thanks [minikomi](https://github.com/minikomi)):
  [commit](https://github.com/padrino/padrino-framework/commit/d4c3b41ca1c8fe80d68254b36796d088a2ad88ad)
- Preserve the original options when resolving a template (Thanks [Xylakant](https://github.com/Xylakant)):
  [commit](https://github.com/padrino/padrino-framework/commit/bf7c898a716a7c653d243bab42734d1700657dfd)
- Moved from rdoc documentation to yard:
  [commit](https://github.com/padrino/padrino-framework/commit/7c5c60475c3909e0c0c1d7ba4057b215e2ff1a59)
- Fix issue with not respecting `RACK_ENV` in the CLI:
  [commit](https://github.com/padrino/padrino-framework/commit/5d631d47ecc7617f22dda21de3d607893a60d453)
- Fixes issue when rendering partials with a forward slash (Thanks [philly-mac](https://github.com/philly-mac)):
  [commit](https://github.com/padrino/padrino-framework/commit/29c8c37bf583eb1108eeb4c431def0c820b821b4),
  [commit](https://github.com/padrino/padrino-framework/commit/5f1fcabdbde0457afb058d4a5109542a016c90c0)


That concludes the changelog for this release. As always if you want to keep up with Padrino updates, be sure to follow
us on twitter: [@padrinorb](http://twitter.com/#!/padrinorb), join us on IRC at “#padrinorb” on freenode or
[open an issue](https://github.com/padrino/padrino-framework/issues) on GitHub.

