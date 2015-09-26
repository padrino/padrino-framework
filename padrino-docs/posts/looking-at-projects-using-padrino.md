---
date: 2011-03-15
author: DAddYE
email: d.dagostino@lipsiasoft.com
categories: Update
tags: padrino, sinatra, ruby
title: Looking at Projects using Padrino
---

Padrino development has been continuing along fairly smoothly with the release 0.9.23 that supports Sinatra 1.2. The last few releases have worked through a lot of the most annoying issues that could prevent new users from getting started. We have also been updating the [guides](http://www.padrinorb.com/guides) to fix many inconsistencies.

Still, one aspect we haven’t talked about too much on our blog yet is the community around Padrino. Specifically, the applications and libraries that have been built on Padrino since the framework was released in November 2009. Recently, we created a [projects page](https://github.com/padrino/padrino-framework/wiki/Projects-using-Padrino) that provides a guide to all the Padrino applications and libraries our team knows about. This post will highlight the most interesting of these projects in more detail.

<break>

## Padrino Applications

There have been a great deal of Sinatra + Padrino applications released into the wild over the last 2 years. Many of these have actually been [Lipsiasoft](http://www.lipsiasoft.com/portfolio) websites built in Padrino by Davide, one of our core team members. Padrino originally started in part because of Davide’s interest in using Sinatra at his own Italy-based consulting company.

In addition to the applications released and deployed by the core team, there have also been a number of interesting applications built by others in the community. A few are highlighted below.

### Fikus

[Fikus](https://github.com/bratta/fikus) is the “Simple Ruby CMS” created by [Tim Gourley](https://github.com/bratta) of the Engine Yard team. This simple content management features an admin interface, markdown for page contents, easy extensibility, mongodb-backed data store, and page caching.

Right now, the easiest way to use fikus is to simply [fork the project](https://github.com/bratta/fikus) and begin making your own changes. All you need to do is clone the project locally and then use bundler to install dependencies. In addition, you need to be running mongodb for persistence.

### Piccioto

[Piccioto](https://github.com/apeacox/picciotto) is a “minimalistic website framework based on Padrino” created by [Andrea Pavoni](https://github.com/apeacox) of digitalbricks in Italy. This simple website framework allows you to create simple hybrid web sites containing static and dynamic components. This framework is composed of many tools which can be used for easy web development and features Html5 Boilerplates, Haml Templates, Sass stylesheets, Rspec testing and semi-static page support.

Right now, the easiest way to use Piccioto is to simply [fork the project](https://github.com/apeacox/picciotto) and begin making your own changes. All you need to do is clone the project locally and then use bundler to install dependencies. Next you can put static pages in `app/views/main/static` and add other routes as necessary to your application.

### Presto

[Presto](https://github.com/pengwynn/presto) is an effort to combine Padrino with [Nesta](http://github.com/gma/nesta) to build a simple Sinatra-based CMS that can be mounted into a larger application. This project was created by [Wynn Netherland](https://github.com/pengwynn) who works a popular podcast about open-source called [TheChangeLog](http://thechangelog.com/). Padrino was actually featured on the program about 9 months ago where they [interviewed us](http://thechangelog.com/post/708173099/episode-0-2-7-padrino-ruby-web-framework) about Padrino.

The easiest way to use this project is to simply [clone the repository](https://github.com/pengwynn/presto) and mount it as a sub-application in your Padrino project.

### Notable Mentions

In addition to those projects, there are many others out there which we know about and many more which we don’t! Here is a list of a few more we thought were worth checking out:

-   [Padrino Web](https://github.com/padrino/padrino-web) – The web application powering our official Padrino website and blog.
-   [pergola](https://github.com/ryanfitz/pergola) – Created by Ryan Fitz and provides a web front-end to MongoDB.
-   [haircut](https://github.com/udzura/haircut) – Created by Uchio Kondo and is a simple url shortener in Padrino and MongoDB.
-   [moolah](https://github.com/mcmire/moolah) – Created by Elliot Winkler and is a tiny money management application.
-   [mashup](https://github.com/mwlang/mashup) – Created by Michael Lang and is a simple RSS feed reader.
-   [me-tee](https://github.com/pepe/me-tee) – Created by Josef Pospíšil and is a small shop for a t-shirt business.

If you have a project built on Padrino that is not mentioned here, please let us know about it!

## Padrino Libraries

There are also many libraries built to extend Padrino’s functionality. Many of these provide excellent features to make development even easier. We select three to feature below:

### padrino-fields

[padrino-fields](https://github.com/activestylus/padrino-fields) by [activestylus](https://github.com/activestylus) is a framework to make form building even easier in Padrino applications. Once you install this application and register this in a Padrino app:

    # Gemfile
    gem "padrino-fields"
    # app.rb
    register PadrinoFields
    set :default_builder, 'PadrinoFieldsBuilder'

You can begin using forms such as:

    app/views/form.haml
    - form_for @user do |f|
      = f.input :username
      = f.input :password
      = f.submit

This will generate a form with labels for username and password – supplying the appropriate inputs, labels and error messages on missing/invalid fields. PadrinoFields looks at your database columns to generate default inputs. Currently only supports datamapper but can be extended to support any component.

### simple-navigation

[simple-navigation](https://github.com/andi/sinatra-simple-navigation) by [Andi Schacke](https://github.com/andi) is a module that makes creating simple navigations with multiple levels easy in Rails, Sinatra or Padrino applications. You can render your navigation as an html list, link list or with breadcrumbs.

Simply install the application with:

    # Gemfile
    gem 'sinatra-simple-navigation', :require => 'sinatra/simple-navigation'
    # app.rb
    register Sinatra::SimpleNavigation

and then run bundle install and begin defining your navigation structure. For examples, check out the [simple nav demos](http://github.com/andi/simple-navigation-demo).

### padrino-warden

[padrino-warden](https://github.com/jondot/padrino-warden) by [Dotan J. Nahum](https://github.com/jondot) is a module that provides authentication for your Padrino application through [Warden](https://github.com/hassox/warden).

### Notable Mentions

There are other libraries definately worth checking out listed below:

-   [padrino-responders](https://github.com/nu7hatch/padrino-responders)
-   [padrino-form-errors](https://github.com/nu7hatch/padrino-form-errors)
-   [padrino-contrib](https://github.com/padrino/padrino-contrib)
-   [padrino-haml-pagination](https://github.com/sumskyi/padrino-haml-pagination)

If you have a library built on Padrino that is not mentioned here, please let us know about it!

## People Using Padrino

There are also a number of developers and consulting companies that have been using Padrino for various projects. A few of them we know of are listed below:

-   [Dynosoft](http://www.dynosoft.com)
-   [BakedWeb](http://bakedweb.net/portfolio/web-development)
-   [Fred Wu](http://fredwu.me/post/759061247/wuit-com-now-runs-on-padrino)
-   [Professional Dilettante](http://professionaldilettante.com/padrino/2010.06.20)
-   [BroadMac](http://broadmac.net/)

This is only a very small list of the people using Padrino. Since we never made much of an effort to compile this information before, we would love to know if you are using Padrino or picking modules into your Sinatra applications. We want to post more regularly on the community around Padrino in the future. You can let us know by sending us a message on Github (nesquena, achiu, daddye) or on our [google groups](http://groups.google.com/group/padrino) or through email to nesquena(AT)gmail(DOT)com. Look forward to hearing from you.