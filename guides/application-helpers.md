---
date: 2010-03-01
author: Nathan
email: nesquena@gmail.com
title: Application Helpers
---

This component provides a great deal of view helpers related to html markup generation. There are helpers for generating tags, forms, links, images, and more. Most of the basic methods should be very familiar to anyone who has used rails view helpers.

 

## Output Helpers

Output helpers are a collection of important methods for managing, capturing and displaying output in various ways and is used frequently to support higher-level helper functions. There are three output helpers worth mentioning: `content_for`, `capture_html`, and `concat_content`

The content\_for functionality supports capturing content and then rendering this into a different place such as within a layout. One such popular example is including assets onto the layout from a template:

    # app/views/site/index.erb
    ...
    <% content_for :assets do %>
      <%= stylesheet_link_tag 'index', 'custom' %>
    <% end %>
    ...

Added to a template, this will capture the includes from the block and allow them to be yielded into the layout:

    # app/views/layout.erb
    ...
    <head>
      <title>Example</title>
      <%= stylesheet_link_tag 'style' %>
      <%= yield_content :assets %>
    </head>

This will automatically insert the contents of the block (in this case a stylesheet include) into the location the content is yielded within the layout.

You can also check if a `content_for` block exists for a given key using `content_for?`:

    # app/views/layout.erb
    <% if content_for?(:assets) %>  
      <div><%= yield_content :assets %></div<
    <% end %>

The `capture_html` and the `concat_content` methods allow content to be manipulated and stored for use in building additional helpers accepting blocks or displaying information in a template. One example is the use of these in constructing a simplified ‘form\_tag’ helper which accepts a block.

    # form_tag '/register' do ... end
    def form_tag(url, options={}, &block)
      # ... truncated ...
      inner_form_html = capture_html(&block)
      concat_content '<form>' + inner_form_html + '</form>'
    end

This will capture the template body passed into the form\_tag block and then append the content to the template through the use of `concat_content`. Note have been built to work for both haml and erb templates using the same syntax.

The list of defined helpers in the ‘output helpers’ category:

-   `content_for(key, &block)`
    -   Capture a block of content to be rendered at a later time.
    -   Existence can be checked using the `content_for?(key)` method.
    -   `content_for(:head) { …content… }`
    -   Also supports arguments passed to the content block
    -   `content_for(:head) { |param1, param2| …content… }`

-   `yield_content(key, *args)`
    -   Render the captured content blocks for a given key.
    -   `yield_content :head`
    -   Also supports arguments yielded to the content block
    -   `yield_content :head, param1, param2`

-   `capture_html(*args, &block)`
    -   Captures the html from a block of template code for erb or haml
    -   `capture_html(&block)` =\> “…html…”

-   `concat_content(text="")`
    -   Outputs the given text to the templates buffer directly in erb or haml
    -   `concat_content(“This will be output to the template buffer in erb or haml”)`

 

## Tag Helpers

Tag helpers are the basic building blocks used to construct html ‘tags’ within a view template. There are three major functions for this category: `tag`, `content_tag` and `input_tag`.

The tag and content\_tag are for building arbitrary html tags with a name and specified options. If the tag contains ‘content’ within then `content_tag` is used. For example:

The input\_tag is used to build tags that are related to accepting input from the user:

    input_tag :text, :class => "demo" # => <input type='text' class='demo' />
    input_tag :password, :value => "secret", :class => "demo"

Note that all of these accept html options and result in returning a string containing html tags.

The list of defined helpers in the ‘tag helpers’ category:

-   `tag(name, options=nil, open=false)`
    -   Creates an html tag with the given name and options
    -   `tag(:br, :style => ‘clear:both’, :open => true)` =\> `<br style="clear:both">`

-   `content_tag(name, content, options=nil, &block)`
    -   Creates an html tag with given name, content and options
    -   `content_tag(:p, “demo”, :class => ‘light’)` =\> `<p class="light">demo</p>`
    -   `content_tag(:p, :class => ‘dark’) { …content… }` =\> `<p class="dark">...content...</p>`

