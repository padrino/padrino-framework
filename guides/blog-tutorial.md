---
date: 2010-03-01
author: Nathan
email: nesquena@gmail.com
title: Blog Tutorial
---

When reading about a new framework, I often find that the best way to get familiar is to read a brief tutorial on how to develop a simple application. This can quickly give new users a sense of the development flow and processes involved in using a framework. This guide will show new users how to develop a simple blog using the Padrino framework. Along the way, each step will be explained and links will be provided to further information on different relevant topics.

 

## Screencast

[![](http://padrino.s3.amazonaws.com/screencast_1.png)](http://padrino.s3.amazonaws.com/screencast_1.mov)

There is also a screencast available for this tutorial. You can check it out by:

-   [Watching it on Vimeo](http://vimeo.com/10522357) (Low Resolution)
-   [Downloading the file](http://padrino.s3.amazonaws.com/screencast_1.mov) (211 Mb, 12:00 in [Quicktime](http://www.apple.com/quicktime/download))

There is a poll on [PeepCode](http://suggestions.peepcode.com/forums/15-general/suggestions/1064769-padrino) so please [VOTE](http://suggestions.peepcode.com/forums/15-general/suggestions/1064769-padrino) for our new [Screencast](http://suggestions.peepcode.com/forums/15-general/suggestions/1064769-padrino) !

 

## Study Guide

To skip this tutorial or immediately see the complete blog tutorial project, you can either checkout the [blog tutorial repository](http://github.com/padrino/sample_blog) using Git:

    $ git clone git://github.com/padrino/sample_blog.git

or even execute the [blog tutorial project template](http://gist.github.com/357045) which will automatically build the blog project step by step using our excellent template runner. You can do this simply by invoking:

    $ padrino g project sample_blog --template sampleblog

To learn more about our template generator, be sure to check out the the [generators guide](/guides/generators).

 

## Installation

In order to develop a Padrino application, we must have a few things installed. First, we must obviously have [ruby](http://www.ruby-lang.org/en/) and [rubygems](http://rubygems.org/) installed. Next, we must install the padrino framework gems:

    $ gem install padrino

For more details on installation, check out the [installation guide](/guides/installation). Once this has been finished, all necessary dependencies should be ready and we can begin developing our sample blog.

 

## Project Generation

To create a Padrino application, the best place to start is using the convenient Padrino generator. Similar to Rails, Padrino has a project generator which will create a skeleton application with all the files you need to being development of your new idea. Padrino is an agnostic framework and supports using a variety of different template, testing, JavaScript and database components. You can learn more by reading the [generators guide](/guides/generators).

For this sample application, we will use the ActiveRecord ORM, the Haml templating language, the Shoulda testing framework and the jQuery JavaScript library. With that in mind, let us generate our new project:

    $ padrino g project sample_blog -t shoulda -e haml -c sass -s jquery -d activerecord -b

This command will generate our basic Padrino project and the print out a nice report of the files generated. The output of this generation command can be viewed in [this gist](http://gist.github.com/337148) file. Notice the `-b` flag in the previous command which automatically instructs bundler to install all dependencies. All we need to do now is `cd` into our brand new application.

    $ cd sample_blog

Now, the terminal should be inside the root of our newly generated application with all necessary gem dependencies installed. Let us take a closer look at the particularly important generated files before we continue on with development.

-   `Gemfile` – Be sure to include any necessary gem dependencies for your app in this file!
-   `app/app.rb` – This is the primary configuration file for your core application.
-   `config/apps.rb` – This defines which applications are mounted in your project.
-   `config/database.rb` – This defines the connection details for your chosen database adapter.

The following important directories are also generated:

-   `app/controllers` – This is where the Padrino route definitions should be defined.
-   `app/helpers` – This is where helper methods should be defined for your application.
-   `app/views` – This should contain your template views to be rendered in a controller.
-   `lib` – This should contain any extensions, libraries or other code to be used in your project.
-   `public` – This is where images, style sheets and JavaScript files should be stored.
-   `test` – This is where your model and controller tests should be stored.

Now, let us examine the `config/database.rb` file to make sure the database connection settings are correct. For now, the defaults are OK for this tutorial. A sqlite3 database will be used that is stored inside `db/sample_blog_development.db`.

Let us also setup a few simple routes in our application to demonstrate the Padrino routing system. Let’s go into the `app/app.rb` file and enter the following routes:

    # app/app.rb
    module SampleBlog
      class App < Padrino::Application
        register SassInitializer
        use ActiveRecord::ConnectionAdapters::ConnectionManagement
        register Padrino::Rendering
        register Padrino::Mailer
        register Padrino::Helpers
          
        enable :sessions
          
        # Add these routes below to the app file...
        get "/" do
          "Hello World!"
        end
    
        get :about, :map => '/about_us' do
          render :haml, "%p This is a sample blog created to demonstrate how Padrino works!"
        end
      end
    end

Note that the first route here sets up a simple string to be returned at the root URL of the application. The second route defines a one-line ‘about’ page inline using Haml which is then explicitly mapped to the ‘/about\_us’ URL. The symbol `:about` is used to reference the route later.

Be sure to check out the [controllers guide](/guides/controllers) for a comprehensive overview of the routing system.

 

## Admin Dashboard Setup

Next, this is a good time to setup the Padrino Admin panel which allows us to easily view, search and modify data for a project. Let’s go back to the console and enter:

    sample_blog $ padrino g admin
    sample_blog $ bundle install

This will create the admin sub-application within your project and mount it within the `config/apps.rb` file. The output of this command can be viewed in [this gist](http://gist.github.com/324298) file.

Now, we should follow the instructions and create our database, run our migrations and run the seed tasks which has been generated in `db/seeds.rb`. Go to the terminal and run:

    sample_blog $ padrino rake ar:create
    sample_blog $ padrino rake ar:migrate
    sample_blog $ padrino rake seed

During this process, you will be prompted to enter an email and password to use for the admin dashboard. Be sure to remember this for use later in development.

To read more about the features of the admin panel, check out the [Admin Panel Guide](/guides/padrino-admin).

 

## Booting Padrino

Now the Padrino project has been generated, the database has been configured and created and the admin panel has been properly setup. We can now start up our Padrino application server. This is quite easy to do with the built-in Padrino tasks. Simply execute the following in the terminal:

    sample_blog $ padrino start

You should see no errors, and the terminal should output:

    => Located unlocked Gemfile for development
    => Padrino/0.10.2 has taken the stage development on port 3000
    >> Thin web server (v1.2.7 codename This Is Not A Web Server)
    >> Maximum connections set to 1024
    >> Listening on localhost:3000, CTRL+C to stop

To read more about available terminal commands, checkout the [Development and Terminal Commands](/guides/development-commands) guide.

Your application now exists on <http://localhost:3000>. Visit this URL in the browser and you should see the route render `Hello World!` route that we defined earlier in this tutorial. We can also visit the admin panel by going to the URL:

<http://localhost:3000/admin>

and then log in using the admin credentials specified during the `rake seed` command performed earlier. Feel free to explore this area and checkout the existing accounts. We will come back to this in more detail later. To read more about the features of the admin panel, check out the [Admin Panel Guide](/guides/padrino-admin).

Worth noting here is that Padrino has full support for code reloading in development mode. This means you can keep the Padrino server running and change your code source and when you refresh in the browser, the changes will be automatically displayed. You might want to open up a new terminal and `cd` to your directory and keep the server running.

 

## Creating Posts

Now that the application is ready and the layouts have been defined, let’s implement the functionality to view our blog posts and even add the ability to create new posts!

Let’s start off by generating the model into our app directory. As of version **0.10.0**, the models will default to generating at the top level ‘models’ directory in a project. We can specify the location by appending the -a option which will generate the models into the designated sub-app directory.

    sample_blog $ padrino g model post title:string body:text -a app
    => Located unlocked Gemfile for development
    create  app/models/post.rb
    create  test/models/post_test.rb
    create  db/migrate/002_create_posts.rb

Let’s add a timestamp for the Post Model in the migration.

    # db/migrate/002_create_posts.rb
    class CreatePosts < ActiveRecord::Migration
      def self.up
        create_table :posts do |t|
          t.string :title
          t.text :body
          t.timestamps
        end
      end

      def self.down
        drop_table :posts
      end
    end

Go ahead and migrate the database now.

    sample_blog $ padrino rake ar:migrate
    => Executing Rake ar:migrate ...
    ==  CreatePosts: migrating ====================================================
    -- create_table("posts", {})
    ==  CreatePosts: migrated (0.0016s) ===========================================

This creates the post model. Next, let’s create the controller to allow the basic viewing functionality.

    sample_blog $ padrino g controller posts get:index get:show
    => Located unlocked Gemfile for development
    create  app/controllers/posts.rb
    create  app/helpers/posts_helper.rb
    create  app/views/posts
    create  test/controllers/posts_controller_test.rb

We’ll want to attached some of the standard routes (:index and :show) to the controller.

    # app/controllers/posts.rb
    SampleBlog::App.controllers :posts do
      get :index do
        @posts = Post.all(:order => 'created_at desc')
        render 'posts/index'
      end
      
      get :show, :with => :id do
        @post = Post.find_by_id(params[:id])
        render 'posts/show'
      end
    end

This controller is defining routes that can be accessed via our application. The “http method” `get` starts off the declaration followed by a symbol representing the “action”. Inside a block we store an instance variable fetching the necessary objects and then render a view template. This should look familiar to those coming from Rails or Sinatra.

Next, we’ll want to create the views for the two controller actions we defined: `index` and `show`.

    # app/views/posts/index.haml
    - @title = "Welcome"

    #posts= partial 'posts/post', :collection => @posts

    # app/views/posts/_post.haml
    .post
      .title= link_to post.title, url_for(:posts, :show, :id => post)
      .date= time_ago_in_words(post.created_at || Time.now) + ' ago'
      .body= simple_format(post.body)

    # app/views/posts/show.haml
    - @title = @post.title
    #show
      .post
        .title= @post.title
        .date= time_ago_in_words(@post.created_at || Time.now) + ' ago'
        .body= simple_format(@post.body)    
    %p= link_to 'View all posts', url_for(:posts, :index)

Padrino Admin makes it easy to create, edit and delete records automatically. To manage posts using Padrino Admin, run this command.

    sample_blog $ padrino g admin_page post
    => Located unlocked Gemfile for development
    create  admin/controllers/posts.rb
    create  admin/views/posts/_form.haml
    create  admin/views/posts/edit.haml
    create  admin/views/posts/index.haml
    create  admin/views/posts/new.haml
    inject  admin/app.rb

Let’s make sure the server is running (`padrino start`) and give this admin interface a try.

Visit <http://localhost:3000/admin> and login using the credentials you had setup during the seed.

There should now be two tabs, one for Posts and the other, Accounts. Click on Posts.

Padrino Admin allows you to easily create new records by clicking “New”. It has a form all ready complete with the fields you had generated prior in the creation of the Post model.

**Note:** make sure to use `padrino g admin_page` **after** the creation of your model and their migration.

Now that you have added a few posts through the admin interface, check out <http://localhost:3000/posts> and notice that the posts you created now show up in the “index” action!

You can see all the routes that we now have defined using the `padrino rake routes` command:

    $ padrino rake routes
        URL                 REQUEST  PATH
        (:about)              GET    /about_us
        (:posts, :index)      GET    /posts
        (:posts, :show)       GET    /posts/show/:id

This can be helpful to understand the mapping between controllers and urls.

 

## Attaching Accounts to Posts

So far, a post does not have a user associated as the author. Suppose that now we want to let every post have an author. Let’s revisit our post model. We’ll start by adding a new migration to attach an Account to a Post.

    sample_blog $ padrino g migration AddAccountToPost account_id:integer
    => Located unlocked Gemfile for development
    create  db/migrate/003_add_account_to_post.rb

This creates a new migration with the desired field attaching the account\_id to the post.

Let’s modify the migration file to assign a user to all existing posts:

    # db/migrate/003_add_account_to_post.rb
    class AddAccountToPost < ActiveRecord::Migration
      def self.up
        change_table :posts do |t|
          t.integer :account_id
        end
        # and assigns a user to all existing posts
        first_account = Account.first
        Post.all.each { |p| p.update_attribute(:account, first_account) }
      end 
      # ...
    end

Now, we’ll return to the Post Model to setup the `account` association and add a few validations.

    # app/models/post.rb
    class Post < ActiveRecord::Base
      belongs_to :account
      validates_presence_of :title
      validates_presence_of :body
    end

Every time we change the database, we need to migrate the database.

    sample_blog $ padrino rake ar:migrate
    ==  AddAccountToPost: migrating ===============================================
    -- change_table(:posts)
    ==  AddAccountToPost: migrated (0.0009s) ====================================== 7:04
    => Executing Rake ar:migrate ...

Our Post now has the appropriate associations and validations. We’ll need to go inside the generated Padrino Admin and make some changes to include the account with the post.

Head on over to `admin/controllers/posts.rb`. We’re going to include the `current_account` to the creation of a new Post.

    # admin/controllers/posts.rb
    Admin.controllers :posts do
    # ...
      post :create do
        @post = Post.new(params[:post])
        @post.account = current_account
        if @post.save
          @title = pat(:create_title, :model => "post #{@post.id}")
          flash[:success] = pat(:create_success, :model => 'Post')
          params[:save_and_continue] ? redirect(url(:posts, :index)) : redirect(url(:posts, :edit, :id => @post.id))
        else
          @title = pat(:create_title, :model => 'post')
          flash.now[:error] = pat(:create_error, :model => 'post')
          render 'posts/new'
        end
      end
    # ...
    end

We’ll also update the post view to show the changes that we made and display the author:

    # app/views/posts/show.haml
    - @title = @post.title
    #show
      .post
        .title= @post.title
        .date= time_ago_in_words(@post.created_at || Time.now) + ' ago'
        .body= simple_format(@post.body)
        .details
          .author Posted by #{@post.account.email}
    %p= link_to 'View all posts', url_for(:posts, :index)

    # app/views/posts/_post.haml
    .post
      .title= link_to post.title, url_for(:posts, :show, :id => post)
      .date= time_ago_in_words(post.created_at || Time.now) + ' ago'
      .body= simple_format(post.body)
      .details
        .author Posted by #{post.account.email}

Now, lets add another user. Revisit <http://localhost:3000/admin> and click on the Account tab. Now create a new Account record. Once you have a new account, try logging into it and then adding one more post in the admin interface. There you have it, multiple users and posts!

See the effects of our changes by visiting <http://localhost:3000/posts> to see our newly created posts linked to the author that wrote them.

 

## Site Layout

Now that the application has been properly configured and the server has been started, let’s create a few basic styles and define a layout to prepare the application for continued development.

First, let us create a layout for our application to use. A layout is a file that acts as a container for the content templates yielded by each route. The layout should be used to create a consistent structure between each page of the application. To create a layout, simply add a file to the `app/views/layouts` directory:

    # app/views/layouts/application.haml
    !!! Strict
    %html
      %head
        %title= [@title, "Padrino Sample Blog"].compact.join(" | ")
        = stylesheet_link_tag 'reset', 'application'
        = javascript_include_tag 'jquery', 'application'
        = yield_content :include
      %body
        #header
          %h1 Sample Padrino Blog
          %ul.menu
            %li= link_to 'Blog', url_for(:posts, :index)
            %li= link_to 'About', url_for(:about)
        #container
          #main= yield
          #sidebar
            = form_tag url_for(:posts, :index), :method => 'get'  do
              Search for:
              = text_field_tag 'query', :value => params[:query]
              = submit_tag 'Search'
            %p Recent Posts
            %ul.bulleted
              %li Item 1 - Lorem ipsum dolorum itsum estem
              %li Item 2 - Lorem ipsum dolorum itsum estem
              %li Item 3 - Lorem ipsum dolorum itsum estem
            %p Categories
            %ul.bulleted
              %li Item 1 - Lorem ipsum dolorum itsum estem
              %li Item 2 - Lorem ipsum dolorum itsum estem
              %li Item 3 - Lorem ipsum dolorum itsum estem
            %p Latest Comments
            %ul.bulleted
              %li Item 1 - Lorem ipsum dolorum itsum estem
              %li Item 2 - Lorem ipsum dolorum itsum estem
              %li Item 3 - Lorem ipsum dolorum itsum estem
        #footer
          Copyright (c) 2009-2010 Padrino

This layout creates a basic structure for the blog and requires the necessary stylesheets and javascript files for controlling the behavior and presentation of our site. The layout also includes some dummy elements such as a fake search and stubs for list items left as an exercise for the reader.

Next, we simply need to setup the style sheets. There are two we will use for this demo. The first is a generic CSS reset by Eric Meyers. The [full reset style sheet](http://github.com/padrino/sample_blog/blob/master/public/stylesheets/reset.css) can be found in the [sample blog repository](http://github.com/padrino/sample_blog/blob/master/public/stylesheets/reset.css) and should be put into `public/stylesheets/reset.css`.

The second style sheet is the application style sheet to give our blog a better look and feel. The [full contents of the style sheet](http://github.com/padrino/sample_blog/blob/master/app/stylesheets/application.sass) can be found in the [sample blog repository](http://github.com/padrino/sample_blog/blob/master/app/stylesheets/application.sass) and should be put into `app/stylesheets/application.sass`.

With the layout and these two stylesheets in place, the blog will now have a much improved look and feel! See the new style by visiting <http://localhost:3000/posts>.

 

## Generating RSS Feed for Posts

Finally, before the application is deployed, let’s set up RSS and Atom feeds for our new blog so people can subscribe to our posts. For the feeds, we’re going to head back to the posts controller and make a few changes by appending a `provides` option to our `index` block. This command below instructs the route that it should respond to HTML, RSS and Atom formats.

    # app/controllers/posts.rb
    SampleBlog::App.controllers :posts do
    ...
      get :index, :provides => [:html, :rss, :atom] do
        @posts = Post.all(:order => 'created_at desc')
        render 'posts/index' 
      end
    ...
    end

Note that this route also instructs the rendering engine to avoid rendering the layout when using RSS or atom formats.

Back in the `index.haml` file, we’ll use the auto\_discovery\_link\_tag helpers to generate the RSS feed using builder.

    # app/views/posts/index.haml
    - @title = "Welcome"

    - content_for :include do
      = feed_tag(:rss, url(:posts, :index, :format => :rss),:title => "RSS")
      = feed_tag(:atom, url(:posts, :index, :format => :atom),:title => "ATOM")

    #posts= partial 'posts/post', :collection => @posts

Next, let us add the templates for atom using builder templates:

    # app/views/posts/index.atom.builder
    xml.instruct!
    xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do
      xml.title   "Padrino Sample Blog"
      xml.link    "rel" => "self", "href" => url_for(:posts, :index)
      xml.id      url_for(:posts, :index)
      xml.updated @posts.first.updated_at.strftime "%Y-%m-%dT%H:%M:%SZ" if @posts.any?
      xml.author  { xml.name "Padrino Team" }

      @posts.each do |post|
        xml.entry do
          xml.title   post.title
          xml.link    "rel" => "alternate", "href" => url_for(:posts, :show, :id => post)
          xml.id      url_for(:posts, :show, :id => post)
          xml.updated post.updated_at.strftime "%Y-%m-%dT%H:%M:%SZ"
          xml.author  { xml.name post.account.email }
          xml.summary post.body
        end
      end
    end

and also the template for rss using builder:

    # app/views/posts/index.rss.builder
    xml.instruct!
    xml.rss "version" => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1/" do
      xml.channel do
        xml.title "Padrino Blog"
        xml.description "The fantastic padrino sample blog"
        xml.link url_for(:posts, :index)

        for post in @posts
          xml.item do
            xml.title post.title
            xml.description post.body
            xml.pubDate post.created_at.to_s(:rfc822)
            xml.link url_for(:posts, :show, :id => post)
          end
        end
      end
    end

Let’s check out our changes. View the available feeds at <http://localhost:3000/posts> . You now have rss and atom feeds available for your blog!

 

## Deploying our Application

Finally, our basic blog has been built and we should deploy our application so the world can check it out! The easiest way to do this quickly and for free is to use a service such as Heroku. Let’s deploy our application to Heroku right now.

The best way to get started using Heroku is by following the [Heroku Quickstart Guide](http://docs.heroku.com/quickstart) . As explained in the guide, be sure to have Git installed and [setup a Heroku account](http://heroku.com/signup) as well as [install the Heroku gem](http://docs.heroku.com/heroku-command) before continuing this tutorial.

Now, to deploy to Heroku, the application needs to be set up as a Git repository:

    sample_blog $ git init
    sample_blog $ git add .
    sample_blog $ git commit -m "initial commit for app"

This initializes the Git repository, adds all the contents and commit them to the repo. Next, the application must be set up on Heroku.

    sample-blog $ heroku create --stack bamboo-ree-1.8.7
    sample-blog $ git push heroku master

That’s it, your app is now running on Heroku!

Run `heroku open` to open your site in your default web browser.

Currently Padrino defaults to **SQLite** but Heroku only supports **PostgreSQL**, so we’ll need to add `pg` as a dependency.

    # Gemfile
    group :production do
     gem 'pg'
    end

Now you can run the following on your local machine to avoid the installation of the `pg` gem:

    sample-blog $ bundle install --without production

It’s also necessary to configure the `config/database.rb` for production.

    # config/database.rb
    postgres = URI.parse(ENV['DATABASE_URL'] || '')

    ActiveRecord::Base.configurations[:production] = {
      :adapter  => 'postgresql',
      :encoding => 'utf8',
      :database => postgres.path[1..-1], 
      :username => postgres.user,
      :password => postgres.password,
      :host     => postgres.host
    }

Now we need to create a Rakefile since we don’t have shell access to `padrino rake`. Simply use the handy Rakefile generator:

    $ padrino rake gen

And a Rakefile will be generated automatically that looks like this:

    # Rakefile
    require 'bundler/setup'
    require 'padrino-core/cli/rake'

    PadrinoTasks.use(:database)
    PadrinoTasks.use(:activerecord)
    PadrinoTasks.init

Finally we need to tweak our `seed.rb`:

    # db/seeds.rb
    email     = "info@padrinorb.com"
    password  = "admin"

    shell.say ""

    account = Account.create(:email => email, 
                             :name => "Foo", 
                             :surname => "Bar", 
                             :password => password, 
                             :password_confirmation => password, 
                             :role => "admin")

    if account.valid?
      shell.say "================================================================="
      shell.say "Account has been successfully created, now you can login with:"
      shell.say "================================================================="
      shell.say "   email: #{email}"
      shell.say "   password: #{password}"
      shell.say "================================================================="
    else
      shell.say "Sorry but some thing went worng!"
      shell.say ""
      account.errors.full_messages.each { |m| shell.say "   - #{m}" }
    end

    shell.say ""

Feel free to change the seed values above.

Now run the following in the console:

    sample_blog $ git add .
    sample_blog $ git commit -m "Added Postgres support"
    sample_blog $ git push heroku master

Now run our `migrations/seeds`:

    sample_blog $ heroku rake ar:migrate
    sample_blog $ heroku rake seed

You’ll see something like:

    sample_blog $ heroku rake ar:migrate
    (in /disk1/home/slugs/151491_a295681_03f1/mnt)
    => Located locked Gemfile for production
    ==  CreateAccounts: migrating =================================================
    -- create_table("accounts", {})
       -> 0.0185s
    ==  CreateAccounts: migrated (0.0229s) ========================================

    ==  CreatePosts: migrating ====================================================
    -- create_table("posts", {})
       -> 0.0178s
    ==  CreatePosts: migrated (0.0218s) ===========================================

    ==  AddAccountToPost: migrating ===============================================
    -- change_table(:posts)
       -> 0.0026s
    ==  AddAccountToPost: migrated (0.0028s) ======================================

    MacBook:sample_blog DAddYE$ heroku rake seed
    (in /disk1/home/slugs/151491_7576c59_03f1/mnt)
    => Located locked Gemfile for production

    =================================================================
    Account has been successfully created, now you can login with:
    =================================================================
       email: info@padrinorb.com
       password: admin
    =================================================================

Now let’s open our newly deployed app:

    sample_blog $ heroku open

Enjoy!
