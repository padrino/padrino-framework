---
author: Foo Bar
title: Padrino Mailer
---

This component creates an easy and intuitive interface for delivering email within a Sinatra application. The
[mail](http://github.com/mikel/mail) library is utilized to do the bulk of the work. There is full support for rendering
email templates, using an html content type and for file attachments. The Padrino Mailer uses a familiar Sinatra syntax
similar to that of defining routes for a controller.


## Configuration

Let's take a look at using the Mailer in an application. By default, the mailer uses the built-in sendmail binary on the
server. However, SMTP is also supported using the following declaration in your application:


```ruby
# app/app.rb
set :delivery_method, :smtp => {
  :address => "smtp.gmail.com",
  :port => 587,
  :user_name => '<username>`gmail.com',
  :password             => '<password>',
  :authentication       => :plain,
  :enable_starttls_auto => true
}
```


Once those have been defined, the default will become smtp delivery unless overwritten in an individual mail definition.


## Quick Usage

Padrino supports sending any arbitrary email (using either sendmail or smtp) right from your controllers. This is ideal
for 'one-off' emails where the 'full' mailer object is simply unnecessary or too heavy for your simple task.


Delivering an email within your controller is simple:


```ruby
# app/controllers/session.rb
post :create do
    email(:from => "tony`reyes.com", :to
    =>"[john@smith.com](mailto:john@smith.com)", :subject
    =>"Welcome![](", :body=>"Body")
end
```


This simple helper will accept any of the standard email attributes and deliver your email in a single command. You can
also use a block, render a template for the body and specify a delivery method:


```ruby
# app/controllers/session.rb
post :create do
  email do
    from "tony@reyes.com"
    to "john@smith.com"
    subject "Welcome)"
    body render('email/registered')
    via :sendmail
  end
end
```


This is all you need to send simple emails. However, Padrino also supports a more 'structured' mailer system as well.


## Mailer Usage

To use the structured mailer syntax, we should define a custom mailer using the `mailer` block:


```ruby
# app/mailers/sample_mailer.rb
MyAppName.mailer :sample do
  email :registration_email do |name, email|
    from '[admin@site.com](mailto:admin@site.com)'
    to email
    subject 'Welcome to the site!'
    locals :name => name, :email => email
    render 'registration_email'
    content_type :html # optional, defaults to :plain
    via :sendmail # optional, to smtp if defined otherwise sendmail
  end
end
```


Note that this can be created much easier by using the padrino-mailer generator in the terminal:


    $ padrino g mailer Sample registration_email


This mailer defines a mail type called '`registration_mail`' with the specified attributes for delivery. The `body`
method is invoking the render command passing the `name` attribute to the body message template which should be defined
in `[views_path]/mailers/sample/registration_email.erb` as shown below:


```erb
# ./views/mailers/sample/registration_email.erb
This is the body of the email and can access the <%= name %> variable
(note the lack of an `@`
on `name`). That's all there is to defining the body of the email which
can be in plain text or html.
```

Note that the mailer has full support for content type resolution and the email could also be in the path
`./views/mailers/sample/registration_email.html.erb` or `./views/mailers/sample/registration_email.plain.erb` specifying
the mime type in the file name as well.


Once the mailer definition has been completed and the template has been
defined, the email can be sent using:


```ruby
deliver(:sample, :registration_email, "Bob",
"[bob@bobby.com](mailto:bob@bobby.com)")
```

And that will then deliver the email according the configured options.


## Multipart Emails

The mailer supports multipart emails quite easily:


```ruby
# app/mailers/sample_mailer.rb
mailer :sample do
  email :email_with_parts do
    from '[admin@site.com](mailto:admin@site.com)'
    # …
    text_part { render('path/to/basic.text') }
    html_part render('path/to/basic.html') # shorter part syntax
  end
end
```

You can even specify multiple part types using the `provides` declaration:


```ruby
# app/mailers/sample_mailer.rb
mailer :sample do
  email :email_with_parts do
    from '[admin@site.com](mailto:admin@site.com)'
    # …
    # renders path/to/basic.html.erb and path/to/basic.plain.erb
    provides :plain, :html
    render 'path/to/basic'
  end
end
```


These will deliver a multipart/alternative email with the appropriate plain text and html sections.


## File Attachments

Using the mailer attaching files to a message is easy:


```ruby
# app/mailers/sample_mailer.rb
mailer :sample do
  email :email_with_files do
    from '[admin@site.com](mailto:admin@site.com)'
    # …
    body "Here are your files!"
    add_file :filename => 'somefile.png', :content =>
    File.open('/full/path/to/somefile.png', 'rb') { |f| f.read }
    add_file '/full/path/to/someotherfile.png'
  end
end
```


This will deliver your email with the appropriate body and the specified files attached.


## Defaults

To define mailer defaults for a message, we can do so app-wide or within a `mailer` block.


```ruby
# app/app.rb
# Application-wide mailer defaults
set :mailer_defaults, :from => '[admin@site.com](mailto:admin@site.com)'

# app/mailers/sample_mailer.rb
MyAppName.mailers :sample do
  defaults :content_type => 'html'
  email :registration do |name, age|
    # Uses default 'content_type' and 'from' values but can also overwrite
    them
    to '[user@domain.com](mailto:user@domain.com)'
    subject 'Welcome to the site!'
    locals :name => name
    render 'registration'
  end
end
```


Using defaults makes sending email even easier when certain attributes are repeated between messages.


## Rendering Variations

To render a short body inline:


```ruby
# app/mailers/sample_mailer.rb
mailer :sample do
  email :short_email do |name, user|
    # …
    body "This is a short body defined right in the mailer itself"
  end
end
```


To render a different template:


```ruby
# app/mailers/sample_mailer.rb
mailer :sample do
  email :custom_email do |name, user|
    # …
    render('path/to/template') # relative to views_path/mailers
  end
end
```

## Testing Email

You can configure the mailer so that it doesn't run during tests. This can be done with:


```ruby
# app/app.rb
configure :test do
 set :delivery_method, :test
end
```


In the `:test` environment, mail deliveries are stacked up in the `Mail::TestMailer.deliveries` array. As a convenience,
you may add the following to your test configuration:


```ruby
# test/test_config.rb
def pop_last_delivery
  Mail::TestMailer.deliveries.pop
end
```


Then, you can test email contents like this:


```ruby
it "sets the state to :complete and sends an email" do
  email = pop_last_delivery
  assert_equal("Thanks for registering", email.subject)
  assert_equal("[site@site.com](mailto:site@site.com)",
  email.from.first)
  assert_equal(@user.email, email.to.first)
end
```


## Using helpers in emails

You can use any helpers, included Padrino Helpers, inside your emails.


Just add some code like the following, we recommend you put it somewhere inside config/boot.rb, and you should be good
to go:


```ruby
Mail::Message.class_eval do
  include Padrino::Helpers::NumberHelpers
  include Padrino::Helpers::TranslationHelpers
end
```


Remember than you can still access Padrino, therefore you could use helpers like **url** to get a particular's url
formatted for you:


```ruby
Padrino.url(:users, :do_something)
```