-   `input_tag(type, options = {})`
    -   Creates an html input field with given type and options
    -   `input_tag :text,     :class => “demo”`
    -   `input_tag :password, :value => “secret”, :class => “demo”`

 

## Asset Helpers

Asset helpers are intended to help insert useful html onto a view template such as ‘flash’ notices, hyperlinks, mail\_to links, images, stylesheets and javascript. An example of their uses would be on a simple view template:

    # app/views/example.haml
    ...
    %head
      = stylesheet_link_tag 'layout'
      = javascript_include_tag 'application'
      = favicon_tag 'images/favicon.png'
    %body
      ...
      = flash_tag :notice
      %p= link_to 'Blog', '/blog', :class => 'example'
      %p Mail me at #{mail_to 'fake@faker.com', "Fake Email Link", :cc => "test@demo.com"}
      %p= image_tag 'padrino.png', :width => '35', :class => 'logo'

The list of defined helpers in the ‘asset helpers’ category:

-   `flash_tag(kind, options={})`
    -   Creates a div to display the flash of given type if it exists
    -   `flash_tag(:notice, :class => ‘flash’, :id => ‘flash-notice’)`

-   `link_to(*args, &block)`
    -   Creates a link element with given name, url and options
    -   `link_to ‘click me’, ‘/dashboard’, :class => ‘linky’`
    -   `link_to ‘click me’, ‘/dashboard’, :class => ‘linky’, :if => @foo.present?`
    -   `link_to ‘click me’, ‘/dashboard’, :class => ‘linky’, :unless => @foo.blank?`
    -   `link_to ‘click me’, ‘/dashboard’, :class => ‘linky’, :unless => :current`
    -   `link_to(‘/dashboard’, :class => ‘blocky’) { …content… }`

-   `mail_to(email, caption=nil, mail_options={})`
    -   Creates a mailto link tag to the specified email\_address
    -   `mail_to “me@demo.com”`
    -   `mail_to “me@demo.com”, “My Email”, :subject => “Feedback”, :cc => ‘test@demo.com’`

-   `image_tag(url, options={})`
    -   Creates an image element with given url and options
    -   `image_tag(‘icons/avatar.png’)`

-   `stylesheet_link_tag(*sources)`
    -   Returns a stylesheet link tag for the sources specified as arguments
    -   `stylesheet_link_tag ‘style’, ‘application’, ‘layout’`

-   `javascript_include_tag(*sources)`
    -   Returns an html script tag for each of the sources provided.
    -   `javascript_include_tag ‘application’, ‘special’`

-   `favicon_tag(source, options={})`
    -   Returns a favicon tag for the header for the source specified.
    -   `favicon_tag ‘images/favicon.ico’, :type => ‘image/ico’`

-   `feed_tag(mime,source, options={})`
    -   Returns a feed tag for the mime and source specified
    -   `feed_tag :atom, url(:blog, :posts, :format => :atom), :title => “ATOM”`

By default, all ‘assets’ including images, scripts, and stylesheets have a timestamp appended at the end to clear the stale cache for the item when modified. To disable this, simply put the setting `disable :asset_stamp` in your application configuration within `app/app.rb`.

 

## Form Helpers

Form helpers are the ‘standard’ form tag helpers you would come to expect when building forms. A simple example of constructing a non-object form would be:

    # app/views/example.haml
    = form_tag '/destroy', :class => 'destroy-form', :method => 'delete' do
      = flash_tag(:notice)
      = field_set_tag do
        %p
          = label_tag :username, :class => 'first'
          = text_field_tag :username, :value => params[:username]
        %p
          = label_tag :password, :class => 'first'
          = password_field_tag :password, :value => params[:password]
        %p
          = label_tag :strategy
          = select_tag :strategy, :options => ['delete', 'destroy'], :selected => 'delete'
        %p
          = check_box_tag :confirm_delete
      = field_set_tag(:class => 'buttons') do
        = submit_tag "Remove"

The list of defined helpers in the ‘form helpers’ category:

-   `form_tag(url, options={}, &block)`
    -   Constructs a form without object based on options
    -   Supports form methods ‘put’ and ‘delete’ through hidden field
    -   `form_tag(‘/register’, :class => ‘example’) { … }`

