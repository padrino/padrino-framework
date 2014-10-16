---
date: 2010-03-01
author: Nathan
email: nesquena@gmail.com
title: Development Commands
---

Padrino also supports robust logging capabilities. By default, logging information will go to the STDOUT in development (for use in a console) and in an environment-specific log file `log/development.log` in test and production environments.

You can modify the logging behavior or disable logging altogether (more docs [here](http://www.padrinorb.com/api/classes/Padrino/Logger.html)):

    # boot.rb
    Padrino::Logger::Config[:development][:stream] = :to_file
    Padrino.load!

To use the logger within a Padrino application, simply refer to the `logger` method accessible within your app and any controller or views:

    # controllers/example.rb
    SimpleApp.controllers do
      get("/test") { logger.info "This is a test" }
    end

The logger automatically supports severity through the use of `logger.info`, `logger.warn`, `logger.error`, et al.
 For more information about the logger, check out our [Logger RDOC](http://www.padrinorb.com/api/classes/Padrino/Logger.html)

 

## Development Reloader

Padrino applications also have the enabled ability to automatically reload all changing application files without the need to restart the server. Through the use of a customized Rack middleware, all files on the ‘load path’ are monitored and reloaded whenever changes are applied.

This makes rapid development much easier and provides a better alternative to ‘shotgun’ or ‘rerun’ which require the application server to be restarted which makes requests take much longer to complete.

An application can explicitly enable / disable reloading through the use of options:

    # app.rb
    class SimpleApp < Padrino::Application
      disable :reload # reload is disabled in all environments
      enable  :reload # enabled in all environments
    end

 

## Gemfile Dependency Resolution

Padrino has native support for `bundler` and the Gemfile system. If your Padrino application was generated with `padrino g`, a Gemfile has already been created for your application. This file will contain a list of all the dependencies for our application.

    # /Gemfile
    source :rubygems
    gem 'sinatra',  :require => 'sinatra/base'
    gem 'sinatra-flash', :require => 'sinatra/flash'

This manifest file uses the standard `bundler` gem syntax of which details can be found in the [Bundler WebSite](http://gembundler.com).

This gem allows us to place all our dependencies into a single file. Padrino will then automatically require all necessary files (if they exist on the system).

If the dependencies are not on the system, you can automatically vendor all necessary gems using the `bundle install --path ./vendor` command within the application root or (only with bundler 1.0) run `bundle install` to install system wide. Note that this is all possible without any further effort than adding the Gemfile (or having this generated automatically with generators explained later).

 

## Auto Load Paths

Padrino also intelligently supports requiring useful files within your application automatically and provides functionality for easily splitting up your application into separate files. Padrino automatically requires `config/database.rb` as a convention for establishing database connection. Also, any files within the `lib` folder will be required automatically by Padrino.

This is powered by the fact that Padrino will automatically load (and reload) any directory patterns within the ‘prequesite paths’. Additional directory patterns can be added to the set of reloaded files as needed by simply appending to the `prerequisites` within your application:

    # config/boot.rb
    Padrino.after_load do
      SimpleApp.prerequisites << Padrino.root('my_app', 'custom_model.rb')
      SimpleApp.prerequisites << Padrino.root('custom_folder/*.rb')
    end
    Padrino.load!

This will instruct Padrino to autoload these files (and reload them when changes are detected). By default, the load path contains certain paths known to contain important files such as controllers, mailers, models, urls, and helpers.

 

## Terminal Commands

Padrino also comes equipped with multiple useful terminal commands which can be activated to perform common tasks such as starting / stopping the application, executing the unit tests or activating an irb session.

The following commands are available:

    # starts the app server (non-daemonized)
    $ padrino start 
    # starts the app server (daemonized) with given port, environment and adapter
    $ padrino start -d -p 3000 -e development -a thin 
      
    # Stops a daemonized app server
    $ padrino stop
      
    # Bootup the Padrino console (irb)
    $ padrino console
      
    # Run/List tasks
    $ padrino rake
      
    # Run piece of code in the context of Padrino (with given environment)
    $ padrino runner 'puts Padrino.env' -e development
      
    # Run Ruby file in the context of Padrino
    $ padrino r script/my_script.rb

The last command “padrino rake” look for rake files in:

    lib/tasks/**/*.rake
    tasks/**/*.rake
    test/test.rake
    spec/spec.rake

In this way you can customize project tasks.

Using these commands can simplify common tasks making development that much smoother.

 

## Special Folders

Padrino load these paths:

    # special folders
    project/lib
    project/models
    project/shared/lib
    project/shared/models
    project/each_app/models

This mean that you are free to store for example `models` where you prefer, if you have two or more apps with same models you can use `project/shared/models` or `root/models`.

If you have only one app you still use `project/app/models`(this is the default padrino g choice)

Remember that if you need to load other paths you can use:

    Padrino.set_load_paths("path/one")

and if you need to load dependencies use:

    Padrino.require_dependencies("path/one/**/*.rb")
