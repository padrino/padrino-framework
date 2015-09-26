---
date: 2010-03-01
author: Nathan
email: nesquena@gmail.com
title: Home
---

Padrino is a Ruby framework built upon the excellent [Sinatra](http://www.sinatrarb.com/) web library. Sinatra is a DSL for creating simple web applications in Ruby with minimal effort. This framework makes it as fun and easy as possible to code increasingly advanced web applications by enhancing Sinatra while staying true to the spirit that makes it great.

 

## Features

Here is a list of major functionality Padrino provides on top of Sinatra:

||
|**Agnostic:**|Full support for many popular testing, templating, mocking, and database libraries.|
|**Generators:**|Create Padrino applications, models, controllers i.e: `padrino g project`.|
|**Mountable:**|Unlike other ruby frameworks, principally designed for mounting multiple apps.|
|**Routing:**|Full url named routes, named params, respond\_to support, before/after filter support.|
|**Tag Helpers:**|View helpers such as: `tag`, `content_tag`, `input_tag`.|
|**Asset Helpers:**|View helpers such as: `link_to`, `image_tag`, `javascript_include_tag`.|
|**Form Helpers:**|Builder support such as: `form_tag`, `form_for`, `field_set_tag`, `text_field`.|
|**Text Helpers:**|Useful formatting like: `relative_time_ago`, `js_escape_html`, `sanitize_html`.|
|**Mailer:**|Fast and simple delivery support for sending emails (akin to ActionMailer).|
|**Admin:**|Builtin Admin interface (like Django).|
|**Caching:**|Simple route and fragment caching to easily speed up your web requests.|
|**Logging:**|Provide a unified logger that can interact with your ORM or any library.|
|**Reloading:**|Automatically reloads server code during development.|
|**Localization:**|Full support of I18n||

 

## Guides

When getting started with Sinatra or Padrino for the first time, we recommend that you check out the [Getting Started](/guides/getting-started) guide which provides an overview of the rest of our resources. Also be sure to check out the [Blog Tutorial](/guides/blog-tutorial) for a step-by-step walkthrough of building your first Padrino project.

Padrino consists of multiple modules which enhance Sinatra in different ways. The major components are described in detail below:

-   [Getting Started](/guides/getting-started)
-   [Generators](/guides/generators)
-   [Application Helpers](/guides/application-helpers)
-   [Controllers and Routing](/guides/controllers)
-   [Development and Terminal Commands](/guides/development-commands)
-   [Mounting Sub-applications](/guides/mounting-applications)
-   [Delivering Mail](/guides/padrino-mailer)
-   [Admin and Authentication](/guides/padrino-admin)
-   [Site Caching](/guides/caching-support)

Note that as a user of Padrino, each of the major components can be used [standalone](/guides/standalone-usage-in-sinatra) in an existing Sinatra application or used together for a full-stack Padrino project.

These guides should provide a pretty good overview but if you have any questions be sure to contact us: [@padrinorb](http://twitter.com/#!/padrinorb), discuss things on the [google groups](https://groups.google.com/forum/?hl=en#!forum/padrino), join us on freenode IRC at “\#padrinorb” or [open an issue](https://github.com/padrino/padrino-framework/issues) on GitHub.
