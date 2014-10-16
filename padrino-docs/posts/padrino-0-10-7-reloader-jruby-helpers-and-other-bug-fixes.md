---
date: 2012-04-27
author: Nathan
email: nesquena@gmail.com
categories: Ruby, Update
tags: padrino, release
title: Padrino 0.10.7 - Reloader, JRuby, Helpers and Other Bug Fixes
---

Several months ago, Padrino 0.10.6 was released which included HTML5 support, improved stability and compatibility patches. Today after some unfortunate delays, we are releasing Padrino 0.10.7 which is a major bug fix and compatibility release. We investigated all major issues reported since the release of 0.10.6 and have addressed the most important issues including renewed JRuby support, a better reloader, activesupport loading, and many other improvements. Full details for this release are below. We look forward to getting back to a quicker release cycle going forward.

<break>

## Bug Fixes, Translations and Miscellaneous

-   Fix reloader issue with class name resolution: [commit](https://github.com/padrino/padrino-framework/commit/5c2623e6ecfaefe0c7cc238fc18319197c15b610)
-   Added support for activerecord-jdbcmysql-adapter: [commit](https://github.com/padrino/padrino-framework/commit/c22420c4f7f1f27b1a4c719db0fc4b221ba3dc26), Thanks [rameshpy](https://github.com/rameshpy)
-   Fix options\_for\_select result in a corner case: [commit](https://github.com/padrino/padrino-framework/commit/caf54927ac3e305ada8e9139b17db8eb3db83e0d), Thanks [whitequark](https://github.com/whitequark)
-   Remove redundant tlsmail dependency: [commit](https://github.com/padrino/padrino-framework/commit/165743e7a11fc7f889759c0b128f3020ce1fcece), Thanks [trevor](https://github.com/trevor)
-   Adds an options attribute to ProjectModule: [commit](https://github.com/padrino/padrino-framework/commit/35844fc3aa3a64050c3eadddda6b4f54aee0aa3c), Thanks [simonc](https://github.com/simonc)
-   Respect configured model name in admin generator: [commit](https://github.com/padrino/padrino-framework/commit/3f7081db8573b472c41fca831241f78fae97ad37), Thanks [joelcuevas](https://github.com/joelcuevas)
-   Patched to fix rake use in padrino templates, Thanks [jasonm23](https://github.com/jasonm23)
-   Fix error\_message\_on for empty array, Thanks [sshaw](https://github.com/sshaw)
-   Adds Swedish localization support, Thanks [Lejdborg](https://github.com/Lejdborg)
-   Adds Romanian localization support, Thanks [relu](https://github.com/relu)
-   Prevent JRuby reloading bug, Thanks [dn2k](https://github.com/dn2k)
-   Fix admin generator to understand model\_name, Thanks [fnordfish](https://github.com/fnordfish)
-   Add CLI shortcut with just ‘c’, Thanks [joslinm](https://github.com/joslinm)
-   Adds a catch all method to the redis cache
-   Make mysql2 alias of mysql when DataMapper is selected
-   Add require ActiveSupport::TimeWithZone class for helpers
-   Change boolean helper attributes to conform to xhtml strict

That concludes the changelog for this release. As always if you want to keep up with Padrino updates, be sure to follow us on twitter: [@padrinorb](http://twitter.com/#!/padrinorb), join us on IRC at “\#padrino” on freenode or [open an issue](https://github.com/padrino/padrino-framework/issues) on GitHub.