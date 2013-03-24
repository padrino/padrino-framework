---
date: 2012-01-23
author: Nathan
email: nesquena@gmail.com
categories: Update
tags: padrino, release
title: Padrino 0.10.6 - ActiveSupport 3.2, MiniRecord, HTML5 Helpers and bug fixes
---

For the last few months, our team has been quite busy so there has been less activity then usual on the Padrino codebase. The other reason for this is that as we have continued to stabilize the scope and the core code, there has been less need for urgent changes. Our core team uses Padrino for most of our projects and Padrino continues to serve as a stable foundation for our applications.

Still, with the [official release of ActiveSupport 3.2](http://weblog.rubyonrails.org/2012/1/20/rails-3-2-0-faster-dev-mode-routing-explain-queries-tagged-logger-store), several contributions to our codebase and some useful bug fixes, we figured the time had come for a new release. Today, we are announcing the release of Padrino 0.10.6 with ActiveSupport 3.2 compatibility, MiniRecord generator support, HTML5 Helpers, along with many compatibility upgrades and bug fixes. Full details for this release are below.

<break>

## ActiveRecord and ActiveSupport 3.2 Upgrade

We have upgraded Padrino to use [ActiveSupport 3.2](:http://weblog.rubyonrails.org/2012/1/20/rails-3-2-0-faster-dev-mode-routing-explain-queries-tagged-logger-store) and to enable support for ActiveRecord 3.2. We believe that Padrino should support the latest version of these components as they become officially available. There shouldn’t be any breaking changes between ActiveRecord 3.1 and the new version release.

## MiniRecord Generators

In this release, we have added generators for the excellent [MiniRecord](https://github.com/DAddYE/mini_record) gem created by Padrino core team member DAddYE. MiniRecord is a gem that makes working with ActiveRecord much easier including automatic migrations and schema definitions in the model themselves. Commit [here](https://github.com/padrino/padrino-framework/commit/eb9952f31cb1e5aa1aef0a0f27e1d2cdf7091ddf).

## HTML 5 Helpers

[Cirex](https://github.com/Cirex) contributed many useful HTML5 Helper changes including support for `number_field`, `telephone_field`, `email_field`, `search_field`, and `url_field`! He also cleaned up the apis for `tag` and `content_tag` for better HTML5 support. The changes shouldn’t break existing applications.

-   Helpers for tag and content\_tag are now HTML5 friendly: [commit](https://github.com/padrino/padrino-framework/commit/653e57bab171ac08495db55bf50b7c91b7758fd1)
-   Support HTML5 based tags for helpers: [commit](https://github.com/padrino/padrino-framework/commit/0327c97162eadf43809ad57b9eccd9949efd4b94)
-   Added support for a few of the new HTML 5 form inputs: [commit](https://github.com/padrino/padrino-framework/commit/31c95d95daa46b1530680b5ceb2d0a52d9423606)

Thanks to [Cirex](https://github.com/Cirex) for putting these together! Check out the [Application Helpers](http://www.padrinorb.com/guides/application-helpers) guide for details about these HTML5 inputs.

In addition [fnordfish](https://github.com/fnordfish) added support for hash options for tags. For instance:

    tag(:div, :data => {:dojo => {:type => 'dijit.form.TextBox', :props => 'readOnly: true'}})

Now properly sets up the **data-dojo-type** and the **data-dojo-props** attributes on a tag. Thanks to [fnordfish](https://github.com/fnordfish): [commit](https://github.com/padrino/padrino-framework/commit/21312fe8e797cf54b2a879d67337c8ef4971f57a), [commit](https://github.com/padrino/padrino-framework/commit/a7af2e0967890229b58b2552b13a5da9f684b0bb)

## Logging

One of our core team members, [skade](https://github.com/skade) has introduced changes to the logger to allow for custom loggers in a much easier way! Now, you can use a custom logger simply by re-assigning the logger to your own logging instance:

    # app/app.rb
    Padrino.logger = Lumberjack::Logger.new
    Padrino.logger.colorize!
    Padrino.logger.debug("Hooray, a colorized Lumberjack logger!")

By default the Padrino logger should work as expected. Commit [here](https://github.com/padrino/padrino-framework/pull/736/files), [here](https://github.com/padrino/padrino-framework/commit/16fa20f872a16272947e7ef9d542545af4b841f0).

## Component Upgrades

-   Adds [Trinidad](http://thinkincode.net/trinidad) support to `padrino start` for use with JRuby applications, [commit](https://github.com/padrino/padrino-framework/commit/ef6b964c88d52d6cdad3e64230ce9e6373a4c0f6) Thanks [skade](https://github.com/skade).
-   Use latest datamapper version (v1.2): [commit](https://github.com/padrino/padrino-framework/commit/f0eef1fab8dbe4a55a049e994b5584645c6f873c)
-   Changes Sequel to use new migration style: [commit](https://github.com/padrino/padrino-framework/commit/74c175765955418da5c93c98f8c5a1a992650b04), Thanks [funny-falcon](https://github.com/funny-falcon).
-   Removes incorrect require when using AR with pg gem: [commit](https://github.com/padrino/padrino-framework/commit/5a9a07813abb042ce779d7fbd85b5418d31ef778), Thanks [udzura](https://github.com/udzura).
-   Fixes error with less component: [commit](https://github.com/padrino/padrino-framework/commit/5be90e2cc16ff8abcacf6c94ef9e7abc89c30c58), Thanks [commit](https://github.com/padrino/padrino-framework/commit/5be90e2cc16ff8abcacf6c94ef9e7abc89c30c58)
-   Writes css into the correct public stylesheets path,

## Bug Fixes and Miscellaneous

-   Fixes issues with the routes after the reloader: [commit](https://github.com/padrino/padrino-framework/commit/7844404d1bed5f3c5258004c2587baf381d45d96)
-   Use binread for file cache on 1.9.X: [commit](https://github.com/padrino/padrino-framework/commit/0de43dc91466becfd687a3fdd00ca0084a1482b9)
-   Added setting to change model name for admin: commit [here](https://github.com/padrino/padrino-framework/commit/f2b7d0cd92b12e3c3c16924a6475eb0c64700e7a), [here](https://github.com/padrino/padrino-framework/commit/92d20d7e4800475c2fa595bbba11dff62a4136ec) and [here](https://github.com/padrino/padrino-framework/commit/c576619172221819fcc1d2fe2235e0339a9276ad), Thanks [aereal](https://github.com/aereal)
-   Adds regexp route generation support: [commit](https://github.com/padrino/padrino-framework/commit/98ce668166b26b091010fdfdc728d0887ef41f2d), Thanks [joshbuddy](https://github.com/joshbuddy)
-   Translation fixes: commits [here](https://github.com/padrino/padrino-framework/commit/bd24d1931f7562a5318fe88a941411fa3a7cf32d), [here](https://github.com/padrino/padrino-framework/commit/9543dee94917e37093b7e8b6f8a8316ac17fe848), and [here](https://github.com/padrino/padrino-framework/commit/5654a5bf06e0196ba27a08bfad75fea1735d7f6e)
-   Set PADRINO\_LOG\_LEVEL constant by default: [commit](https://github.com/padrino/padrino-framework/commit/1a4184205679d7a28bcb5fead15f002ce9e68ad3), Thanks [marcosdsanchez](https://github.com/marcosdsanchez)
-   Fix app.app\_name is not set error in padrino-cache: [commit](https://github.com/padrino/padrino-framework/commit/8522841f88557c6746ab950f41d194781573c7a0), Thanks [modeverv](https://github.com/modeverv)
-   Mailer generator now handles hyphens: [commit](https://github.com/padrino/padrino-framework/commit/e63dfeef69c4275f28c44b9393ef9a6190216863)
-   Replace Sinatra quote with Godfather movie reference on server exit: [commit](https://github.com/padrino/padrino-framework/commit/245d59f25a44ea9c2400778492840df4d8d80ba6), Thanks [danishkhan](https://github.com/danishkhan)
-   Correctly parse arguments to padrino binary: [commit](https://github.com/padrino/padrino-framework/commit/bb0c7fc4f5e9f5f639d30a2d3ce8f40c1ad32d80)
-   Cache now stores response and content\_type: [commit](https://github.com/padrino/padrino-framework/commit/8f746e0ec8e9225400efaf4cf3b1c86c20011c82), Thanks [sumskyi](https://github.com/sumskyi)

That concludes the changelog for this release. As always if you want to keep up with Padrino updates, be sure to follow us on twitter: [@padrinorb](http://twitter.com/#!/padrinorb), join us on IRC at “\#padrino” on freenode or [open an issue](https://github.com/padrino/padrino-framework/issues) on GitHub.