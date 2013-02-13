---
author: Foo Bar
title: Running Padrino on JRuby
---

You can run Padrino on JRuby 1.6.2.

## Install on JRuby


You can easily install Padrino on JRuby when you use [rvm](https://rvm.beginrescueend.com/):


    $ rvm use -create jruby-1.6.2@padrino
    $ gem install padrino


Create Padrino project just as you do when using MRI or REE:


    $ padrino g project jrack-test


`cd ./jrack-test` and you should edit `Gemfile`:


```ruby
# JRuby deployment requirements
# please add these lines…
gem 'jruby-openssl'
gem 'jruby-rack'
gem 'warbler'
```

Now you can go:


    $ bundle


Then, create the test controller:



    $ padrino gen controller index get:index get:hello get:show_path


A controller sample is here:


```ruby
# index.rb
JrackTest.controllers :index do
  get :index do
  "Hello, JPadrino![]("
  end

  get :hello, :map => '/:id' do
  "Hello, #{params[:id]})"
  end

  get :show_path, :map => '/show-path/*urls' do
  "You accessed: #{params[:urls].inspect}"
  end
end
```


Then run:


    $ padrino start


You can access `http://localhost:3000` as you run Padrino on MRI.


## How to create WAR

Now you should have installed `warbler` gem, so you can:


    $ warble config

Edit `config/warble.rb` if you want to apply some customizations. You can access
[JRuby-Rack official README](https://github.com/nicksieger/jruby-rack/#readme) and
[Warbler rdoc](http://caldersphere.rubyforge.org/warbler/).


For example, if you want to deploy the app to server root directory, just add to `config/warble.rb`:


```ruby
config.jar_name = "ROOT"
```


If you are ready, run:


    $ warble war


You would get `jrack-test.war` (the same name as your project directory name), and you can deploy this war file to
tomcat! I tested on tomcat 6.0.20, and it works well with quick response.


## How to use jdbc mysql with Activerecord

Let's say you have a Padrino project set up to use the mysql SQL adapter and Activerecord as the database component. You
want to switch the adapter from the default mysql implementation to jdbc-mysql to take advantage of the native java jdbc
implementation. It's pretty straightforward.


Edit your `Gemfile` which probably starts something like this:


```ruby
source :rubygems

# Server requirements (defaults to WEBrick)
gem 'thin'
gem 'mongrel'


# Project requirements
gem 'rake'
gem 'sinatra-flash', :require => 'sinatra/flash'

# Component requirements
gem 'erubis', "~> 2.7.0"
gem 'activerecord', :require => "active_record"
gem 'mysql'

# JRuby deployment requirements
# please add these lines…
gem 'jruby-openssl'
gem 'jruby-rack'
gem 'warbler'
```


Replace the mysql gem with the gems for jdbc-mysql and activerecord jdbc mysql support. Your resulting `Gemfile` should
look like this:


```ruby
source :rubygems

# Server requirements
# gem 'thin'
# gem 'mongrel'

# Project requirements
gem 'rake'
gem 'sinatra-flash', :require => 'sinatra/flash'

# Component requirements
gem 'erubis', "~> 2.7.0"
gem 'activerecord', :require => "active_record"
# gem 'mysql'

# JRuby deployment requirements
# please add these lines…
gem 'jruby-openssl'
gem 'jruby-rack'
gem 'warbler'

# mysql-jdbc deployment requirements
gem "activerecord-jdbc-adapter", "1.2.0"
gem "activerecord-jdbcmysql-adapter", "1.2.0"
gem "jdbc-mysql", "~> 5.1.0"
```

Test your changes by creating some models/migrations:


    $ padrino g model post title:string body:text


and run the rake tasks:


    $ padrino rake ar:drop ar:create ar:migrate -trace


You should see something like this:


```ruby
=> Executing Rake ar:drop ar:create ar:migrate -trace.
*** Invoke ar:drop
*** Invoke environment (first_time)
*** Execute environment
*** Execute ar:drop
*** Invoke ar:create
*** Invoke environment
*** Execute ar:create
*** Invoke ar:migrate (first_time)
*** Invoke environment
*** Execute ar:migrate
  CreatePosts: migrating =
-- create_table(:posts, {:id=>true, :force=>true, :options=>"ENGINE=MyISAM"})
   -> 0.0910s
   -> 0 rows
 CreatePosts: migrated (0.0920s)

*** Invoke ar:schema:dump
*** Invoke environment
** Execute ar:schema:dump
```


You should now be set to use jdbc-mysql instead of the default mysql connector. This should allow you to use jndi
connections defined by application containers like jboss, thus offloading connection property management to the
container.


Here's a sample jndi connection section in `config/database.rb`:


```ruby
ActiveRecord::Base.configurations[:production] = {
 :adapter => 'jdbc',
 :jndi => 'java:jdbc/jndi_my_padrino_project',
 :driver => 'com.mysql.jdbc.Driver'

}
```

