---
author: Foo Bar
title: Why
label: Menu
---

Many developers fall in love with the simplicity and expressiveness of Sinatra but quickly come to miss a great deal of
functionality provided by other web frameworks such as Rails when building non-trivial applications.


Our team has come to love the philosophy of Sinatra which acts as a thin layer on top of rack allowing middleware to do
most of the work and enabling additional complexity only when required.


The goal for this framework is to match the essence of Sinatra and make it suitable for increasingly complex
applications that require the use of forms, mail delivery, localization, helpers, caching, etc…


For our team, coding is **an art form** and Sinatra best enables this concept because of these core principles:

- Clean
- Compact
- Fast
- Creative
- Concise


The Padrino framework is the perfect solution for your small projects as well as for your larger project requirements!


Below we review a few ways that Padrino compares to existing web frameworks.


## Routing

Like Sinatra, this framework uses **http verb** routing declarations instead of complex routing setups. We think that
its more *explicit*, *cleaner* to read and *simpler* to write than other alternatives.


```ruby
get "/home-page" do
  render :home
end
```

Unlike Sinatra, this framework supports *namespaced route aliases*, *named parameters*, *nested routes*, and *respond to
formats*. See the [controller guide](/guides/controllers) for more details.


Here is an example:


```ruby
MyApp.controller :products do
  get :show, :map => "/this-is/:id/cool" do
    product = Product.find(params[:id])
    render 'products/show'
  end
end
```

Route aliases can help you write urls in your app:


```ruby
url(:products, :show, :id => product)
```


without consider the final url, because this may change.


In Rails, to do the same thing requires:


```ruby
class ProductsController < ActionController::Base
  def show
    product = Product.find
  end
end
```


Then open `config/routes.rb` and add a seo friendly url like:


```ruby
map.connect "/this-is/:id/cool", :controller => "products",
:action => "show"
```

With rails in order to establish the *final* url, we needed to open
*another file* .


Figures to have: 50 controllers with 7 actions each.


At the end of your work you need to enhance your urls to be more SEO friendly


You need to browse 50 controllers and check each action and copy/map them into `routes.rb`.


## Rendering

Different from Rails, we take an *explicit* approach to rendering templates within a route. We believe that writing a
little more can really help make the code much more readable.


In rails, you might see the following action:

```ruby
class ClientsController < ActionController::Base
  def new
    client = Client.new
  end
end
```


To know which template will be rendered you need to know the name of the controller `ClientsController` or file
name `clients_controller.rb` and be cognizant of conventions to know which template (`/clients/new`) will
be rendered.


Now, we don't think that you're *stupid*. But especially in larger codebases or in code written from others your *mind*
is needed elsewhere for more important things, so we enforce a *concise* syntax:


```ruby
MyApp.controller :clients do
  get :new do
    client = Client.new
    render 'clients/new'
  end
end
```


For some this can be tiring to their hands, but for others it can help to understand better what exactly is going on. A
little extra effort goes a long way!


## Directory Tree

We think that a framework must meet small project and big project requirements so for a thin app, a Rails tree is too
big and complex.


```bash
$ rails blog
/blog
|--app
|------controllers
|------helpers
|------models
|------views
|----------layouts
|--config
|------environments
|------initializers
|------locales
|--db
|--doc
|--lib
|------tasks
|--log
|--public
|------images
|------javascripts
|------stylesheets
|--script
|--test
|------fixtures
|------functional
|------integration
|------performance
|------unit
|--tmp
|------cache
|------pids
|------sessions
|------sockets
|--vendor
|------plugin
```


Padrino's generated tree is far more compact in comparison:


```bash
$ padrino-gen project blog
/blog
|--app
|------controllers
|------helpers
|------views
|----------layouts
|--config
|--lib
|--public
|------images
|------javascripts
|------stylesheets
|--spec
|--tmp
```


## DRY Principles

The main aim of Ruby on Rails is *don't repeat yourself* but Padrino doesn't just apply this concept for *coding*.


The current Rails version (things changed a little in 3.0 version) copies these for each project:


```bash
script/about
script/breakpointer
script/console
script/dbconsole
script/destroy
script/generate
script/performance
script/plugin
script/process
script/runner
script/server
```


