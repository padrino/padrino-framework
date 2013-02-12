---
author: Foo Bar
tags: padrino, sinatra, ruby
categories: Ruby, Update
title: Padrino 0.9.27 - Project settings, routing, compatibility and bug fixes
---

## Project-wide Settings

In this release, we have added the notion of ‘project’ settings that are inherited by every Padrino application within
the project. This can be used to set any properties but is particularly useful for sharing sessions across your apps.
These project-wide settings are intended to live in `config/apps.rb` and are generated in every new application.


```ruby
# config/apps.rb
# Set the global project settings for your apps.
# These settings are inherited by your subapps.
# You can override these settings in each of your sub apps.
Padrino.configure_apps do
  enable :sessions
  set :foo, “bar”
end
```


Using this is optional and you can override these settings on a per-app basis as well. Commits are
[[here](https://github.com/padrino/padrino-framework/commit/3b04e489ff7477ab28fbca2ded503f3efdde77f3]),
[[here](https://github.com/padrino/padrino-framework/commit/0825b6bf9ae337f5860a3a3cfe5662b646927f03]), and
[[here](https://github.com/padrino/padrino-framework/commit/99033a8a368eb9942daf6b5af174857bd38948e6]).


## Reverse Route Recognition

We have occasionally had the need to access the current route from within a template in order to create links or
determine the current page.


Given we have a route such as


```ruby
# controllers.rb
controller :some do
get :other, :map => “/custom/url/with-:foo” do; end
end
```


We have added the ability to recognize a url and retrieve the route:


```haml
# my_view.haml
url(:some, :other, :foo => :bar)
# => /custom/url/with-bar
```

We have also added the ability to get the current page:


```ruby
# in a path like /posts/?search=bar&name=foo
= link_to “Sort by Name”, current_path(“sort” => :name)
= link_to “Sort by Date”, current_path(“sort” => :date)
```


Commits for this are
[here](https://github.com/padrino/padrino-framework/commit/c0b23620e08917928fd445b27575ddae3fbfb494) and
[[here](https://github.com/padrino/padrino-framework/commit/221ae9f53fd3e9603c9acf2d22f18b08b3d00ba6]).


## Compatibility Fixes

- Upgrade to Sinatra 1.2.6 dependency from 1.2.4 by default
- Make logger Sinatra 1.3 compatible
  [[commit](https://github.com/padrino/padrino-framework/commit/1ea322e3c74d2c15fac1a67d208670f544984d9b])
- SCSS needs to rely on ‘sass’ gem instead of ‘haml’
  [[commit](https://github.com/padrino/padrino-framework/commit/a7758e62e6acdb4cd6f5e00d89595d79f4b01607])
- Use CouchRest::Model in favor of deprecated CouchRest::ExtendedDocument. Thanks to Burgestrand!
  [[commit](https://github.com/padrino/padrino-framework/commit/8fc910e7fa6dbf41f06cb5a14d97a8988ad6d699])
- Use the sqlite3 gem as dependency for generated projects
  [[commit](https://github.com/padrino/padrino-framework/commit/8e7ea0081a68bc0ffedc186f62c131835d17124d])
- Use SecureRandom to generate session secret
  [[commit](https://github.com/padrino/padrino-framework/commit/7770883d3b486342070eb159ab57ffda0f7206e5])
- Partials can now be used directly with Sinatra from Padrino::Helpers
  [[commit](https://github.com/padrino/padrino-framework/commit/0507fe3910beea2bf268d9ca746349099c35415a]),
  [[example](https://gist.github.com/956825])
- Adds MongoMapper rake task for dropping the database
  [[commit](https://github.com/padrino/padrino-framework/commit/0a9eaae1d3aff47954836bebcd5ae21f74c9a7b2])


## Bug Fixes

- Fix YAML by using ‘syck’ to parse by default
  [[commit](https://github.com/padrino/padrino-framework/commit/a3bc92488b96bc34c3ab6d34498c5ebdeef006b0])
- Fix to slim template in admin for destroy session
  [[commit](https://github.com/padrino/padrino-framework/commit/5ebf0292ca8a974910d587a7b5c2a0203eac56a6])
- Offline generation of static js
  [[commit](https://github.com/padrino/padrino-framework/commit/e2069fe19cc5c02ee27620157eedd519555adcb9])

