---
date: 2011-05-10
author: DAddYE
email: d.dagostino@lipsiasoft.com
categories: Ruby, Faqs
tags: padrino, ruby, sinatra, omniauth
title: Padrino and OmniAuth Overview
---

In this post, we will show you how to mix our [Access Control](https://github.com/padrino/padrino-framework/blob/master/padrino-admin/lib/padrino-admin/access_control.rb) described [here](/guides/padrino-admin#admin-authentication) with the beautiful [omniauth](https://github.com/intridea/omniauth) rack middleware.

The Padrino admin authentication and access control system provides a simple foundation from which you can create your authentication system. Combined with [omniauth](https://github.com/intridea/omniauth) you can then easily leverage the system to allow authentication through a variety of methods. Read below for more details on how to integrate them.

<break>

In this article we’ll cover two topics:

1) Integrating Padrino Admin Authentication into all apps within your project
 2) Enabling custom authentication strategies within the authentication system

Before we begin, it is important to note that our integrated authentication based on project-roles can interact easily with other systems. The only files that need to be changed are `session.rb` and `account.rb` in order to add your own custom code.

So, let’s start by creating a project using activerecord:

    $ padrino g project foo --orm activerecord --tiny
    $ cd foo
    $ bundle install

Now we need to add a model called `Account` to act as our persistence model:

    $ padrino g model Account name:string email:string role:string uid:string provider:string

||
|name|the name of the account|
|email|the email of the account|
|role|the access control role|
|uid|omniauth uid|
|provider|omniauth provider|

Now we need to create and migrate our database:

    $ padrino rake ar:create ar:migrate

Open your favorite editor and browse and edit `Gemfile` and add `omniauth` gem and the providers for twitter and facebook. 
We also add the `haml` gem as it's not included by default in the "tiny" padrino template:

    # Gemfile
    gem 'omniauth'
    gem 'omniauth-twitter'
    gem 'omniauth-facebook'
    gem 'haml'

Now, run bundle install to install dependencies:

    $ bundle install

Now we need to add the `omniauth middleware`. Here you can choose two ways:

1) Add the middleware project-wide (so every subapp can use it)
 2) Add the middleware only to the one app that requires it

In our example, we need to edit simply `app/app.rb` and add:

    # app/app.rb
    use OmniAuth::Builder do
      provider :twitter,  'consumer_key', 'consumer_secret'
      provider :facebook, 'app_id', 'app_secret'
    end

If you are in a multiapp scenario you need to edit `config/boot.rb`:

    # config/boot.rb
    Padrino.use OmniAuth::Builder do
      provider :twitter,  'consumer_key', 'consumer_secret'
      provider :facebook, 'app_id', 'app_secret'
    end

    # before the line
    Padrino.load!

To obtain an app\_id and secret for Facebook, you need to:

-   Go to the [Facebook Developers Page](http://www.facebook.com/developers)
-   Browse and click [create a new app](http://www.facebook.com/developers/createapp.php)
-   Set your app name and complete the form…
-   One you finish that you are allowed to edit your settings, go to **website** section
-   Add to site url: `http://localhost:3000`
-   Add to domain: `localhost`
-   Write the **Application ID** and **Application Secret** to the `OmniAuth::Builder`

To obtain a consumer\_key and consumer\_secret for Twitter, you need to:

-   Go to [Twitter Applications Page](https://developer.twitter.com/apps/new)
-   Insert all details and be sure to check **Application Type: Browser**
-   Set a callback url with a valid domain ex: `www.mydomain.com/auth/twitter/callback`
-   Save and go to **Application Settings** and **Manage Domains**
-   Be sure that you can see your example domain: `www.mydomain.com/auth/twitter/callback`
-   Authorize domain: `localhost`
-   Now go to **Application Details** and save `Consumer key` and `Consumer Secret` to the `OmniAuth::Builder`

**NOTE**: For domain, it is not important that this path exist because `omniauth` changes the callback url.

Next, we can integrate our authentication system within in `app/app.rb`:

    # app/app.rb
    # at the top before the class definition
    register Padrino::Admin::AccessControl

    set :login_page, "/" # determines the url login occurs

    access_control.roles_for :any do |role|
      role.protect "/profile"
      role.protect "/admin" # here a demo path
    end

    # now we add a role for users
    access_control.roles_for :users do |role|
      role.allow "/profile"
    end

And add a couple useful routes, edit `app/controllers.rb` with:

    # app/controllers.rb
    get :index do
      haml <<-HAML.gsub(/^ {6}/, '')
        Login with
        =link_to('Facebook', '/auth/facebook')
        or
        =link_to('Twitter',  '/auth/twitter')
      HAML
    end

    get :profile do
      content_type :text
      current_account.to_yaml
    end

    get :destroy do
      set_current_account(nil)
      redirect url(:index)
    end

    get :auth, :map => '/auth/:provider/callback' do
      auth    = request.env["omniauth.auth"]
      account = Account.find_by_provider_and_uid(auth["provider"], auth["uid"]) || 
                Account.create_with_omniauth(auth)
      set_current_account(account)
      redirect "http://" + request.env["HTTP_HOST"] + url(:profile)
    end

We invoked a method `Account.create_with_omniauth` above, so edit `app/models/account.rb` and add:

    # app/models/account.rb
    def self.create_with_omniauth(auth)
      create! do |account|
        account.provider = auth["provider"]
        account.uid      = auth["uid"]
        account.email    = auth["name"]
        account.email    = auth["user_info"]["email"] if auth["user_info"] # we get this only from FB
        account.role     = "users"
      end
    end

That should just about do it! Let’s start the server:

    $ padrino start

Browse <http://localhost:3000/profile>

That will kickoff to the login\_page, in our case `/`.

Now you can login here <http://localhost:3000>

Follow your login process and then if needed <http://localhost:3000/destroy>

That is all you need to setup a barebones authentication system in Padrino. This post has gotten you started with a working “Account” and role based authentication solution with integrated omniauth support. From here, obviously there are a number of other features you might want to add on top to flesh out, and that is left for another post or as an exercise to the reader.

If you are interested in more Padrino information, check out [why you should use](http://www.padrinorb.com/pages/why) our framework and our [Blog Tutorial](http://www.padrinorb.com/guides/blog-tutorial) along with our other [Padrino Guides](http://www.padrinorb.com/guides).