Why do we need these commands for each project? With Padrino, you can achieve the same functionality with:


```bash
$ padrino start|stop # for starting and stopping the built-in server
$ padrino-gen        # that act as script/generate (can also use padrino g)
```


Why does each project need a `Rakefile`? How many times do you actually change it? In Padrino, to run rake tasks you can
simply do:


```bash
$ padrino rake your:task
```


If you need your own tasks like within rails, you can simply store them in `lib/tasks` and they will be automatically
available to you. See the [rake tasks](/guides/rake-tasks) guide for more info.


## Mountable Applications

Both Merb and Rails still do not support a simple way (as within Django) to creating multiple applications within the
same projects. Rails 3 is working towards true fully mountable applications, but Padrino has them right now out of the
box and with virtually no extra effort.


Why is it necessary to have mountable applications? There are many different applicable scenarios. For example, you
might need to build simple sites which act as customer showrooms. All of these sites share the same logic like admin,
auths, models, etc.


In Rails, to achieve this you might normally create three separate applications:


```bash
$ rails show_room_1
$ rails show_room_2
$ rails show_room_3
```


Then if you are a good coder, you will have your own libs/gems and you can share them however you need to recreate
models, migrations some custom helpers etc…


You might also see Rails apps with controllers such as:


```bash
/app/controllers/show_room_1
/app/controllers/show_room_2
/app/controllers/show_room_3
```


However, with this approach it becomes a little tricky to locate urls and generally more complicated to manage.


In Padrino, what Rails/Merb calls an **Application** is actually a **Project**. So following our simple *scenario*,
you can create a project called **showrooms** and then build `showroom applications` mounted within the project.


```bash
$ padrino-gen project showrooms -r haml -d mongomapper # or your preferred orm
$ cd showrooms
$ padrino-gen app show_room_1
$ padrino-gen app show_room_2
$ padrino-gen app show_room_3
```

Then in your project you have a tree like:


```bash
/showrooms
|--app # is the core we can store our basic logic .
|------controllers
|------helpers
|------views
|------models
|--admin # is a shared interface for our customers for manage their site contents.
|------controllers
|------helpers
|------views
|--show_room_1 # frontend application and itself can contain if necessary their own models.
|------controllers
|------helpers
|------views
|--show_room_2 # frontend application and itself can contain if necessary their own models.
|------controllers
|------helpers
|------views
|--show_room_3 # frontend application and itself can contain if necessary their own models.
|------controllers
|------helpers
|------views
|----------layouts
|--config
|--lib
|--public
|------images
|------javascripts
|------stylesheets
|--spec
|--tmp
```


As you can see this is a much cleaner and simpler to keep things organized within a large project requiring shared
resources.


## Agnostic


Rails has its ActiveRecord, Merb has it's Datamapper. With some work, you can have them use another ORM. With Padrino,
using your desired library can be done with ease. This isn't just specific for ORM's either. On top of Sinatra's
philosophy of simplicity and expressiveness, Padrino comes shipped with a plethora of components you can choose from,
whether it be for renderers, stylesheets, javascripts, and even tests and mocks. As of the current version, Padrino
comes with component choices for:


**Database Wrapper**

- ActiveRecord
- DataMapper
- Sequel
- MongoMapper
- Mongoid
- Mongomatic
- Ohm
- Coachrest


**Tests**

- Bacon
- Shoulda
- RSpec
- Riot
- Cucumber
- Testspec


**Javascripts**

- Prototype
- RightJS
- JQuery
- MooTools
- extcore
- dojo


**Renderer**

- Erb
- Haml
- Slim
- Liquid


**Stylesheets**

- Sass
- Less
- SCSS
- Compass


**Mocks**

- RR
- Mocha


With Padrino, the developer is able to pick the best components based on the requirements of his project while still
enjoying deep framework integration. In addition [new components](http://www.padrinorb.com/guides/adding-new-components)
are easily added and are just a pull request away. For more information, check out the
[guides](http://www.padrinorb.com/guides/generators) for more details.


Padrino is also capable of being included piece by piece into a standard Sinatra application if the entire framework is
not needed. You can easily cherry pick the desired Padrino modules into a Sinatra app by following the
[standalone usage guide](http://www.padrinorb.com/guides/standalone-usage-in-sinatra)