-   `field_set_tag(*args, &block)`
    -   Constructs a field\_set to group fields with given options
    -   `field_set_tag(:class => ‘office-set’) { }`
    -   `field_set_tag(“Office”, :class => ‘office-set’) { }`

-   `error_messages_for(:record, options={})`
    -   Constructs list html for the errors for a given object
    -   `error_messages_for :user`

-   `label_tag(name, options={}, &block)`
    -   Constructs a label tag from the given options
    -   `label_tag :username, :class => ‘long-label’`
    -   `label_tag(:username, :class => ‘blocked-label’) { … }`

-   `hidden_field_tag(name, options={})`
    -   Constructs a hidden field input from the given options
    -   `hidden_field_tag :session_key, :value => ‘secret’`

-   `text_field_tag(name, options={})`
    -   Constructs a text field input from the given options
    -   `text_field_tag :username, :class => ‘long’`

-   `text_area_tag(name, options={})`
    -   Constructs a text area input from the given options
    -   `text_area_tag :username, :class => ‘long’`

-   `password_field_tag(name, options={})`
    -   Constructs a password field input from the given options
    -   `password_field_tag :password, :class => ‘long’`

-   `number_field_tag(name, options={})`
    -   Constructs a number field input from the given options
    -   `number_field_tag :age, :class => ‘long’`

-   `telephone_field_tag(name, options={})`
    -   Constructs a phone field input from the given options
    -   `telephone_field_tag :mobile, :class => ‘long’`

-   `email_field_tag(name, options={})`
    -   Constructs a email field input from the given options
    -   `email_field_tag :email, :class => ‘long’`

-   `search_field_tag(name, options={})`
    -   Constructs a search field input from the given options
    -   `search_field_tag :query, :class => ‘long’`

-   `url_field_tag(name, options={})`
    -   Constructs a url field input from the given options
    -   `url_field_tag :image_source_url, :class => ‘long’`

-   `check_box_tag(name, options={})`
    -   Constructs a checkbox input from the given options
    -   `check_box_tag :remember_me, :checked => true`

-   `radio_button_tag(name, options={})`
    -   Constructs a radio button input from the given options
    -   `radio_button_tag :gender, :value => ‘male’`

-   `select_tag(name, settings={})`
    -   Constructs a select tag with options from the given settings
    -   `select_tag(:favorite_color, :options => [‘1’, ‘2’, ‘3’], :selected => ‘1’)`
    -   `select_tag(:more_color, :options => [[‘label’, ‘1’], [‘label2’, ‘2’]])`
    -   `select_tag(:multiple_color, :options => [‘1’, ‘2’, ‘3’], :multiple => true,
        :selected => [‘1’, ‘3’])`

-   `file_field_tag(name, options={})`
    -   Constructs a file field input from the given options
    -   `file_field_tag :photo, :class => ‘long’`

-   `submit_tag(caption, options={})`
    -   Constructs a submit button from the given options
    -   `submit_tag “Create”, :class => ‘success’`

-   `button_tag(caption, options={})`
    -   Constructs an input (type =\> ‘button’) from the given options
    -   `button_tag “Cancel”, :class => ‘clear’`

-   `image_submit_tag(source, options={})`
    -   Constructs an image submit button from the given options
    -   `image_submit_tag “submit.png”, :class => ‘success’`

 

## FormBuilders

Form builders are full-featured objects allowing the construction of complex object-based forms using a simple, intuitive syntax.

A form\_for using these basic fields might look like:

    # app/views/example.haml
    = form_for @user, '/register', :id => 'register' do |f|
      = f.error_messages
      %p
        = f.label :username, :caption => "Nickname"
        = f.text_field :username
      %p
        = f.label :email
        = f.text_field :email
      %p
        = f.label :password
        = f.password_field :password
      %p
        = f.label :is_admin, :caption => "Admin User?"
        = f.check_box :is_admin
      %p
        = f.label :color, :caption => "Favorite Color?"
        = f.select :color, :options => ['red', 'black']
      %p
        = fields_for @user.location do |location|
          = location.text_field :street
          = location.text_field :city
      %p
        = f.submit "Create", :class => 'button'

