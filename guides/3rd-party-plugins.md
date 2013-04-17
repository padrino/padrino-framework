---
date: 2013-04-16
author: Ortuna
email: ortuna@gmail.com
title: 3rd Party Plugins
---
Padrino is a modular framework.  As such, you can leverage other libraries such as Sinatra libraries which
complement Padrino quite well.

##Rendering JSON with sinatra-contrib

First you must reference [sinatra-contrib](https://github.com/sinatra/sinatra-contrib) in your Gemfile:

```ruby
#Gemfile
source :rubygems

# Server requirements
# gem 'thin' # or mongrel
# gem 'trinidad', :platform => 'jruby'

# Project requirements
gem 'rake'
gem 'sinatra-flash', :require => 'sinatra/flash'

# Component requirements
gem 'haml'

# Test requirements

# Padrino Stable Gem
gem 'padrino', :path => '~/Desktop/code/padrino-framework'

# Or Padrino Edge
# gem 'padrino', :git => 'git://github.com/padrino/padrino-framework.git'

# Or Individual Gems
# %w(core gen helpers cache mailer admin).each do |g|
#   gem 'padrino-' + g, '0.10.7'
# end

gem 'sinatra-contrib'
```


You may use the #json method after you have registered the sinatra helper:

```ruby
class MyJsonApp < Padrino::Application
  register Padrino::Rendering
  register Padrino::Mailer
  register Padrino::Helpers


  helpers Sinatra::JSON

  enable :sessions
  get '/' do
    hash = {foo: 'bar'}
    json hash
  end
end
```
