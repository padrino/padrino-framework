---
date: 2010-03-01
author: DAddYE
email: d.dagostino@lipsiasoft.com
title: Mounting Applications
---

Padrino applications are all automatically mountable into other Padrino projects. This means that a given Padrino project directory can easily mount multiple applications. This allows for better organization of complex applications, re-usable applications that can be applied (i.e admin, auth, blog) and even more flexibility.

You can think of mountable applications as a ‘full-featured’ merb slice or rails engine. Instead of a separate construct, any application can simply be packaged and mounted into another project.

 

## Mounting Syntax

Padrino stores application mounting information by default within `config/apps.rb`. This file is intended to keep all information regarding what applications are mounted to which uri’s. An `apps.rb` file has the following structure:

    Padrino.mount("blog").to("/blog")
    Padrino.mount("website").to("/website")
    Padrino.mount("app").to("/")

This would mount three applications onto the Padrino project, one served from the ‘/blog’ uri namespace one with ‘/website’ uri namespace and the other served from the ‘/’ uri namespace.

 

## Advanced Mounting Support

In addition to the basic mounting capabilities afforded by Padrino for each application within a project, the [Padrino::Router](http://github.com/padrino/padrino-framework/blob/master/padrino-core/lib/padrino-core/router.rb) also allows for more advanced mounting conditions.

The Padrino::Router is an enhanced version of [Rack::UrlMap](http://github.com/rack/rack/blob/master/lib/rack/urlmap.rb) which extends the ability to mount applications to a specified path, or specify host and subdomains to match to an application. For example, you could put the following in your `config/apps.rb` file:

    # Adds support for matching an app to a host string or pattern
    Padrino.mount("Blog").to("/").host("blog.example.org")
    Padrino.mount("Admin").host("admin.example.org")
    Padrino.mount("WebSite").host(/.*\.?example.org/)
    Padrino.mount("Foo").to("/foo").host("bar.example.org")

This will configure each application to match to the given host pattern simplifying routing considerably.