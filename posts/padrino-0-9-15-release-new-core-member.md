---
author: Foo Bar
tags: padrino, release, version, plugins, templates, ohm, mongomatic, hudson
categories: Ruby, Update
title: Padrino 0.9.15 Release! New Core Member!
---

With the templates and plugins generator in Padrino we can now generate a project with a template using:


```ruby
padrino-gen project my_project~~p
path/to/my/template.rb~~r=path/to/your/project
```


For existing plugins that you want to have installed into your project, use the plugin generator:


```ruby
padrino-gen plugin hoptoad
```


A list of available plugins are kept at [padrino-recipes](http://github.com/padrino/padrino-recipes). The plugin
generator can also accept a path to a ruby file or even a gist as well! View the
[guides](http://www.padrinorb.com/guides/generators#plugin-generator) for more information!


This version also provides new additions such as, a variety of new components to Padrino:


- erubis - renderer(thanks to cored)
- liquid - renderer(thanks to rwilcox)
- mongomatic - orm(thanks to lusis)
- ohm - orm(thanks to lusis)
- scss - stylesheets


new translations such as:


- Dutch Translation (thanks to Martijin)
- Polish translation (Thanks to Kriss)


a few fixes, namely:

- fixes custom conditions
- fixes the app generation destroy option
- routes now take a regex
- ensures that the .component file stores the choices after they have been validated
- fixes an issue with the reloader where the object space wasn't been cleared.
- fixes the logic for `options_for_select` helper
- Removed some deprecation
- Fixed `DataMapper.finalize`


To see the full list of changes, take a look at the [changelog](http://www.padrinorb.com/changes)


We are also excited to introduce our newest core member, lusis! He has contributed various components such as ohm and
mongomatic, and has also generously setup a [hudson server](http://bit.ly/aIzvBE) for the Padrino community! We’re glad
to have him on board and look forward to his contributions to the project!

