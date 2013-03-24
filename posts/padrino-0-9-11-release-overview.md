---
date: 2010-05-28
author: DAddYE
email: d.dagostino@lipsiasoft.com
categories: Update
tags: padrino, release, version
title: Padrino 0.9.11 Release Overview
---

Today the Padrino team released the new version 0.9.11. This version contains a number of new features and a lot of bug fixes. The features and fixes include a new mailer, improved routing support, core refactorings, enhanced test coverage, new language translations, and much more.

Also worth noting is that this version contains a few backwards **incompatible** changes to the API from 0.9.10. These changes are to help stabilize the Padrino API towards a 1.0 release and generally improve the consistency of our framework.

This post will guide you through the specific changes that are needed to fix compatibility for 0.9.11 and also explain in much more detail what has changed in this release.

<break>

## What’s new in this version?

### Refactored Mailer

In this release, the biggest feature change is the updated mailer functionality. The syntax for the mailer has been modified significantly. In addition, the underlying message delivery library has been changed from tmail to the much better [mail](http://github.com/mikel/mail) library.

Mailer definitions now use a much more consistent ‘Sinatra’ syntax instead of the old ActionMailer syntax. We think this makes the mailer much more intuitive and adherent to the Sinatra philosophy:

    # app/mailers/sample_mailer.rb
    MyAppName.mailer :sample do
      email :registration_email do |name, email|
        from 'admin@site.com'
        to email
        subject 'Welcome to the site!'
        locals :name => name, :email => email
        render 'registration_email'
      end
    end

In addition, the mailer now has support for ‘quick’ email delivery within a controller. To deliver a ‘one-off’ email from the controller, simply use the `email` method:

    # app/controllers/session.rb
    post :create do
      # ... do stuff ...
      email(:to => "john@smith.com", :subject => "Successfully Registered!", :body => "Test Body")
    end

To check out more information, be sure to read the [mailer](http://www.padrinorb.com/guides/padrino-mailer) guide.

### Upgraded Core Router

In previous versions, Padrino has leveraged the [Usher](http://github.com/joshbuddy/usher) router to provide fast and reliable routing functionality that replaces the limited Sinatra router. Usher was developed by Joshua who is now a core member of the Padrino development team. As we were developing Padrino, a number of router bugs were reported and the Usher framework was patched as problem reports were resolved. However, a few bug reports caused Joshua to consider rewriting an entirely new router library from scratch that would supersede Usher.

Eventually, Joshua posted his new router called [http\_router](http://github.com/joshbuddy/http_router) which successfully replaces Usher. In this new version of Padrino, Usher has been replaced by http\_router. For users, this shouldn’t mean any major changes to their code. All of the existing router tests still pass with the new http\_router implementation. The new router should perform considerably quicker and is also more memory efficient.

### Tiny Project Generation

In addition to standard project generation, there is now support for an alternate project generation syntax which creates a much flatter file structure. You can do a tiny project generation with:

    $ padrino g project tiny_app -d mongoid --tiny

In this version, instead of a `app/controller` folder, there is simply a `app/controllers.rb` file. Instead of an `app/mailers` folder, there is simply an `app/mailers.rb` file. This is for projects that do not require the ‘full’ padrino structure and require a more concise structure.

### Database Adapter Support

Padrino generators have always had full support for multiple persistence engines (i.e sequel, datamapper, etc) but now we have support for specifying the database adapter to use for the RDBMS’s. Now, you can specify the adapter to use (mysql, sqlite, postgres) as follows:

    $ padrino g project your_project -d datamapper   -a mysql    # Uses Datamapper and MySQL
    $ padrino g project your_project -d activerecord -a postgres # Uses ActiveRecord and Postgres
    $ padrino g project your_project -d sequel       -a sqlite   # Uses Sequel and Sqlite3

This will automatically configure the database in `config/database.rb` to use the specified adapter for your project.

### Improved Reloader

Padrino always had development code reloading but there were a number of flaws that created problems such as duplicate logging, filters, model definitions, and certain files failed to reload properly. In this release, we have upgraded the reloader such that it should work seamlessly in many more cases than before. It is unlikely to be completely smooth, but creating a perfect code reloader is an incremental process. We will continue to work on the reloader in future releases.

### Additional Enhancements

There are also a number of other big and compatibility fixes, most notably:

-   Use Bundler to declare external dependencies in padrino gem
-   Fixed routing isses with IE accept headers
-   Adds dojo.js as script component
-   Fixed escaping in javascript helper
-   Added compatibility with ActiveSupport 3.0 beta
-   Added compatibility with DataMapper 1.0
-   Added support for Mongoid 1.9.1
-   Added better bundler support also for testing
-   Removed jeweler dependency and use dynamic gemspecs
-   Major cleanups to gem generation tasks
-   Fixed mounter in certain scenarios (i.e. single app file)
-   Fixed an issue with cherry-picking Padrino Rendering into a Sinatra application
-   Fixed several issues with Usher and routing functionality
-   Improve the router’s use of base uri’s in url\_for method
-   Added full Spanish, German, Turkish, Ukrainian translations
-   Fixed error\_messages\_for to use humanized attribute
-   Adds compass component for stylesheets in project generator
-   Adds support for a ’—app’ option to specify app name in project generator
-   Added support for disabling asset timestamps via setting

## How do I convert older projects?

To make 0.9.10 applications compatible with this new version, there are a few things you must modify in your code. The first change is that the Padrino modules (Padrino::Helpers and Padrino::Mailer) are no longer invisibly registered within your app. In newly generated projects, these modules are included explicitly in the app file. To fix older apps, simply add the following to `app/app.rb` as needed:

    # app/app.rb
    class MyAppName < Padrino::Application
      register Padrino::Helpers # add this module if needed
      register Padrino::Mailer  # add this module if needed
    end

In addition, you should add the correct modules to the admin application (if generated) to `admin/app.rb` as shown:

    # admin/app.rb
    class Admin < Padrino::Application
      register Padrino::Helpers
      register Padrino::Mailer
      register Padrino::Admin::AccessControl
    end

This should make the applications work as they did in 0.9.10. In addition to this the only other breaking change is the completely new mailer functionality. The old mailer syntax required your settings to be configured as shown:

    # config/initializers/mailer_init.rb
    Padrino::Mailer::Base.smtp_settings = { 
     :host   => 'smtp.gmail.com', 
     :port   => '587', 
     :tls    => true, 
     :user   => 'user', 
     :pass   => 'pass', 
     :auth   => :plain 
    } 

this should be replaced with the updated syntax:

    # app/app.rb
    set :delivery_method, :smtp => { 
      :address              => "smtp.gmail.com",
      :port                 => 587,
      :domain               => 'your.host.name',
      :user_name            => '<username>',
      :password             => '<password>',
      :authentication       => 'plain',
      :enable_starttls_auto => true  
    }

You also need to modify the older mailer definitions:

    # app/mailers/sample_mailer.rb
    class SampleMailer < Padrino::Mailer::Base
      def registration_email(name, email)
        from 'admin@site.com'
        to email
        subject 'Welcome to the site!'
        body :name => name, :email => email
      end
    end

and change them to use the updated syntax:

    # app/mailers/sample_mailer.rb
    MyAppName.mailer :sample do
      email :registration_email do |name, email|
        from 'admin@site.com'
        to email
        subject 'Welcome to the site!'
        # now requires explicit render 
        #   template found in app/views/mailers/sample/registration.erb
        #   with access to 'name' and 'email' local vars
        render 'registration' 
        locals :name => name, :email => email
      end
    end

Once you have switched both the smtp configuration and the mailer definitions, your old app should work properly in 0.9.11. For more information on the updated mailer, be sure to check the [mailer](http://www.padrinorb.com/guides/padrino-mailer) guide.

If you are using Datamapper 1.0, and you generated your application in 0.9.10, be sure to update the Gemfile accordingly:

    # Gemfile
    gem 'data_mapper'
    gem 'dm-sqlite-adapter'

and be sure to remove all other datamapper gem references.