The list of defined helpers in the ‘form builders’ category:

-   `form_for(object, url, settings={}, &block)`
    -   Constructs a form using given or default form\_builder
    -   Supports form methods ‘put’ and ‘delete’ through hidden field
    -   Defaults to StandardFormBuilder but you can easily create your own!
    -   `form_for(@user, ‘/register’, :id => ‘register’) { |f| …field-elements… }`
    -   `form_for(:user, ‘/register’, :id => ‘register’) { |f| …field-elements… }`

-   `fields_for(object, settings={}, &block)`
    -   Constructs fields for a given object for use in an existing form
    -   Defaults to StandardFormBuilder but you can easily create your own!
    -   `fields_for @user.assignment do |assignment| … end`
    -   `fields_for :assignment do |assigment| … end`

The following are fields provided by AbstractFormBuilder that can be used within a form\_for or fields\_for:

-   `error_messages(options={})`
    -   Displays list html for the errors on form object
    -   `f.errors_messages`

-   `label(field, options={})`
    -   `f.label :name, :class => ‘long’`

-   `text_field(field, options={})`
    -   `f.text_field :username, :class => ‘long’`

-   `check_box(field, options={})`
    -   Uses hidden field to provide a ‘unchecked’ value for field
    -   `f.check_box :remember_me, :uncheck_value => ‘false’`

-   `radio_button(field, options={})`
    -   `f.radio_button :gender, :value => ‘male’`

-   `hidden_field(field, options={})`
    -   `f.hidden_field :session_id, :class => ‘hidden’`

-   `text_area(field, options={})`
    -   `f.text_area :summary, :class => ‘long’`

-   `password_field(field, options={})`
    -   `f.password_field :secret, :class => ‘long’`

-   `number_field(field, options={})`
    -   `f.number_field :age, :class => ‘long’`

-   `telephone_field(field, options={})`
    -   `f.telephone_field :mobile, :class => ‘long’`

-   `email_field(field, options={})`
    -   `f.email_field :email, :class => ‘long’`

-   `search_field(field, options={})`
    -   `f.search_field :query, :class => ‘long’`

-   `url_field(field, options={})`
    -   `f.url_field :image_source, :class => ‘long’`

-   `file_field(field, options={})`
    -   `f.file_field :photo, :class => ‘long’`

-   `select(field, options={})`
    -   `f.select(:state, :options => [‘California’, ‘Texas’, ‘Wyoming’])`
    -   `f.select(:state, :collection => @states, :fields => [:name, :id])`
    -   `f.select(:state, :options => […], :include_blank => true)`

-   `submit(caption, options={})`
    -   `f.submit “Update”, :class => ‘long’`

-   `image_submit(source, options={})`
    -   `f.image_submit “submit.png”, :class => ‘long’`

### Standard Form Builder

There is also an additional StandardFormBuilder which builds on the abstract fields that can be used within a form\_for.

A form\_for using these standard fields might be:

    # app/views/example.haml
    = form_for @user, '/register', :id => 'register' do |f|
        = f.error_messages
        = f.text_field_block :name, :caption => "Full name"
        = f.text_field_block :email
        = f.check_box_block  :remember_me
        = f.select_block     :fav_color, :options => ['red', 'blue']
        = f.password_field_block :password
        = f.submit_block "Create", :class => 'button'

and would generate this html (with each input contained in a paragraph and containing a label):

    <form id="register" action="/register" method="post">
      <label for="user_name">Full name:</label>
      <input type="text" id="user_name" name="user[name]" />
        ...omitted...
      <input type="submit" value="Create" class="button" />
    </form>

The following are fields provided by StandardFormBuilder that can be used within a form\_for or fields\_for:

-   `text_field_block(field, options={}, label_options={})`
    -   `text_field_block(:nickname, :class => ‘big’, :caption => “Username”)`

-   `text_area_block(field, options={}, label_options={})`
    -   `text_area_block(:about, :class => ‘big’)`

