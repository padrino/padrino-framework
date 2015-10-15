---
date: 2015-10-15
author: Igor Bochkariov
email: ujifgc@gmail.com
title: Mounting Grape
---

Create your new project. It can be a regular one:

```
$ padrino g project gapp
```

Or a lean one if you don't want any Sinatra apps in it:

```
$ padrino g project gapp --lean
```

Go to the new `gapp` folder and add `gem 'grape'` to `Gemfile`. Then install the required gems:

```
$ bundle
```

Create file `api/api.rb` and put your Grape code there:

```
module Gapp
  class API < Grape::API
    get :hello do
      { hello: 'grape' }
    end

    get 'status' do
      cookies[:status_count] ||= 0
      cookies[:status_count] = cookies[:status_count].to_i + 1
      { status_count: cookies[:status_count] }
    end
  end
end
```

Go to file `config/apps.rb` and add to the end of it:

```
Padrino.mount('API', :app_file => Padrino.root('api/api.rb'), :app_class => 'Gapp::API').to('/master')
```

Now you can run `rackup` from your `gapp` folder and visit http://127.0.0.1:9292/master/hello or http://127.0.0.1:9292/master/status


```
<?xml version="1.0" encoding="UTF-8"?>
<hash>
  <hello>grape</hello>
</hash>
```

```
<?xml version="1.0" encoding="UTF-8"?>
<hash>
  <status-count type="integer">42</status-count>
</hash>
```
