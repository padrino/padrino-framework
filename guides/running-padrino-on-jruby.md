---
date: 2011-06-06
author: Uchio
email: udzura@udzura.jp
title: Running Padrino on JRuby
---

You can run Padrino (0.9.29 / 0.10.3 is tested) on JRuby 1.6.4.

 

## Install on JRuby

You can easily install Padrino on jruby when you use [rvm](https://rvm.beginrescueend.com/) :

    $ rvm use --create jruby-1.6.4@padrino
    $ gem install padrino

Create Padrino project just as you do when using MRI or REE:

    $ padrino g project jrack-test

`cd ./jrack-test` and you should edit `Gemfile`:

    # JRuby deployment requirements
    # please add these lines...
    gem 'jruby-openssl'
    gem 'jruby-rack'
    gem 'warbler'

Now you can go:

    $ bundle

Then, create the test controller:

    padrino gen controller index get:index get:hello get:show_path

A controller sample is here:

    # index.rb
    JrackTest.controllers :index do
      get :index do
        "Hello, JPadrino!"
      end
      
      get :hello, :map => '/:id' do
        "Hello, #{params[:id]}!"
      end
      
      get :show_path, :map => '/show-path/*urls' do
        "You accessed: #{params[:urls].inspect}"
      end
    end

Then run:

    padrino start

To run JRuby on 1.9 compat mode:

    alias padrino='jruby --1.9 -S padrino'
    padrino start

You can access `localhost:3000` as you run padrino on MRI…

 

## How to create WAR

Now you should have installed `warbler` gem, so you can:

    warble config

Edit `config/warble.rb` if you want to apply some customizations. You can access [JRuby-Rack official README](https://github.com/nicksieger/jruby-rack/#readme) and [Warbler rdoc](http://caldersphere.rubyforge.org/warbler/).

For example, if you want to deploy the app to server root directory, just add to `config/warble.rb`:

      config.jar_name = "ROOT"

Deploying with JRuby on 1.9 compat mode:

      config.webxml.jruby.compat.version = "1.9"

If you are ready, run:

    warble war

You would get `jrack-test.war` (the same name as your project diresctory name), and you can deploy this war file to tomcat! I tested on tomcat 6.0.20, and it works well with quick response.