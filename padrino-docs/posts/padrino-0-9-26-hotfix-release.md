---
date: 2011-04-28
author: Nathan
email: nesquena@gmail.com
categories: Update
tags: padrino, sinatra, ruby
title: Padrino 0.9.26 - Hotfix Release
---

We recently released [0.9.25](http://www.padrinorb.com/blog/padrino-0-9-25-slim-and-erubis-caching-and-fixes) which was a milestone release with many significant improvements. Unfortunately, we let a few serious bugs slip into the release as well, so a hotfix release is required.

Before going into the fixes, just want to also preface with the fact that we are taking steps to make sure future releases are better tesed. First, we used to have a CI server but the server was no longer available so we have setup a new Hudson CI server to guarantee that a release works on a variety of ruby versions and platforms. Second, we are going to do a better job of testing edge releases on our applications before released. It is important to us that each release is rock-solid before we push that out to rubygems.

A breakdown of the details of this hotfix release is in the details.

<break>

There are several fixes that went into this release to patch issues users were experiencing after an upgrade:

**HTTPRouter**

There were a [couple](https://github.com/padrino/padrino-framework/issues/496) [issues](https://github.com/padrino/padrino-framework/issues/495) with http\_router that were causing installation and usage issues on certain platforms. This has been fixed [here](https://github.com/padrino/padrino-framework/commit/a616af1853719b0d7bd23d2f47f88810d77f220d) by using the upgraded version. Thanks Josh!

**Mongoid Rake Tasks**

We had accidentally borked the mongoid rake tasks that come as part of Padrino, with a ‘gsub gone wrong’. bernerdschaefer:“https://github.com/bernerdschaefer” quickly identified and corrected the issue [here](https://github.com/padrino/padrino-framework/commit/8978c8c75ed84d2799dfe60805eda4ab1fa56df4). Thanks!

**Shared Sessions**

We have made several session security improvements in the last release but also inadvertently broke shared sessions between applications in a project. This was quickly identified and fixed [here](https://github.com/padrino/padrino-framework/commit/ef40aa09d2568446dfff3a3c15c91712e1076ffa).

**Development Reloader**

Patches to enhance the development reloading capabilities also inadvertently broke reloading in some cases. This was fixed [here](https://github.com/padrino/padrino-framework/commit/8fe18e8b0bf1f95769e9ee8538c332da1762749d) and should be working as usual.

**Compliance with Rack::CommonLogger**

Small update, we have made our logging functions compliant with rack commonlogger, by adding a ‘write’ method [here](https://github.com/padrino/padrino-framework/commit/ab1e61e39b3ed54a67bf80a70a182371d633bf30) which was identified by Alex Sharp. Thanks!

**Cache Installation**

On Windows, users were [reporting](https://github.com/padrino/padrino-framework/issues/491) that installing the cache gem didn’t work. This was an easy issue to resolve “here”: and now installation should work as expected.

**Test Generation**

We have improved test generation to allow the various sub-apps in a project to have isolated testing environments. If you have three apps `app1`, `app2`, and `app3` in a project, you can now do:

    # Run all tests
    $ padrino rake test
    # Run tests for app 1
    $ padrino rake test:app1
    # Run tests for app 2
    $ padrino rake test:app2

When tests are generated for an application, they are now separated into application-specific folders such as:

test/app1
 test/app2
 test/app3

Allowing more granular and isolated testing of each application.

Be sure to upgrade from 0.9.25 to 0.9.26 as soon as possible. If you are experiencing issues please [let us know](https://github.com/padrino/padrino-framework/issues) on the issue tracker.