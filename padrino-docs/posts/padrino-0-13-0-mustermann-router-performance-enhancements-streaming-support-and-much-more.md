---
date: 2015-10-12
author: Nathan Esquenazi
email: nesquena@gmail.com
categories: Ruby, Update
tags: padrino, sinatra, ruby
title: Padrino 0.13.0 - Mustermann Router, Performance Enhancements, Streaming Support, and Much More
---

                    Padrino 0.12.4 was shipped on October 19th 2014. Hard to believe that just about a year has flown by since then as we have been working towards our next major release of Padrino. While there have been betas available for some time, we are excited to announce the final release of Padrino 0.13.0! This version has a huge host of improvements and upgrades, both big and small.

This 0.13.0 release brings several major changes and updates including a completely redesigned router, significant performance enhancements, streaming support, bug fixes and a ton of code cleanup. Full details for this release are below. You should also check out the [0.13.0 upgrade guide](http://www.padrinorb.com/blog/upgrading-padrino-from-0-12-x-to-0-13-0-guide) as well for a detailed look at moving up from 0.12.X.

Redesigned Mustermann Router
----------------------------

One of the big changes in this release was the retirement of [http_router](https://github.com/joshbuddy/http_router) which is no longer being maintained. We have switched to a brand new router written by [@namusyaka](https://github.com/namusyaka). The older router had accrued significant technical debt with many hacks and workarounds introduced along with thread-safety issues. We’ve been working on this redesigned router for quite sometime, running [router benchmarks](https://github.com/padrino/padrino-framework/pull/1692) and making sure we took our time to ensure a smooth replacement. We are proud to unveil the new router with this release and you can [read more details in this PR](https://github.com/padrino/padrino-framework/pull/1800).

Project-wide Configuration
--------------------------

With 0.13.0 comes project-wide global configuration options with environment support. This is inspired by the Sinatra configuration system but is project-wide rather than app-specific. Configuration can be done anywhere in your project including `config/apps.rb`:

```ruby
Padrino.config.value1 = 42

Padrino.configure :development do |config|
  config.value2 = ‘only development’
end

Padrino.configure :development, :production do |config|
  config.value2 = ‘both development and production’
end

Padrino.configure do |config|
  config.value2 = ‘any environment’
end
```

and then these values can be accessed with:

~~~~ {lang="ruby"}
Padrino.config.value1 # => 42
Padrino.config.value2 # => 'any environment'
~~~~

Thanks to [@ujifgc](https://github.com/ujifgc) for implementing this. More details can [be found in the PR](https://github.com/padrino/padrino-framework/pull/1909).

Sinatra Upgrades
----------------

In this release, we have upgraded Sinatra to the latest 1.4.6 release which allowed us to clean up several previous workarounds. The result is an even cleaner integration with Sinatra. This includes the following Sinatra compatibility improvements:

* FIX [Remove temporary `show_exceptions` code](https://github.com/padrino/padrino-framework/pull/1899) 
* FIX [#1867](https://github.com/padrino/padrino-framework/issues/1867) Update ShowExceptions to suit latest rack master ([@namusyaka](https://github.com/namusyaka)) 
* FIX [#1950](https://github.com/padrino/padrino-framework/issues/1950) Padrino now follows Sinatra’s charset policy ([@ujifgc](https://github.com/ujifgc)) 
* FIX [Sinatra async streaming callbacks](https://github.com/padrino/padrino-framework/issues/1704) 
* FIX [#1880](https://github.com/padrino/padrino-framework/issues/1880) rendering issue by accepting string content types ([@ujifgc](https://github.com/ujifgc)) 
* FIX [#1942](https://github.com/padrino/padrino-framework/issues/1942) maintain Sinatra params indifference ([@ujifgc](https://github.com/ujifgc))

We are committed to compatibility with our Sinatra core and this release marks a solid step forward in that regard.

Component Updates
-----------------

There are several component updates and tweaks in this release including but not limited to:

* NEW [#1133](https://github.com/padrino/padrino-framework/issues/1133) switch default renderer to none ([@ujifgc](https://github.com/ujifgc)) 
* FIX Update [rack-test to 0.6.3](https://github.com/padrino/padrino-framework/commit/1a3b2644413cdb865c8f93d26e35af135c5d562a) and remove old patch ([@ujifgc](https://github.com/ujifgc)) 
* NEW [#1908](https://github.com/padrino/padrino-framework/issues/1908) Adds test-unit as a test component ([@namusyaka](https://github.com/namusyaka)) 
* FIX [#1932](https://github.com/padrino/padrino-framework/issues/1932) Replace ConnectionManagement with ConnectionPoolManagement ([@namusyaka](https://github.com/namusyaka)) 
* NEW [#1940](https://github.com/padrino/padrino-framework/issues/1940) Add IdentityMap middleware to datamapper ([@namusyaka](https://github.com/namusyaka)) 
* FIX [#1895](https://github.com/padrino/padrino-framework/issues/1895) Use compass-blueprint gem for improved compass generator ([@myokoym](https://github.com/myokoym))

Performance Improvements
------------------------

We are committed to making Padrino as lightweight and comparable to raw Sinatra speed as possible. In that vein, we have made the following improvements:

* NEW [#1857](https://github.com/padrino/padrino-framework/issues/1857) Precompile routes when loading Padrino ([@namusyaka](https://github.com/namusyaka)) 
* FIX [#1792](https://github.com/padrino/padrino-framework/issues/1792) Faster code using reverse_each to iterate gems ([@glaucocustodio](https://github.com/glaucocustodio)) 
* FIX [#1793](https://github.com/padrino/padrino-framework/issues/1793) Faster codeusing #sub instead of #gsub ([@glaucocustodio](https://github.com/glaucocustodio)) 
* FIX [#1959](https://github.com/padrino/padrino-framework/issues/1959) simplify the mounter class ([@dnesteryuk](https://github.com/dnesteryuk)) 
* FIX [#1891](https://github.com/padrino/padrino-framework/issues/1891) Refactorings for more reliable dependency loading ([@hcatlin](https://github.com/hcatlin), [@namusyaka](https://github.com/namusyaka))

We’ve also introduced a benchmark test suite to test speed for padrino core and router:

- NEW [#1966](https://github.com/padrino/padrino-framework/issues/1966) sample benchmark test of padrino core ([@ujifgc](https://github.com/ujifgc))

This should help us in making continued improvements going forward.

Bug Fixes and Misc Improvements
-------------------------------

A full list of other changes can be [found on Github](https://github.com/padrino/padrino-framework/compare/0.12.5...0.13.0) but an abridged version has been appended below:

-   FIX [#1614](https://github.com/padrino/padrino-framework/issues/1614) Do not search for caller in bundler lib ([@ujifgc](https://github.com/ujifgc))
-   FIX [#1796](https://github.com/padrino/padrino-framework/issues/1796) Save and restore layout setting on render ([@ujifgc](https://github.com/ujifgc))
-   FIX [#1965](https://github.com/padrino/padrino-framework/issues/1965) Fail properly on wrong mailer name or message ([@ujifgc](https://github.com/ujifgc))
-   FIX [#1916](https://github.com/padrino/padrino-framework/issues/1916) Check key existence on caching ([@namusyaka](https://github.com/namusyaka))
-   NEW [#1919](https://github.com/padrino/padrino-framework/issues/1919) allow configuring log file path
-   FIX [#1931](https://github.com/padrino/padrino-framework/issues/1931) render partials in mail if padrino-helpers is available ([@ujifgc](https://github.com/ujifgc))
-   FIX [#1829](https://github.com/padrino/padrino-framework/issues/1829) add absolute_url to app methods, add :base_url setting ([@ujifgc](https://github.com/ujifgc))
-   NEW [#1898](https://github.com/padrino/padrino-framework/issues/1898) Adds missing helpers for the input html element ([@namusyaka](https://github.com/namusyaka))
-   FIX AWS namespace in Dynamoid component ([@namusyaka](https://github.com/namusyaka))
-   FIX Root index route incorrectly matches single-character URLs ([@namusyaka](https://github.com/namusyaka))
-   NEW [#1929](https://github.com/padrino/padrino-framework/issues/1929) Alias db:migrate:down and db:migrate:up when using datamapper ([@postmodern](https://github.com/postmodern))
-   FIX Restore AbstractFormBuilder#field_human_name ([@namusyaka](https://github.com/namusyaka))
-   FIX [#1936](https://github.com/padrino/padrino-framework/issues/1936) Don’t echo password input ([@namusyaka](https://github.com/namusyaka))
-   FIX Cache test for moneta ([@ujifgc](https://github.com/ujifgc))
-   FIX [#1943](https://github.com/padrino/padrino-framework/issues/1943) Issue with format provides in controller with wildcard accepts header ([@ujifgc](https://github.com/ujifgc))
-   FIX properly reload classes without instances ([@ujifgc](https://github.com/ujifgc))
-   FIX [#1922](https://github.com/padrino/padrino-framework/issues/1922) consider methodless constants not external ([@ujifgc](https://github.com/ujifgc))
-   NEW [#1853](https://github.com/padrino/padrino-framework/issues/1853) Adds wrapper for application which allows better extensibility ([@namusyaka](https://github.com/namusyaka))
-   NEW Remove deprecated cache functionality ([@minad](https://github.com/minad))
-   FIX [#1772](https://github.com/padrino/padrino-framework/issues/1772) add button content tag to button_to block ([@ujifgc](https://github.com/ujifgc))
-   FIX [#1795](https://github.com/padrino/padrino-framework/issues/1795) load missing models for sq:seed ([@ujifgc](https://github.com/ujifgc))
-   NEW Use mustermann19 in all cases now ([@namusyaka](https://github.com/namusyaka))
-   FIX [#1803](https://github.com/padrino/padrino-framework/issues/1803) Use relative paths for sqlite and sequel ([@ujifgc](https://github.com/ujifgc))
-   FIX [#1821](https://github.com/padrino/padrino-framework/issues/1821) Don’t load dependency files unless app’s root is within Padrino root ([@namusyaka](https://github.com/namusyaka))
-   FIX [#1835](https://github.com/padrino/padrino-framework/issues/1835) Switch admin to sequel fixtures rather than datamapper ([@namusyaka](https://github.com/namusyaka))
-   FIX Widen the range of `default_dependency_paths` ([@namusyaka](https://github.com/namusyaka))
-   NEW [#1831](https://github.com/padrino/padrino-framework/issues/1831) Implement the `mi:translate` task ([@namusyaka](https://github.com/namusyaka))
-   FIX [#1852](https://github.com/padrino/padrino-framework/issues/1852) ApplicationWrapper Prerequisite Issue ([@hcatlin](https://github.com/hcatlin))
-   FIX [#1856](https://github.com/padrino/padrino-framework/issues/1856) Skips loading models for the activerecord rake tasks ([@namusyaka](https://github.com/namusyaka))
-   NEW [#1818](https://github.com/padrino/padrino-framework/issues/1818) Implement `source_location` option for logger ([@namusyaka](https://github.com/namusyaka))
-   FIX [#1859](https://github.com/padrino/padrino-framework/issues/1859) Correct issues with the admin seeds generator ([@Quintasan](https://github.com/Quintasan))
-   FIX [#1879](https://github.com/padrino/padrino-framework/issues/1879) Improve access to Active Record Database Configuration ([@scudelletti](https://github.com/scudelletti))
-   DELETE remove deprecations (String#undent, #link_to with :fragment, old caching, old form builder, rendering #fetch_template_file, #cache_template_file!, #resolved_layout, Application#load_paths, Padrino.set_load_paths, Padrino.load_paths)
-   FIX [#1860](https://github.com/padrino/padrino-framework/issues/1860) Padrino —environment switch now takes precedence over RACK_ENV environment variable
-   FIX [#1849](https://github.com/padrino/padrino-framework/issues/1849) return proper exit codes in CLI

Want to give a special thanks to the key contributors for this release, working tirelessly to make this Padrino release happen: [@ujifgc](https://github.com/ujifgc), [@namusyaka](https://github.com/namusyaka). Thanks so much!

Please report any issues you encounter with this release! We are working very actively on Padrino and want to make the framework as stable and reliable as possible. That concludes the changelog for this release. As always if you want to keep up with Padrino updates, be sure to follow us on twitter: [@padrinorb](http://twitter.com/#!/padrinorb), join us on IRC at “#padrino” on freenode or [open an issue](https://github.com/padrino/padrino-framework/issues) on GitHub.