-   `password_field_block(field, options={}, label_options={})`
    -   `password_field_block(:code, :class => ‘big’)`

-   `file_field_block(field, options={}, label_options={})`
    -   `file_field_block(:photo, :class => ‘big’)`

-   `check_box_block(field, options={}, label_options={})`
    -   `check_box_block(:remember_me, :class => ‘big’)`

-   `select_block(field, options={}, label_options={})`
    -   `select_block(:country, :option => [‘USA’, ‘Canada’])`

-   `submit_block(caption, options={})`
    -   `submit_block(:username, :class => ‘big’)`

-   `image_submit_block(source, options={})`
    -   `image_submit_block(‘submit.png’, :class => ‘big’)`

### Custom Form Builders

You can also easily build your own FormBuilder which allows for customized fields and behavior:

    class MyCustomFormBuilder < AbstractFormBuilder
      # Here we have access to a number of useful variables
      #
      # ** template  (use this to invoke any helpers)(ex. template.hidden_field_tag(...))
      # ** object    (the record for this form) (ex. object.valid?)
      # ** object_name (object's underscored type) (ex. object_name => 'admin_user')
      #
      # We also have access to self.field_types => [:text_field, :text_area, ...]
      # In addition, we have access to all the existing field tag 
      # helpers (text_field, hidden_field, file_field, ...)
    end

Once a custom builder is defined, any call to form\_for can use the new builder:

    = form_for @user, '/register', :builder => 'MyCustomFormBuilder', :id => 'register' do |f|
      ...fields here...

The form builder can even be made into the default builder when form\_for is invoked:

    # anywhere in the Padrino or Sinatra application
    set :default_builder, 'MyCustomFormBuilder'

And there you have it, a fairly complete form builder solution for Padrino (and Sinatra).
 I hope to create or merge in an even better ‘default’ form\_builder in the near future.

### Nested Object Form Support

Available in the 0.9.21 Padrino release is support for nested object form helpers. This allows forms to have arbitrarily complex nested forms that can build multiple related objects together. Let’s take a simple example of a person with an address. Here are the related psuedo models:

    class Person < ORM::Base
      has_many :addresses, :class_name => 'Address'
      accepts_nested_attributes_for :addresses, :allow_destroy => true
    end

    class Address < ORM::Base
      belongs_to :person
    end

The model declarations are dependent on your chosen ORM. Check the documentation to understand how to declare nested attributes in your given ORM component. Given those models and enabling nested attributes for the association, the following view will allow nested form creation:

    # app/views/person/_form.html.haml
    = form_for @person, '/person/create'  do |f|
      = f.text_field :name 
      = f.text_field :favorite_color
      = f.fields_for :addresses do |address_form| 
        = address_form.label :street 
        = address_form.text_field :street
        = address_form.label :city
        = address_form.text_field :city
        - unless address_form.object.new_record? 
          = address_form.check_box '_destroy' 
          = address_form.label '_destroy', :caption => 'Remove' 
        = submit_tag "Save"

This will present a form that allows the person’s name and color to be set along with their first address. Using this functionality, the controller does not need to change whatsoever as the nested data will be passed in and instantiated as part of the parent model.

 

## Format Helpers

Format helpers are several useful utilities for manipulating the format of text to achieve a goal.
 The four format helpers are `escape_html`, `distance_of_time_in_words`, `time_ago_in_words`, and `js_escape_html`.

The escape\_html and js\_escape\_html function are for taking an html string and escaping certain characters.
 `escape_html` will escape ampersands, brackets and quotes to their HTML/XML entities. This is useful to sanitize user content before displaying this on a template. `js_escape_html` is used for passing javascript information from a js template to a javascript function.

    escape_html('<hello>&<goodbye>') # => &lt;hello&gt;&amp;&lt;goodbye&gt;

There is also an alias for escape\_html called `h` for even easier usage within templates.

