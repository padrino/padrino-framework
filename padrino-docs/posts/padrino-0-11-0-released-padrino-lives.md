---
date: 2013-03-10
author: DAddYE
email: d.dagostino@lipsiasoft.com
categories: Update
tags: ruby, sinatra, padrino, release
title: Padrino 0.11.0 Released - Padrino Lives!
---

The Padrino team is very pleased to finally be able to announce the 0.11.0 release of the Padrino Framework! We have been working on this release for almost a year now and we have had dozens of contributors helping us stabilize Padrino. We know our release cycle got out whack and this version took too long to release. We all take accountability for that and will work to pick up release momentum and release patch and minor versions more often.

Since our 0.10.7 release, development on Padrino has been moving forward very actively and as such this is probably our biggest release in terms of code modified and issues resolved that we have had in years. We are very proud of this release which includes several major improvements:

1) Totally Redesigned Admin
 2) New brand identity on the way
 3) Upgraded Sinatra and http\_router
 4) CSRF Form Protection
 5) ActiveSupport::SafeBuffer
 6) New Rakefile format
 7) Gemified Apps
 8) Performance Tools
 9) App Namespacing
 10) Project Modules
 11) Optimized Reloader

and a lot more changes! In the full post below, we will take you through a tour of the biggest changes in this release (for a more compact view, see our [changelog](http://www.padrinorb.com/changes)).

<break>

## Redesigned Admin

We have introduced a number of exciting improvements to admin in this release. First, with the help of [@WaYdotNET](https://github.com/WaYdotNET), we have completely rewritten the admin interface front-end. The new front-end uses bootstrap, font-awesome and jquery. A few commits: [1](https://github.com/padrino/padrino-framework/commit/3f62f747f03991e0bb6ad9774dd3ebacfe73a23c), [2](https://github.com/padrino/padrino-framework/commit/d6afa8febdc3dcdf1bc61668084cd66290ad4390)

This snowballed into a huge team effort so thanks to everyone involved [@WaYdotNET](https://github.com/WaYdotNET), [@DAddYE](https://github.com/DAddYE), [@dariocravero](https://github.com/dariocravero)), [@ujifgc](https://github.com/ujifgc), [@tyabe](https://github.com/tyabe) and several others! Here’s a few screenshots of our brand new admin pages:

[![](http://i.imgur.com/DUO2SfU.png)](http://i.imgur.com/DUO2SfU.png) [![](http://i.imgur.com/QDAl4nu.png)](http://i.imgur.com/QDAl4nu.png)"
 [![](http://i.imgur.com/hPiOYqi.png)](http://i.imgur.com/hPiOYqi.png) [![](http://i.imgur.com/vcA6ZPV.png)](http://i.imgur.com/vcA6ZPV.png)"

See more images in the [Padrino Admin Album](http://imgur.com/a/gimrX)! Note that the new Padrino Admin has a responsive design that behaves well on tablets and mobile devices. Now you can even manage your admin data from your iPad!

There were also several additional fixes for admin listed below:

-   Get the first key passed to expire helper. [commit](https://github.com/padrino/padrino-framework/commit/04d26c4a696e9eb50e247e308fad1d62d7ba7198) (Thanks [@gugat](https://github.com/gugat))
-   Fixes model output in erb templates. [commit](https://github.com/padrino/padrino-framework/commit/53358f588ed49d8838dc0082e30b2dcca36310ba) (Thanks [@sleepingstu](https://github.com/sleepingstu))
-   Halting page with 404 if record is not found [commit](https://github.com/padrino/padrino-framework/commit/a7b6b69ce9f309e3e8616b3ad2c8f561590f5170) (Thanks [@kot-begemot](https://github.com/@kot-begemot))
-   Cleanups to admin documentation. [commit](https://github.com/padrino/padrino-framework/commit/21146f6ffbedcce89b4ae23c48bba7c1bf8edc42) (Thanks [@danieltahara](https://github.com/danieltahara))
-   Fixes CSS Errors on admin pages. [commit](https://github.com/padrino/padrino-framework/commit/f5301722562972fd939dd2689549cbbd59c49a20) (Thanks [@dariocravero](https://github.com/dariocravero))
-   A lot more commits, this was a huge effort!

## New brand identity on the way

We have started to rebrand ourselves, thanks to [@tomatuxtemple](https://github.com/tomatuxtemple) we are getting there!.. Welcome the new logo:

[![](http://i.imgur.com/X7n3Kdo.png)](http://i.imgur.com/X7n3Kdo.png)

The new web experience is just around the corner too, so keep your eyes and ears wide open!

## Upgraded Sinatra and http\_router

[Sinatra 1.4](http://rkh.im/sinatra-1.4) was just released recently, and we have full support for Sinatra 1.4.X in this release. Commits: [1](https://github.com/padrino/padrino-framework/commit/68e58b4609ec528fc0ea9f8f95ace36dec9b2920), [2](https://github.com/padrino/padrino-framework/commit/ba2cfcdeb1c4428cc19013d09ba05f1383455360), [3](https://github.com/padrino/padrino-framework/commit/15927ecb172f99fca56d243d331729b9194daa91), [4](https://github.com/padrino/padrino-framework/commit/181b844ab93914c88bfd908a5eefe8b67d2aaeef), [5](https://github.com/padrino/padrino-framework/commit/777ee25223a1998f616d648a932d85f94cf199dc)

We have also upgraded to the latest [http\_router 0.11](https://github.com/joshbuddy/http_router) to address many thread-safety issues and overall performance improvements.

Thanks to [@DAddYE](https://github.com/DAddYE) for putting together the http\_router upgrade to 0.11. Commits: [1](https://github.com/padrino/padrino-framework/commit/c2b56c47b15334f3c3839e4f3614669c1fdc33e2)

## CSRF Protection

Padrino now supports [CSRF protection](http://en.wikipedia.org/wiki/Cross-site_request_forgery) out of the box to enable additional security protection against unauthorized commands being sent to a Padrino application.

Thanks to [@skade](https://github.com/skade) and [@dariocravero](https://github.com/dariocravero) for working together to implement this security feature. Commits: [1](https://github.com/padrino/padrino-framework/commit/3767875ad450ea63f34f26fca0e3646c50f4e802), [2](https://github.com/padrino/padrino-framework/commit/3afb1070ce83a9daccfa40fef8d8c1655c68a103), [3](https://github.com/padrino/padrino-framework/commit/d7f719db9f6f863811c22978ba1329645e828ccb), [4](https://github.com/padrino/padrino-framework/commit/b6ddd1617c9f81868c747bd28edaf35ed1951a6a), [5](https://github.com/padrino/padrino-framework/commit/3f52b59b3b93278346b5c8cc5c98876ec1c78a17)

## ActiveSupport::SafeBuffer

In Padrino 0.11.0, we have begun work on improving the security of Padrino out of the box. We all take app security very seriously, and after much discussion decided to introduce a SafeBuffer into Padrino. This will help protect users against [XSS (Cross-site Scripting) attacks](http://en.wikipedia.org/wiki/Cross-site_scripting).

This change switches all rendering to use SafeBuffer instead of a raw string. All strings returned from \#render are considered escaped. Strings can be marked safe for concatenation using String\#html\_safe, which turns returns the String as a SafeBuffer.

All helpers have been ported over to use SafeBuffers. The changes follow one general rule: all tag helpers like tag and content\_tag escape everything by default while block helpers like content\_for and form\_for assume that the given content is already escaped.

If you are generating HTML in your helpers, you should now make sure that you call `html_safe` on the result, so that the HTML is not automatically escaped:

    def my_helper
      "<p>hello!</p>".html_safe
    end

Thanks to [@skade](https://github.com/skade) for proposing and putting this together! See commits here: [1](https://github.com/padrino/padrino-framework/commit/2c89e1fc7b70c4906b291b3781908c02a0d1233e), [2](https://github.com/padrino/padrino-framework/commit/3a00f4bf03f98d39a026fbfd348b82daacb26dad), [3](https://github.com/padrino/padrino-framework/commit/87049be0e30d101bc02a4bca4d7df50e32f32ebf), [4](https://github.com/padrino/padrino-framework/commit/0f179db270089c047736ccae33433f5d6d2ad304)

This is a direct port of the functionality present in Rails, so thanks to the whole Rails team as well.

## New Rakefile format

Another source of frustration for users was the missing `Rakefile`: now, every new project has one by default. \`padrino rake\` still continues to work, but bare \`rake\` works just as nice as well. Also, the Rakefile format has changed: instead of implicitly loading rake tasks that fit your environment, this is now explicit and looks like this:

    require 'padrino-core/cli/rake'
    PadrinoTasks.use(:sequel)
    PadrinoTasks.use(:database)
    PadrinoTasks.init

This makes it easier to replace tasks you don’t want to use and leads to less guessing by the framework. Don’t like our `database` tasks? Just erase that line. Want to use them again? Just put it back in.

Old Rakefiles still work, but will emit a very visible warning on how to change your Rakefile to the new format. Thanks to [@skade](https://github.com/skade) for putting this together!

## Gem-ified Apps

An often requested feature for Padrino is the ability to easily package a Padrino application as a gem. We have now baked this right into the project generator. If you want to generate an application for use as a gem, we will automatically generate the gem and project structure for you! Simply add the `--gem` flag when generating a project:

    padrino g project my_gemified_app --gem

This will generate a Padrino project within the context of a gem structure for you automatically. Now you can publish your Padrino apps as standalone gems with ease. After generation, see the README for more information about how to mount your gem-ified into Padrino projects.

A gemified project can be started and used like any other padrino project from its root path:

    padrino start

But also be included into another project using the `Gemfile`. For development, you can use the `:path` option and the project will also be reloaded:

    gem 'my_gemified_app' #, :path => /path/to/my_gemified_app

You can mount apps from other projects like so:

    Padrino.mount('MyFancyApp::App', :app_file => MyGemifiedApp.root("my_fancy_app", "app.rb")).to('/my_fancy_app')

This is an exciting step for Padrino and creating truly standalone and modular applications that can be easily installed, setup and mounted into an existing Project. We have more plans for this as we approach towards 1.0.

Nothing keeps you from generating your main project as gemified project: there is nothing special about them, gemified projects behave like normal projects with some additions.

Thanks to [@skade](https://github.com/skade) for putting this together! See commits here: [1](https://github.com/padrino/padrino-framework/commit/2975efa8a6f395b9075b1a7e939fff70412d8e91), [2](https://github.com/padrino/padrino-framework/commit/e470a20f76ed07a218815ba2850a084eae1b8f6a), [3](https://github.com/padrino/padrino-framework/commit/af1efbf18861fb21660481e29821465fa54e4dd8), [4](https://github.com/padrino/padrino-framework/commit/88d575f5404abcfb77c32d9c3df43e46e0399a22), [5](https://github.com/padrino/padrino-framework/commit/74fdf09ea18bbaff25d6a4661a2cc1c6f8b1d7f5)

## Performance Tools

In this release, we have also introduced a `padrino-performance` gem optionally included as part of your Padrino application. Simply add `padrino-performance` to your Gemfile. You can use the performance gem to check for well-know errors like multiple loaded json libraries on the console with:

    bundle exec padrino-performance -j -- bundle exec padrino console

or profile the memory for your application:

    bundle exec padrino-performance -m -- bundle exec padrino start

This represents the first step for our built-in memory and performance profiler within Padrino. This will get more love as we approach and move into our 1.0 release. We take performance and memory usage very seriously and are always striving to keep Padrino as lightweight as possible in line with our fast Sinatra foundations.

Thanks to [@skade](https://github.com/skade) and [@dariocravero](https://github.com/dariocravero) for working together to get this to a solid place. You can find more details about this on the [README](https://github.com/padrino/padrino-framework/tree/master/padrino-performance) and [PR](ttps://github.com/padrino/padrino-framework/pull/1027)

## App Namespacing

In addition to supporting gem-ified Padrino application, we have also taken another step towards modular design by introducing app namespacing. In the past, if a Padrino project was generated with the name “sample\_blog”, then the application name would just be `SampleBlog`.

Starting with 0.11.0, generated project now have namespaced apps within a module. For example, if you generate a Padrino project named “sample\_blog” with:

    padrino g project sample_blog --orm activerecord

The primary app file will still be located in “app/app.rb” but the class will be `SampleBlog::App`. Similarly, everything else has been changed to support the namespacing to allow a project to be roughly self-contained within a single namespace.

One caveat is that to avoid any issues with various ORMs, models are **not generated** within the app namespace. Models will be continued to be generated outside of any namespace for simplicity.

Thanks to [@achiu](https://github.com/achiu) and Thanks to [@skade](https://github.com/skade) for working together to finalize this and make this compatible with the new app gem support introduced as well.

## Project Modules

Along with gemified apps, a new feature entered padrino-core: Project Modules. Those allow projects to live somewhere else then the applications root path and are a simple, yet powerful way of modularization. Project modules are tracked by the reloader and thus easy to use during development. A project module for a gemified app looks like this:

    require 'padrino-core'
    module GemifiedProject
      extend Padrino::Module
      gem! "gemified_project"
    end

A project module will have its own root, so if you want to safely generate a path inside a gemified app, you should use the project module instead of `Padrino`:

    GemifiedProject.root("config", "database.rb")

Project Modules, like `Padrino` have `dependency_paths` to play around with that are tracked by the reloader:

    GemifiedProject.dependency_paths << "#{MyModule.root}/uploaders/*.rb"

The nice thing is that `gem!` is only a helper that indicates that this module should be loaded from a gem, along with proper tracking of the gems root path. You can also set up your own project module by hand, if you want to use some other form of organization. Just set the `root` correctly:

    module MyProject
      extend Padrino::Module
      self.root = "/my/fixed/folder"
    end

You can use the Module for project namespacing, if you want to:

    module MyProject
      class MyModel
      end
    end

## Optimized Reloader

As many of you might know, the Padrino development reloader has been a common point of frustration and trouble for us. There is still a ways to go and we have some plans on how to replace the reloader for 1.0. Still, in 0.10.7, the reloader would in certain cases for large projects become increasingly slow. In extreme cases, reloading could take as long as 10+ seconds.

Several people helped us track this down and the reloader is substantially faster in this release. The primary fix was thanks to [@dcu](https://github.com/dcu) who helped us clean up our traversal of object space and substantially speed of the reloader in extreme cases. [commit](https://github.com/padrino/padrino-framework/commit/d9ab01665534a66b6f891a2efbc6b377c8134b76). We also fixed a thread-safety issue thanks to [@udzura](https://github.com/udzura). Thanks guys!

## Upgraded Components

Several updated components in this release:

-   Upgrade Mongoid to support 3.0. [commit](https://github.com/padrino/padrino-framework/commit/263b3edd913943e10640cf22ebdad3a25ce025b2) (Thanks [@dcu](https://github.com/dcu))
-   Fix mongoid rake tasks. [commit](https://github.com/padrino/padrino-framework/commit/3203a3c33fa9e62cdcf13cabf56e73d043c88c1a) (Thanks [@dayflower](https://github.com/dayflower))
-   Add Puma as a server handler. [commit](https://github.com/padrino/padrino-framework/commit/52545ab0e09c30b6ba5cee04488953ea02487d5c) (Thanks [@dariocravero](https://github.com/dariocravero))
-   Upgrade ActiveRecord support. [commit](https://github.com/padrino/padrino-framework/commit/39edad425018f023535f7cae7373d7a2319076d6)
-   Upgrade to mysql 2.8.1. [commit](https://github.com/padrino/padrino-framework/commit/92ec3bf8ba5f48c5b60d1182c85a47b6df21608a) (Thanks [@udzura](https://github.com/udzura)).

We are committed to keeping our support components up to date. We can always use help so pull requests welcome!

## Mailer

-   Lazy load mail gem for 20% padrino bootup speed improvement. [commit](https://github.com/padrino/padrino-framework/commit/dae883f2a6a38a0edfe00fb47eeb61fb8ffdbbf0) (Thanks [@ujifgc](https://github.com/ujifgc))
-   Upgrade to mail gem 2.5.3 to fix security vulnerabilities. [commit](https://github.com/padrino/padrino-framework/commit/0261a8ad48aee354492f713758b023fe75a80836)
-   Refactor to cleanup and DRY code. [commit](https://github.com/padrino/padrino-framework/commit/e84eb45cce7962c64c8691fca2352a3e75d6cf30) (Thanks [@Ortuna](https://github.com/Ortuna))

## Logging

-   Fix Padrino.logger thread safety issues. commits: [1](https://github.com/padrino/padrino-framework/commit/e42fc4009ef6c25baeb7afe37244143482ee8575), [2](https://github.com/padrino/padrino-framework/commit/13f466246a7538f23468a3704652c78b4567ae69), [3](https://github.com/padrino/padrino-framework/commit/dde54328d037a00afa4e28f712d0ec88c5c2fbbb) (Thanks [@sgonyea](https://github.com/sgonyea))
-   Add colorize\_logging option. [commit](https://github.com/padrino/padrino-framework/commit/14ebe6db68b91f8830fc06d63514295ef491cf88) (Thanks [@tyabe](https://github.com/tyabe)).
-   Display seconds instead of milliseconds. [commit](https://github.com/padrino/padrino-framework/commit/ca72c6ae395bbd91d28bd1bec9ecfae59b3d8171) (Thanks [@muxcmux](https://github.com/muxcmux))

## Helpers

-   Add support for HTML5 multiple files upload. [commit](https://github.com/padrino/padrino-framework/commit/26aeb430af8c62a0d14ccd768ae97d4269414468) (Thanks [@hooktstudios](https://github.com/hooktstudios))
-   Adds check\_box\_group and radio\_button\_group helpers [commit](https://github.com/padrino/padrino-framework/commit/89fabaa92b23ea1afbb88c89ecba0e2c2524442b) (Thanks [@ujifgc](https://github.com/ujifgc))
-   Adds breadcrumbs helpers. [commit](https://github.com/padrino/padrino-framework/commit/0beb004f46b84b84b43d6db5470e48dbb3ceebb9) (Thanks [@WaYdotNET](https://github.com/WaYdotNET))

## Cache Parser

We have also added a parser strategy pluggable interface for the padrino-cache. Now, you can select how the cache data is serialized into your cache store of choice. By default, we now store the data as plain text unless otherwise specified.

Example:

    Padrino.cache = Padrino::Cache::File.new(...)
    Padrino.cache.parser # => Padrino::Cache::Parser:Plain
    Padrino.cache.parser = :marshal

Or you can write your own:

    require 'oj'
    module PadrinoJSON
      def self.encode(code)
        Oj.dump(code)
      end
      def self.decode(code)
        Oj.load(code)
      end
    end

Finally you can load your strategy:

    Padrino.cache.parser = PadrinoJSON

Thanks to [@DAddYE](https://github.com/DAddYE) for putting the parsing strategy system into place. [commit](https://github.com/padrino/padrino-framework/commit/24543be6d34899c76eb6f36f62d5bc2dc7843c35)

## Bug Fixes

Lots of bug fixes and other changes in this release, see our [changelog](http://www.padrinorb.com/changes) for a full rundown.

## Explicit by default

A notable change comes in the philosophy of the framework: Instead of guessing application and task locations based on your bundle and project setup, Padrino will now use an explicit version (like setting the `:app_file` parameter for `Padrino.mount` and using `PadrinoTasks.use` in Rakefiles). This makes it far easier for users to replace them and makes it clearer what gets loaded and what doesn’t. It also avoids frustrating mis-guesses by the framework. The old ways will still work for quite a while, but we believe that less magic is the way to go in the future. This is no API change, the underlying API was always there, its just used in another way.

## Summary

As we mentioned, this is probably one of the bigger releases we have had in a long time, but we will keep the momentum moving and probably be out with a 0.11.1 release in the next couple weeks. Please let us know if you run into any problems (especially when upgrading from 0.10.X).

There are a lot of people that have made this release happen. Thanks to [@skade](https://github.com/skade), [@dariocravero](https://github.com/dariocravero), and [@ujifgc](https://github.com/ujifgc) from our core team for doing a lot of the contributions towards 0.11.0.

Special thanks to [@wikimatze](https://github.com/matthias-guenther) for cleaning up our docs and comments all over our framework and for putting together an [awesome Padrino book](https://github.com/matthias-guenther/padrino-book) that helps people learn how to use Padrino. Also special thanks to [@postmodern](https://github.com/postmodern) for helping us out recently especially when it comes to security, [@WaYdotNET](https://github.com/WaYdotNET) for being a long time contributor plus helping redesign admin and [@Ortuna](https://github.com/Ortuna) for helping us to refactor and clean up our codebase. As always, Padrino 0.11.0 would not be possible without the support of [Konstantin Haase](https://github.com/rkh) and everyone else involved in [Sinatra](https://sinatrarb.com). Thanks to all of our contributors.

That concludes the changelog for this release. As always if you want to keep up with Padrino updates, be sure to follow us on twitter: [@padrinorb](http://twitter.com/#!/padrinorb), join us on IRC at “\#padrino” on freenode or [open an issue](https://github.com/padrino/padrino-framework/issues) on GitHub.