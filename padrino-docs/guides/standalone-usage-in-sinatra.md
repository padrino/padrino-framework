---
date: 2010-03-01
author: Uchio
email: udzura@udzura.jp
title: Standalone Usage in Sinatra
---

 

## Introduction

Padrino is by default a full-stack framework which provides a large number of enhancements to Sinatra and uses a new base application `Padrino::Application`. However, there are clearly times when even Padrino itself is far too ‘heavyweight’ for an application.

In these instances, the ideal situation would be to cherry-pick individual enhancements and use them in your existing Sinatra application. Fortunately, Padrino is committed to allowing you to do exactly that! Each major component within Padrino can be used in isolation and applied to an existing Sinatra application. This guide will walk you through that process for each component. You can also find some examples [here](http://github.com/padrino/single-apps).

 

## Padrino Helpers

This component provides a great deal of view helpers related to html markup generation. There are helpers for generating tags, forms, links, images, and more. Most of the basic methods should be very familiar to anyone who has used rails view helpers.

You can check out the details of these helpers in the [Application Helpers](/guides/application-helpers) guide. To register these helpers within your Sinatra application:

    # app.rb
    require 'sinatra/base'
    require 'padrino-helpers'

    class Application < Sinatra::Base
      register Padrino::Helpers
    end

 

## Padrino Mailer

This component provides a powerful but simple mail delivery system within Padrino (and Sinatra). There is full support for using an html content type as well as for file attachments. The Padrino Mailer has many similarities to ActionMailer but is much lighter-weight and easier to use.

You can check out the details of the mailer in the [Padrino Mailer](/guides/padrino-mailer) guide. To register this mailer within your Sinatra application:

    # app.rb
    require 'sinatra/base'
    require 'padrino-mailer'

    class Application < Sinatra::Base
      register Padrino::Mailer
      
      mailer :sample do
        email :birthday do |name, age|
          subject 'Happy Birthday!'
          to      'john@fake.com'
          from    'noreply@birthday.com'
          locals  :name => name, :age => age
          render  'sample/birthday'
        end
      end 
    end

 

## Padrino Routing

You can check out the details of the routing system in the [Routing](/guides/controllers) guide. To register the routing and controller functionality within your Sinatra application:

    # app.rb
    require 'sinatra/base'
    require 'padrino-core/application/routing'
    ##
    # Small example that show you some padrino routes.
    # Point your browser to:
    #
    #   http://localhost:3000
    #   http://localhost:3000/bar
    #   http://localhost:3000/bar.js
    #   http://localhost:3000/custom-route/123
    #
    # These routes didn't works:
    #
    #   http://localhost:3000/bar.xml
    #   http://localhost:3000/bar.jsl
    #   http://localhost:3000/custom-route
    #
    class MyApp < Sinatra::Application
      register Padrino::Routing

      get :foo, :map => "/" do
        "This is foo mapped as index"
      end

      get :bar, :provides => [:js, :html] do
        case content_type
          when :js   then "Bar for js"
          when :html then "Bar for html"
          else "You can never see this"
        end
      end

      get :custom, :map => '/custom-route', :with => :id do
        "This is a custom route with #{params[:id]} as params[:id]"
      end
    end # MyApp

    MyApp.run!(:port => 3000)

 

## Padrino Rendering

Padrino enhances the Sinatra ‘render’ method to have support for automatic template engine detection, among other more advanced features.

    # app.rb
    require 'sinatra/base'
    require 'padrino-core/application/rendering'

    class Application < Sinatra::Base
      register Padrino::Rendering

      get('/')  { render 'example/demo' } # Auto-renders 'views/example/demo.haml' 
      get('/demo') { render :haml, 'example/demo' } # Renders 'views/example/demo.haml' 
    end

 

## Padrino Cache

**Note that the padrino-cache** gem does not currently do anything! This is a placeholder for when this gem has been implemented.

    # app.rb
    require 'sinatra/base'
    require 'padrino-cache'

    class Application < Sinatra::Base
      register Padrino::Cache
    end

This will allow for use of the caching functionality within Sinatra.