Format helpers also includes a number of useful text manipulation functions such as `simple_format`, `pluralize`, `word_wrap`, and `truncate`.

    simple_format("hello\nworld") # => "<p>hello<br/>world</p>"
    pluralize(2, 'person') => '2 people'
    word_wrap('Once upon a time', :line_width => 8) => "Once upon\na time"
    truncate("Once upon a time in a world far far away", :length => 8) => "Once upon..."
    truncate_words("Once upon a time in a world far far away", :length => 4) => "Once upon a time..."
    highlight('Lorem dolor sit', 'dolor') => "Lorem <strong class="highlight">dolor</strong> sit"

These helpers can be invoked from any route or view within your application.

The list of defined helpers in the ‘format helpers’ category:

-   `simple_format(text, html_options)`
    -   Returns text transformed into HTML using simple formatting rules.
    -   `simple_format(“hello\nworld”)` =\> `"<p>hello<br/>world</p>"`

-   `pluralize(count, singular, plural = nil)`
    -   Attempts to pluralize the singular word unless count is 1.
    -   `pluralize(2, ‘person’)` =\> ‘2 people’

-   `word_wrap(text, *args)`
    -   Wraps the text into lines no longer than line\_width width.
    -   `word_wrap(‘Once upon a time’, :line_width => 8)` =\> “Once upon\\na time”

-   `truncate(text, *args)`
    -   Truncates a given text after a given :length if text is longer than :length (defaults to 30).
    -   `truncate(“Once upon a time in a world far far away”, :length => 8)` =\> “Once upon…”

-   `truncate_words(text, *args)`
    -   Truncates a given text after a given :length of total words (defaults to 30).
    -   truncate\_words(“Once upon a time in a world far far away”, :length =\> 4) =\> “Once upon a time…”

-   `highlight(text, words, *args)`
    -   Highlights one or more words everywhere in text by inserting it into a :highlighter string.
    -   `highlight(‘Lorem ipsum dolor sit amet’, ‘dolor’)`

-   `escape_html` (alias `h` and `h!`)
    -   (from RackUtils) Escape ampersands, brackets and quotes to their HTML/XML entities.

-   `strip_tags(html)`
    -   Remove all html tags and return only a clean text.

-   `distance_of_time_in_words(from_time, to_time = 0)`
    -   Returns relative time in words referencing the given date
    -   `distance_of_time_in_words(2.days.ago)` =\> “2 days”
    -   `distance_of_time_in_words(5.minutes.ago)` =\> “5 minutes”
    -   `distance_of_time_in_words(2800.days.ago)` =\> “over 7 years”

-   `time_ago_in_words(from_time)`
    -   Returns relative time in words from the current date
    -   `time_ago_in_words(2.days.ago)` =\> “2 days”
    -   `time_ago_in_words(1.day.from_now)` =\> “tomorrow”

-   `js_escape_html(html_content)`
    -   Escapes html to allow passing information to javascript. Used for passing data inside an ajax .js.erb template
    -   `js_escape_html("<h1>Hey</h1>")`

 

## Render Helpers

This component provides a number of rendering helpers making the process of displaying templates a bit easier.
 This plugin also has support for useful additions such as partials (with support for :collection) for the templating system.

Using render plugin helpers is extremely simple. If you want to render an erb template in your view path:

    render :erb, 'path/to/erb/template'

or using haml templates works just as well:

    render :haml, 'path/to/haml/template'

There is also a method which renders the first view matching the path and removes the need to define an engine:

    render 'path/to/any/template'

It is worth noting these are mostly for convenience. With nested view file paths in Sinatra, this becomes tiresome:

    haml :"the/path/to/file"
    erb "/path/to/file".to_sym

Finally, we have the all-important partials support for rendering mini-templates onto a page:

    partial 'photo/item', :object => @photo, :locals => { :foo => 'bar' }
    partial 'photo/item', :collection => @photos

This works as you would expect and also supports the collection counter inside the partial `item_counter`

    # /views/photo/_item.haml
    # Access to collection counter with <partial_name>_counter i.e item_counter
    # Access the object with the partial_name i.e item

The list of defined helpers in the ‘render helpers’ category:

-   `render(engine, data, options, locals)`
    -   Renders the specified template with the given options
    -   `render ‘user/new’`
    -   `render :erb, ‘users/new’, :layout => false`

