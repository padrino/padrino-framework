---
date: 2010-03-01
author: Arthur
email: mr.arthur.chiu@gmail.com
title: Padrino Mailer
---

This component creates an easy and intuitive interface for delivering email within a Sinatra application. The [mail](http://github.com/mikel/mail) library is utilized to do the bulk of the work. There is full support for rendering email templates, using an html content type and for file attachments. The Padrino Mailer uses a familiar Sinatra syntax similar to that of defining routes for a controller.

 

## Configuration

Let’s take a look at using the Mailer in an application. By default, the mailer uses the built-in sendmail
 binary on the server. However, smtp is also supported using the following declaration in your application:

    # app/app.rb
    set :delivery_method, :smtp => { 
      :address              => "smtp.gmail.com",
      :port                 => 587,
      :user_name            => '<username>@gmail.com',
      :password             => '<password>',
      :authentication       => :plain,
      :enable_starttls_auto => true  
    }

Once those have been defined, the default will become smtp delivery unless overwritten in an individual mail definition.

You can also configure the mailer to not run during tests. This can be done with:

    # app/app.rb
    set :delivery_method, :test

 

## Quick Usage

Padrino supports sending any arbitrary email (using either sendmail or smtp) right from your controllers. This is ideal for ‘one-off’ emails where the ‘full’ mailer object is simply unnecessary or too heavy for your simple task.

Delivering an email within your controller is simple:

    # app/controllers/session.rb
    post :create do
      email(:from => "tony@reyes.com", :to => "john@smith.com", :subject => "Welcome!", :body=>"Body")
    end

This simple helper will accept any of the standard email attributes and deliver your email in a single command. You can also use a block, render a template for the body and specify a delivery method:

    # app/controllers/session.rb
    post :create do
      email do
        from "tony@reyes.com"
        to "john@smith.com"
        subject "Welcome!"
        body render('email/registered')
        via :sendmail
      end
    end

This is all you need to send simple emails. However, Padrino also supports a more ‘structured’ mailer system as well.

 

## Mailer Usage

To use the structured mailer syntax, we should define a custom mailer using the `mailer` block:

    # app/mailers/sample_mailer.rb
    MyAppName.mailer :sample do
      email :registration_email do |name, email|
        from 'admin@site.com'
        to email
        subject 'Welcome to the site!'
        locals :name => name, :email => email
        render 'registration_email'
        content_type :html       # optional, defaults to :plain
        via :sendmail            # optional, to smtp if defined otherwise sendmail
      end
    end

Note that this can be created much easier by using the padrino-mailer generator in the terminal:

    $ padrino g mailer Sample registration_email

This mailer defines a mail type called ‘`registration_mail`’ with the specified attributes for delivery. The `body` method is invoking the render command passing the `name` attribute to the body message template which should be defined in `[views_path]/mailers/sample/registration_email.erb` as shown below:

    # ./views/mailers/sample/registration_email.erb
    This is the body of the email and can access the <%= name %> variable.
    That's all there is to defining the body of the email which can be in plain text or html.

Note that the mailer has full support for content type resolution and the email could also be in the path `./views/mailers/sample/registration_email.html.erb` or `./views/mailers/sample/registration_email.plain.erb` specifying the mime type in the file name as well.

Once the mailer definition has been completed and the template has been defined, the email can be sent using:

    deliver(:sample, :registration_email, "Bob", "bob@bobby.com")

And that will then deliver the email according the the configured options.

 

## Multipart Emails

The mailer supports multipart emails quite easily:

    # app/mailers/sample_mailer.rb
    mailer :sample do
      email :email_with_parts do
        from 'admin@site.com'
        # ...
        text_part { render('path/to/basic.text')  }
        html_part render('path/to/basic.html') # shorter part syntax
      end
    end

You can even specify multiple part types using the `provides` declaration:

    # app/mailers/sample_mailer.rb
    mailer :sample do
      email :email_with_parts do
        from 'admin@site.com'
        # ...
        # renders path/to/basic.html.erb and path/to/basic.plain.erb
        provides :plain, :html
        render 'path/to/basic'
      end
    end

These will deliver a multipart/alternative email with the appropriate plain text and html sections.

 

## File Attachments

Using the mailer attaching files to a message is easy:

    # app/mailers/sample_mailer.rb
    mailer :sample do
      email :email_with_files do
        from 'admin@site.com'
        # ...
        body "Here are your files!"
        add_file :filename => 'somefile.png', :content => File.read('/somefile.png')
        add_file '/full/path/to/someotherfile.png'
      end
    end

This will deliver your email with the appropriate body and the specified files attached.

 

## Defaults

To define mailer defaults for a message, we can do so app-wide or within a `mailer` block.

    # app/app.rb
    # Application-wide mailer defaults
    set :mailer_defaults, :from => 'admin@site.com'
        
    # app/mailers/sample_mailer.rb
    MyAppName.mailers :sample do
      defaults :content_type => 'html'
      email :registration do |name, age|
        # Uses default 'content_type' and 'from' values but can also overwrite them
        to      'user@domain.com'
        subject 'Welcome to the site!'
        locals  :name => name
        render  'registration'
      end
    end

Using defaults makes sending email even easier when certain attributes are repeated between messages.

 

## Rendering Variations

To render a short body inline:

    # app/mailers/sample_mailer.rb
    mailer :sample do
      email :short_email do |name, user|
        # ...
        body "This is a short body defined right in the mailer itself"
      end
    end

To render a different template:

    # app/mailers/sample_mailer.rb
    mailer :sample do
      email :custom_email do |name, user|
        # ...
        render('path/to/template') # relative to views_path/mailers
      end
    end