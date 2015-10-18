---
date: 2015-10-12
author: Nathan Esquenazi
email: nesquena@gmail.com
categories: Ruby, Update
tags: padrino, sinatra, ruby
title: Upgrading Padrino from 0.12.X to 0.13.0 Guide
---

This is the step-by-step guide for upgrading from Padrino 0.12.X to 0.13.0! This will review all the breaking changes and modifications made within the new release. Be sure to also check the [0.13.0 Release Blog Post](http://www.padrinorb.com/blog/padrino-0-13-0-mustermann-router-performance-enhancements-streaming-support-and-much-more) for more information.

<break>

Deprecated Features Removed
---------------------------

Several deprecated methods were removed in this release including:

* `#link_to with :fragment` 
  * Use `:fragment` for `#url` instead: `url(:controller, :action, :fragment => "foo")` 
* `Application#load_paths`, `Padrino.set_load_paths`, `Padrino.load_paths` 
  * To set, use `$LOAD_PATH.concat(paths)` 
  * To get, use `Padrino.prerequisites` instead 
  * deprecated caching methods
    * methods including `#get`, `#set`, `#flush` (see [more here](https://github.com/padrino/padrino-framework/blob/7dbc8ce92030f2b2b8e63a41d0563d1044a588aa/padrino-cache/lib/padrino-cache/legacy_store.rb)) 
* deprecated form builder methods 
  * methods including `field_error` and `nested_form?` (see [more here](https://github.com/padrino/padrino-framework/blob/7dbc8ce92030f2b2b8e63a41d0563d1044a588aa/padrino-helpers/lib/padrino-helpers/form_builder/deprecated_builder_methods.rb)") 
* `#fetch_template_file`, `#cache_template_file!`, `#resolved_layout` rendering methods 
  * No replacement exists 
* `String#undent` 
  * No replacement exists

Helper Changes
--------------

There are a few helper changes to be aware of:

* `select_tag` used to be fairly ambiguous when specifying “selected” options. The ambiguity has been removed by always relying on the “value” where possible. 
  * Switch your `:selected` options to indicate the value of the option wherever possible. (see [more here](https://github.com/padrino/padrino-framework/commit/49f4e907d0caeba81537f184db99a550cac31c5a))

New Routing System
------------------

Subtle differences likely exist between the old [http_router](https://github.com/joshbuddy/http_router) and the new [mustermann](https://github.com/rkh/mustermann) powered system. These differences include:

* Splat arguments in URL are now a string rather than an array 
  * `get :show, :map => "/show/*name"` used to return `params[:name]` as an array. Now this is a string.