-   `partial(template, *args)`
    -   Renders the html related to the partial template for object or collection
    -   `partial ‘photo/item’, :object => @photo, :locals => { :foo => ‘bar’ }`
    -   `partial ‘photo/item’, :collection => @photos`

 

## Custom Defined Helpers

In addition to the helpers provided by Padrino out of the box, you can also add your own helper methods and classes that will be accessible within any controller or view automatically.

To define a helper method, simply use an existing helper file (created when generating a controller) or define your own file in `app/helpers` within your application. Methods can be made available within you controller by simply wrapping the methods in the `helpers` block:

    # app/helpers/some_helper.rb
    MyAppName.helpers do
      def some_method
        # ...do something here...
      end
    end

You can also define entire classes for use as helpers just as easily:

    # app/helpers/some_helper.rb
    class SomeHelper
     def self.do_something
       # ...do something here...
     end
    end

These helpers can then easily be invoked in any controllers or templates within your application:

    # app/controllers/posts.rb
    MyAppName.controllers :posts do
      get :index do
        some_method # helper method
        SomeHelper.do_something # helper class
      end
    end

Use these in situations where you wish to cleanup your controller or your view code. Helpers are particularly useful for DRY’ing up repeated use of the same markup or behavior. **Note** that helper methods and objects should be reloaded automatically for you in development.

 

## Unobtrusive Javascript Helpers

In addition to the helpers above, certain helpers also have certain unobtrusive javascript options that are available to be used with any of the javascript adapters packaged with padrino. Once your app has been [generated](http://www.padrinorb.com/guides/generators) with a particular javascript adapter, you can utilize the baked in support with the `link_to` and `form_for` tags.

### Remote Forms

To generate a ‘remote’ form in a view:

    # /app/views/users/new.html.haml
    = form_for :user, url(:create, :format => :js), :remote => true do |f|
      .content=partial "/users/form"

which will generate the following unobtrusive markup:

    <form data-remote="true" action="/items/create.js" method="post">
      <div class="content">
        <input type="text" id="post_title" name="post[title]">
        <input type="submit" value="Create">
      </div>
    </form>

    # /app/controllers/users.rb
      post :create, :provides => :js do
        @user = User.new(params[:user])
        if @user.save
          "$('form.content').html('#{partial("/users/form")}');"
        else
          "alert('User is not valid');"
        end
      end

A remote form, when submitted by the user, invokes an xhr request to the specified url (with the appropriate form parameters) and then evaluates the response as javascript.

### Remote Links

To generate a ‘remote’ link in a view:

    link_to "add item", url(:items, :new, :format => :js), :remote => true

which will generate the following unobtrusive markup:

    <a href="/items/new.js" data-remote="true">add item</a>

A remote link, when clicked by the user, invokes an xhr request to the specified url and then evaluates the response as javascript.

### Link Confirmations

To generate a ‘confirmation’ link in a view:

    link_to "delete item", url(:items, :destroy, :format => :js), :confirm => "Are You Sure?"

which will generate the following unobtrusive markup:

    <a data-confirm="Are You Sure?" href="/posts/destroy/7">[destroy]</a>

A link with confirmation, when clicked by the user, displays an alert box confirming the action before invoking the link.

### Custom Method Links

To generate a ‘method’ link in a view:

    link_to "logout", url(:session, :destroy, :format => :js), :method => :delete

which will generate the following unobtrusive markup:

    <a data-method="delete" href="/posts/destroy/7" rel="nofollow">[destroy]</a>

A link with a custom method, when clicked by the user, visits the link using the http method specified rather than via the ‘GET’ method.

### Enabling UJS Adapter

**Note**: In order for the unobstrusive javascript to work, you must be sure to include the chosen javascript framework and ujs adapter in your views (or layout). For instance, if I selected jquery for my project:

    # /apps/views/layouts/application.haml
    = javascript_include_tag 'jquery', 'jquery-ujs', 'application'

This will ensure jquery and the jquery ujs adapter are properly loaded to work with the helpers listed above.
