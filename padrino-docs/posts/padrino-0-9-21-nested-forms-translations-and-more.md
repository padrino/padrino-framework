---
date: 2011-02-25
author: Nathan
email: nesquena@gmail.com
categories: Ruby, Update
tags: padrino, release
title: Padrino 0.9.21 - Nested Forms, Translations and More
---

Today, we have released a new version of Padrino 0.9.21 which continues the tradition of incremental improvements towards a 1.0 release. We will consider Padrino ‘1.0’ once we feel that the framework is sufficiently robust and well-documented.

We aren’t quite all the way there yet but we are rapidly improving with each release. This release contains agnostic nested object forms, chinese translations, routing enhancements, and component compatibility fixes. A more detailed list of changes is included in the full post.

<break>

There are no breaking changes from the previous version. The major changes are below:

## Nested Object Forms

One of the most commonly requested features is nested object form support within our view helpers. This handles the case where a form should create multiple related objects at once of different types.

For instance if you have a user and he has an address which is stored in a separate model. Now Padrino supports agnostic form builders for nested objects. Using this is quite simple and extends the existing form syntax:

    # app/views/example.haml
    # app/views/person/_form.html.haml
    - form_for @person, '/person/create'  do |f|
      = f.text_field :name 
      = f.text_field :favorite_color
      - f.fields_for :addresses do |address_form| 
        = address_form.label :street 
        = address_form.text_field :street
        = address_form.label :city
        = address_form.text_field :city
        - unless address_form.object.new_record? 
          = address_form.check_box '_destroy' 
          = address_form.label '_destroy', :caption => 'Remove' 
        = submit_tag "Save"

For the details be sure to checkout the [Application Helper Guide](http://www.padrinorb.com/guides/application-helpers) to learn more.

## Routing Fixes

Joshua Hull in particular can be thanked for many of these routing fixes reported by our users. In particular:

-   Routing now properly supports variables within an index route
-   Fixes routes with conjunction of :map and :with
-   Fixes regular expression route captures
-   Laziness of provides now conveys its format neediness [Fixes [Issue 412](https://github.com/padrino/padrino-framework/issues/closed#issue/412)]

<!-- -->

    # app/controllers/example.rb
    get :index, :map => '/bugs', :with => :id do
      # ...
    end

    get %r{/([0-9]+)/} do |num|
      "Your lucky number: #{num} #{params[:captures].first}"
    end

Regular expression routes should now work as expected in nearly all cases.

## Component Fixes

-   Updated mongomapper adapter to use rails3 branch
-   Updated datamapper gen to store correctly passwords
-   Adds mongoid rake tasks for maintaining database

## Traditional and Simplified Chinese Translations

This release brings support for Traditional Chinese(thanks to ayamomiji) and Simplified Chinese translations. This means that the Padrino Admin application as well as all form helpers are properly localized to this language. If you speak a language that Padrino doesn’t yet support, please consider contributing! We are happy to help get you started.

## Other fixes

-   Major changes to output handling for padrino helpers allowing easier template integration ([gist](https://gist.github.com/829030))
-   Better project generation name validations
-   Fixes the select\_tag to have better support for multiple options
-   Cleans up bundler integration removing legacy support for 0.9
-   Fixed issue with error\_message\_on where incorrect object was being accessed
-   Layouts are properly found now with shorthand aliases
    -   `render "brochure/home", :layout => :narrow`

A full list of changes can be seen by looking at our [github commit history](https://github.com/padrino/padrino-framework/commits/master) for more details. We are already working on a 0.9.22 release will should include a few exciting new features. If you run into any problems please do let us know on the [Github Issues](https://github.com/padrino/padrino-framework/issues) page.