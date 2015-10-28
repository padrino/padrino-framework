require 'padrino-helpers/form_helpers/errors'
require 'padrino-helpers/form_helpers/options'
require 'padrino-helpers/form_helpers/security'

module Padrino
  module Helpers
    ##
    # Helpers related to producing form related tags and inputs into templates.
    #
    module FormHelpers
      def self.included(base)
        base.send(:include, FormHelpers::Errors)
        base.send(:include, FormHelpers::Options)
        base.send(:include, FormHelpers::Security)
      end

      ##
      # Constructs a form for object using given or default form_builder.
      #
      # @param [Object] object
      #   The object for which the form is being built.
      # @param [String] URL
      #   The url this form will submit to.
      # @param [Hash] options
      #   The settings associated with this form.
      #   Accepts a :namespace option that will be prepended to the id attributes of the form's elements.
      #   Also accepts HTML options.
      # @option settings [String] :builder ("StandardFormBuilder")
      #   The FormBuilder class to use such as StandardFormBuilder.
      # @option settings [Symbol] :as
      #   Sets custom form object name.
      # @param [Proc] block
      #   The fields and content inside this form.
      #
      # @yield [AbstractFormBuilder] The form builder used to compose fields.
      #
      # @return [String] The html object-backed form with the specified options and input fields.
      #
      # @example
      #   form_for :user, '/register' do |f| ... end
      #   form_for @user, '/register', :id => 'register' do |f| ... end
      #   form_for @user, '/register', :as => :customer do |f| ... end
      #
      def form_for(object, url, options={}, &block)
        instance = builder_instance(object, options)
        # this can erect instance.multipart flag if the block calls instance.file_field
        html = capture_html(instance, &block)
        options = { :multipart => instance.multipart }.update(options.reject{ |key,_| [:namespace, :as].include?(key) })
        form_tag(url, options) { html }
      end

      ##
      # Constructs form fields for an object using given or default form_builder.
      # Used within an existing form to allow alternate objects within one form.
      #
      # @param [Object] object
      #   The object for which the fields are being built.
      # @param [Hash] options
      #   The settings associated with these fields. Accepts HTML options.
      # @param [Proc] block
      #   The content inside this set of fields.
      #
      # @return [String] The html fields with the specified options.
      #
      # @example
      #   fields_for @user.assignment do |assignment| ... end
      #   fields_for :assignment do |assigment| ... end
      #
      def fields_for(object, options={}, &block)
        instance = builder_instance(object, options)
        fields_html = capture_html(instance, &block)
        fields_html << instance.hidden_field(:id) if instance.send(:nested_object_id)
        concat_content fields_html
      end

      ##
      # Constructs a form without object based on options.
      #
      # @param [String] url
      #   The URL this form will submit to.
      # @param [Hash] options
      #   The html options associated with this form.
      # @param [Proc] block
      #   The fields and content inside this form.
      #
      # @return [String] The HTML form with the specified options and input fields.
      #
      # @example
      #   form_tag '/register', :class => "registration_form" do ... end
      #
      def form_tag(url, options={}, &block)
        options = {
          :action => escape_link(url),
          :protect_from_csrf => is_protected_from_csrf?,
          'accept-charset' => 'UTF-8'
        }.update(options)
        options[:enctype] = 'multipart/form-data' if options.delete(:multipart)

        if (desired_method = options[:method]) =~ /get/i
          options.delete(:protect_from_csrf)
        else
          options[:method] = 'post'
        end
        inner_form_html = hidden_form_method_field(desired_method)
        inner_form_html << csrf_token_field if options.delete(:protect_from_csrf)
        concat_content content_tag(:form, inner_form_html << capture_html(&block), options)
      end

      ##
      # Returns the hidden method field for 'put' and 'delete' forms.
      # Only 'get' and 'post' are allowed within browsers;
      # 'put' and 'delete' are just specified using hidden fields with form action still 'put'.
      #
      # @param [String] desired_method
      #   The method this hidden field represents (i.e put or delete).
      #
      # @return [String] The hidden field representing the +desired_method+ for the form.
      #
      # @example
      #   # Generate: <input name="_method" value="delete" />
      #   hidden_form_method_field('delete')
      #
      def hidden_form_method_field(desired_method)
        return SafeBuffer.new if desired_method.nil? || desired_method.to_s =~ /get|post/i
        hidden_field_tag(:_method, :value => desired_method)
      end

      ##
      # Constructs a field_set to group fields with given options.
      #
      # @overload field_set_tag(legend=nil, options={}, &block)
      #   @param [String] legend  The legend caption for the fieldset
      #   @param [Hash]   options The html options for the fieldset.
      #   @param [Proc]   block   The content inside the fieldset.
      # @overload field_set_tag(options={}, &block)
      #   @param [Hash]   options The html options for the fieldset.
      #   @param [Proc]   block   The content inside the fieldset.
      #
      # @return [String] The html for the fieldset tag based on given +options+.
      #
      # @example
      #   field_set_tag(:class => "office-set") { }
      #   field_set_tag("Office", :class => 'office-set') { }
      #
      def field_set_tag(*args, &block)
        options = args.last.is_a?(Hash) ? args.pop : {}
        legend_html = args.empty? ? SafeBuffer.new : content_tag(:legend, args.first)
        concat_content content_tag(:fieldset, legend_html << capture_html(&block), options)
      end

      ##
      # Constructs a label tag from the given options.
      #
      # @param [String] name
      #   The name of the field to label.
      # @param [Hash] options
      #   The html options for this label.
      # @option options :caption
      #   The caption for this label.
      # @param [Proc] block
      #   The content to be inserted into the label.
      #
      # @return [String] The html for this label with the given +options+.
      #
      # @example
      #   label_tag :username, :class => 'long-label'
      #   label_tag :username, :class => 'long-label' do ... end
      #
      def label_tag(name, options={}, &block)
        options = { :caption => "#{Inflections.humanize(name)}: ", :for => name }.update(options)
        caption_text = SafeBuffer.new << options.delete(:caption)
        caption_text << "<span class='required'>*</span> ".html_safe if options.delete(:required)

        if block_given?
          concat_content content_tag(:label, caption_text << capture_html(&block), options)
        else
          content_tag(:label, caption_text, options)
        end
      end

      ##
      # Creates a text field input with the given name and options.
      #
      # @macro [new] text_field
      #   @param [Symbol] name
      #     The name of the input to create.
      #   @param [Hash] options
      #     The HTML options to include in this field.
      #
      #   @option options [String] :id
      #     Specifies a unique identifier for the field.
      #   @option options [String] :class
      #     Specifies the stylesheet class of the field.
      #   @option options [String] :name
      #     Specifies the name of the field.
      #   @option options [String] :accesskey
      #     Specifies a shortcut key to access the field.
      #   @option options [Integer] :tabindex
      #     Specifies the tab order of the field.
      #   @option options [Integer] :maxlength
      #     Specifies the maximum length, in characters, of the field.
      #   @option options [Integer] :size
      #     Specifies the width, in characters, of the field.
      #   @option options [String] :placeholder
      #     Specifies a short hint that describes the expected value of the field.
      #   @option options [Boolean] :hidden
      #     Specifies whether or not the field is hidden from view.
      #   @option options [Boolean] :spellcheck
      #     Specifies whether or not the field should have it's spelling and grammar checked for errors.
      #   @option options [Boolean] :draggable
      #     Specifies whether or not the field is draggable. (true, false, :auto).
      #   @option options [String] :pattern
      #     Specifies the regular expression pattern that the field's value is checked against.
      #   @option options [Symbol] :autocomplete
      #     Specifies whether or not the field should have autocomplete enabled. (:on, :off).
      #   @option options [Boolean] :autofocus
      #     Specifies whether or not the field should automatically get focus when the page loads.
      #   @option options [Boolean] :required
      #     Specifies whether or not the field is required to be completed before the form is submitted.
      #   @option options [Boolean] :readonly
      #     Specifies whether or not the field is read only.
      #   @option options [Boolean] :disabled
      #     Specifies whether or not the field is disabled.
      #
      #   @return [String]
      #     Generated HTML with specified +options+.
      #
      # @example
      #   text_field_tag :first_name, :maxlength => 40, :required => true
      #   # => <input name="first_name" maxlength="40" required type="text" />
      #
      #   text_field_tag :last_name, :class => 'string', :size => 40
      #   # => <input name="last_name" class="string" size="40" type="text" />
      #
      #   text_field_tag :username, :placeholder => 'Your Username'
      #   # => <input name="username" placeholder="Your Username" type="text" />
      #
      def text_field_tag(name, options={})
        input_tag(:text, { :name => name }.update(options))
      end

      ##
      # Creates a number field input with the given name and options.
      #
      # @macro [new] number_field
      #   @param [Symbol] name
      #     The name of the input to create.
      #   @param [Hash] options
      #     The HTML options to include in this field.
      #
      #   @option options [String] :id
      #     Specifies a unique identifier for the field.
      #   @option options [String] :class
      #     Specifies the stylesheet class of the field.
      #   @option options [String] :name
      #     Specifies the name of the field.
      #   @option options [String] :accesskey
      #     Specifies a shortcut key to access the field.
      #   @option options [Integer] :tabindex
      #     Specifies the tab order of the field.
      #   @option options [Integer] :min
      #     Specifies the minimum value of the field.
      #   @option options [Integer] :max
      #     Specifies the maximum value of the field.
      #   @option options [Integer] :step
      #     Specifies the legal number intervals of the field.
      #   @option options [Boolean] :hidden
      #     Specifies whether or not the field is hidden from view.
      #   @option options [Boolean] :spellcheck
      #     Specifies whether or not the field should have it's spelling and grammar checked for errors.
      #   @option options [Boolean] :draggable
      #     Specifies whether or not the field is draggable. (true, false, :auto).
      #   @option options [String] :pattern
      #     Specifies the regular expression pattern that the field's value is checked against.
      #   @option options [Symbol] :autocomplete
      #     Specifies whether or not the field should have autocomplete enabled. (:on, :off).
      #   @option options [Boolean] :autofocus
      #     Specifies whether or not the field should automatically get focus when the page loads.
      #   @option options [Boolean] :required
      #     Specifies whether or not the field is required to be completeled before the form is submitted.
      #   @option options [Boolean] :readonly
      #     Specifies whether or not the field is read only.
      #   @option options [Boolean] :disabled
      #     Specifies whether or not the field is disabled.
      #
      #   @return [String]
      #     Generated HTML with specified +options+.
      #
      # @example
      #   number_field_tag :quantity, :class => 'numeric'
      #   # => <input name="quantity" class="numeric" type="number" />
      #
      #   number_field_tag :zip_code, :pattern => /[0-9]{5}/
      #   # => <input name="zip_code" pattern="[0-9]{5}" type="number" />
      #
      #   number_field_tag :credit_card, :autocomplete => :off
      #   # => <input name="credit_card" autocomplete="off" type="number" />
      #
      #   number_field_tag :age, :min => 18, :max => 120, :step => 1
      #   # => <input name="age" min="18" max="120" step="1" type="number" />
      #
      def number_field_tag(name, options={})
        input_tag(:number, { :name => name }.update(options))
      end

      ##
      # Creates a telephone field input with the given name and options.
      #
      # @macro text_field
      #
      # @example
      #   telephone_field_tag :phone_number, :class => 'string'
      #   # => <input name="phone_number" class="string" type="tel" />
      #
      #  telephone_field_tag :cell_phone, :tabindex => 1
      #  telephone_field_tag :work_phone, :tabindex => 2
      #  telephone_field_tag :home_phone, :tabindex => 3
      #
      #  # => <input name="cell_phone" tabindex="1" type="tel" />
      #  # => <input name="work_phone" tabindex="2" type="tel" />
      #  # => <input name="home_phone" tabindex="3" type="tel" />
      #
      def telephone_field_tag(name, options={})
        input_tag(:tel, { :name => name }.update(options))
      end
      alias_method :phone_field_tag, :telephone_field_tag

      ##
      # Creates an email field input with the given name and options.
      #
      # @macro text_field
      #
      # @example
      #   email_field_tag :email, :placeholder => 'you@example.com'
      #   # => <input name="email" placeholder="you@example.com" type="email" />
      #
      #   email_field_tag :email, :value => 'padrinorb@gmail.com', :readonly => true
      #   # => <input name="email" value="padrinorb@gmail.com" readonly type="email" />
      #
      def email_field_tag(name, options={})
        input_tag(:email, { :name => name }.update(options))
      end

      ##
      # Creates a search field input with the given name and options.
      #
      # @macro text_field
      #
      # @example
      #  search_field_tag :search, :placeholder => 'Search this website...'
      #  # => <input name="search" placeholder="Search this website..." type="search" />
      #
      #  search_field_tag :search, :maxlength => 15, :class => ['search', 'string']
      #  # => <input name="search" maxlength="15" class="search string" />
      #
      #  search_field_tag :search, :id => 'search'
      #  # => <input name="search" id="search" type="search" />
      #
      #  search_field_tag :search, :autofocus => true
      #  # => <input name="search" autofocus type="search" />
      #
      def search_field_tag(name, options={})
        input_tag(:search, { :name => name }.update(options))
      end

      ##
      # Creates a URL field input with the given name and options.
      #
      # @macro text_field
      #
      # @example
      #  url_field_tag :favorite_website, :placeholder => 'http://padrinorb.com'
      #  <input name="favorite_website" placeholder="http://padrinorb.com." type="url" />
      #
      #  url_field_tag :home_page, :class => 'string url'
      #  <input name="home_page" class="string url", type="url" />
      #
      def url_field_tag(name, options={})
        input_tag(:url, { :name => name }.update(options))
      end

      ##
      # Constructs a hidden field input from the given options.
      #
      # @example
      #   hidden_field_tag :session_key, :value => "__secret__"
      #
      def hidden_field_tag(name, options={})
        input_tag(:hidden, { :name => name }.update(options))
      end

      ##
      # Constructs a text area input from the given options.
      #
      # @example
      #   text_area_tag :username, :class => 'long', :value => "Demo?"
      #
      def text_area_tag(name, options={})
        inner_html = TagHelpers::NEWLINE + options.delete(:value).to_s
        content_tag(:textarea, inner_html, { :name => name }.update(options))
      end

      ##
      # Constructs a password field input from the given options.
      #
      # @example
      #   password_field_tag :password, :class => 'long'
      #
      # @api public
      def password_field_tag(name, options={})
        input_tag(:password, { :name => name }.update(options))
      end

      ##
      # Constructs a check_box from the given options.
      #
      # @example
      #   check_box_tag :remember_me, :value => 'Yes'
      #
      def check_box_tag(name, options={})
        input_tag(:checkbox, { :name => name, :value => '1' }.update(options))
      end

      ##
      # Constructs a radio_button from the given options.
      #
      # @example
      #   radio_button_tag :remember_me, :value => 'true'
      #
      def radio_button_tag(name, options={})
        input_tag(:radio, { :name => name }.update(options))
      end

      ##
      # Constructs a file field input from the given options.
      #
      # @example
      #   file_field_tag :photo, :class => 'long'
      #
      # @api public
      def file_field_tag(name, options={})
        name = "#{name}[]" if options[:multiple]
        input_tag(:file, { :name => name }.update(options))
      end

      ##
      # Constructs a select from the given options.
      #
      # @example
      #   options = [['caption', 'value'], ['Green', 'green1'], ['Blue', 'blue1'], ['Black', "black1"]]
      #   options = ['option', 'red', 'yellow' ]
      #   select_tag(:favorite_color, :options => ['red', 'yellow'], :selected => 'green1')
      #   select_tag(:country, :collection => @countries, :fields => [:name, :code], :include_blank => 'None')
      #
      #   # Optgroups can be generated using :grouped_options => (Hash or nested Array)
      #   grouped_options = [['Friends',['Yoda',['Obiwan',1]]],['Enemies',['Palpatine',['Darth Vader',3]]]]
      #   grouped_options = {'Friends' => ['Yoda',['Obiwan',1]],'Enemies' => ['Palpatine',['Darth Vader',3]]}
      #   select_tag(:color, :grouped_options => [['warm',['red','yellow']],['cool',['blue', 'purple']]])
      #
      #   # Optgroups can be generated using the rails-style attribute hash.
      #   grouped_options = {
      #     "Friends" => ["Yoda", ["Obiwan", 2, {:magister => 'no'}], {:lame => 'yes'}],
      #     "Enemies" => [["Palpatine", "Palpatine", {:scary => 'yes', :old => 'yes'}], ["Darth Vader", 3, {:disabled => true}]]
      #   }
      #   select_tag(:name, :grouped_options => grouped_options)
      #
      # @param [String] name
      #   The name of the input field.
      # @param [Hash] options
      #   The html options for the input field.
      # @option options [Array<String, Array>] :options
      #  Explicit options to display in the select. Can be strings or string tuples.
      # @option options [Array<Array>] :grouped_options
      #   List of options for each group in the select. See examples for details.
      # @option options [Array<Object>] :collection
      #   Collection of objects used as options in the select.
      # @option options [Array<Symbol>] :fields
      #   The attributes used as "label" and "value" for each +collection+ object.
      # @option options [String] :selected (nil)
      #   The option value initially selected.
      # @option options [Boolean] :include_blank (false)
      #   Include a blank option in the select.
      # @option options [Boolean] :multiple (false)
      #   Allow multiple options to be selected at once.
      #
      # @return [String] The HTML input field based on the +options+ specified.
      #
      def select_tag(name, options={})
        options = { :name => name }.merge(options)
        options[:name] = "#{options[:name]}[]" if options[:multiple]
        content_tag(:select, extract_option_tags!(options), options)
      end

      ##
      # Constructs a button input from the given options.
      #
      # @param [String] caption
      #   The caption for the button.
      # @param [Hash] options
      #   The html options for the input field.
      #
      # @return [String] The html button based on the +options+ specified.
      #
      # @example
      #   button_tag "Cancel", :class => 'clear'
      #
      def button_tag(caption, options = {})
        input_tag(:button, { :value => caption }.update(options))
      end

      ##
      # Constructs a submit button from the given options.
      #
      # @overload submit_tag(options={})
      #   @param [Hash]    options  The html options for the input field.
      # @overload submit_tag(caption, options={})
      #   @param [String]  caption  The caption for the submit button.
      #   @param [Hash]    options  The html options for the input field.
      #
      # @return [String] The html submit button based on the +options+ specified.
      #
      # @example
      #   submit_tag "Create", :class => 'success'
      #   submit_tag :class => 'btn'
      #
      def submit_tag(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        caption = args.length >= 1 ? args.first : "Submit"
        input_tag(:submit, { :value => caption }.merge(options))
      end

      ##
      # Constructs a submit button from the given options.
      #
      # @param [String] source
      #   The source image path for the button.
      # @param [Hash] options
      #   The html options for the input field.
      #
      # @return [String] The html image button based on the +options+ specified.
      #
      # @example
      #   image_submit_tag 'form/submit.png'
      #
      def image_submit_tag(source, options={})
        input_tag(:image, { :src => image_path(source) }.update(options))
      end

      ##
      # Creates a form containing a single button that submits to the URL.
      #
      # @overload button_to(caption, url, options={})
      #   @param [String]  caption  The text caption.
      #   @param [String]  url      The url href.
      #   @param [Hash]    options  The html options.
      # @overload button_to(url, options={}, &block)
      #   @param [String]  url      The url href.
      #   @param [Hash]    options  The html options.
      #   @param [Proc]    block    The button content.
      #
      # @option options [Boolean] :multipart
      #   If true, this form will support multipart encoding.
      # @option options [String] :remote
      #   Instructs ujs handler to handle the submit as ajax.
      # @option options [Symbol] :method
      #   Instructs ujs handler to use different http method (i.e :post, :delete).
      # @option options [Hash] :submit_options
      #   Hash of any options, that you want to pass to submit_tag (i.e :id, :class)
      #
      # @return [String] Form and button html with specified +options+.
      #
      # @example
      #   button_to 'Delete', url(:accounts_destroy, :id => account), :method => :delete, :class => :form
      #   # Generates:
      #   # <form class="form" action="/admin/accounts/destroy/2" method="post">
      #   #   <input type="hidden" value="delete" name="_method" />
      #   #   <input type="submit" value="Delete" />
      #   # </form>
      #
      def button_to(*args, &block)
        options = args.last.is_a?(Hash) ? args.pop : {}
        name, url = *args
        options['data-remote'] = 'true' if options.delete(:remote)
        submit_options = options.delete(:submit_options) || {}
        form_tag(url || name, options) do
          if block_given?
            content_tag(:button, capture_html(&block), submit_options)
          else
            submit_tag(name, submit_options)
          end
        end
      end

      ##
      # Constructs a range tag from the given options.
      #
      # @example
      #   range_field_tag('ranger_with_min_max', :min => 1, :max => 50)
      #   range_field_tag('ranger_with_range', :range => 1..5)
      #
      # @param [String] name
      #   The name of the range field.
      # @param [Hash] options
      #   The html options for the range field.
      # @option options [Integer] :min
      #  The min range of the range field.
      # @option options [Integer] :max
      #  The max range of the range field.
      # @option options [range] :range
      #  The range, in lieu of :min and :max.  See examples for details.
      # @return [String] The html range field
      #
      def range_field_tag(name, options = {})
        options = { :name => name }.update(options)
        if range = options.delete(:range)
          options[:min], options[:max] = range.min, range.max
        end
        input_tag(:range, options)
      end

      DATETIME_ATTRIBUTES = [:value, :max, :min].freeze
      COLOR_CODE_REGEXP   = /\A#([0-9a-fA-F]{3}){1,2}\z/.freeze

      ##
      # Constructs a datetime tag from the given options.
      #
      # @example
      #   datetime_field_tag('datetime_with_min_max', :min => DateTime.new(1993, 2, 24, 12, 30, 45),
      #                                               :max => DateTime.new(2000, 4, 1, 12, 0, 0))
      #   datetime_field_tag('datetime_with_value', :value => DateTime.new(2000, 4, 1, 12, 0, 0))
      #
      # @param [String] name
      #   The name of the datetime field.
      # @param [Hash] options
      #   The html options for the datetime field.
      # @option options [DateTime, String] :min
      #  The min date time of the datetime field.
      # @option options [DateTime, String] :max
      #  The max date time of the datetime field.
      # @option options [DateTime, String] :value
      #  The value of the datetime field. See examples for details.
      # @return [String] The html datetime field
      #
      def datetime_field_tag(name, options = {})
        options = { :name => name }.update(options)
        options = convert_attributes_into_datetime("%Y-%m-%dT%T.%L%z", options)
        input_tag(:datetime, options)
      end

      ##
      # Constructs a datetime-local tag from the given options.
      #
      # @example
      #   datetime_local_field_tag('datetime_local_with_min_max', :min => DateTime.new(1993, 2, 24, 12, 30, 45),
      #                                                           :max => DateTime.new(2000, 4, 1, 12, 0, 0))
      #   datetime_local_field_tag('datetime_local_with_value', :value => DateTime.new(2000, 4, 1, 12, 0, 0))
      #
      # @param [String] name
      #   The name of the datetime local field.
      # @param [Hash] options
      #   The html options for the datetime-local field.
      # @option options [DateTime, String] :min
      #  The min date time of the datetime-local field.
      # @option options [DateTime, String] :max
      #  The max date time of the datetime-local field.
      # @option options [DateTime, String] :value
      #  The value of the datetime field. See examples for details.
      # @return [String] The html datetime-local field
      #
      def datetime_local_field_tag(name, options = {})
        options = { :name => name }.update(options)
        options = convert_attributes_into_datetime("%Y-%m-%dT%T", options)
        input_tag(:"datetime-local", options)
      end

      ##
      # Constructs a date tag from the given options.
      #
      # @example
      #   date_field_tag('date_with_min_max', :min => DateTime.new(1993, 2, 24),
      #                                       :max => DateTime.new(2000, 4, 1))
      #   date_field_tag('date_with_value', :value => DateTime.new(2000, 4, 1))
      #
      # @param [String] name
      #   The name of the date field.
      # @param [Hash] options
      #   The html options for the date field.
      # @option options [DateTime, String] :min
      #  The min date time of the date field.
      # @option options [DateTime, String] :max
      #  The max date time of the date field.
      # @option options [DateTime, String] :value
      #  The value of the date field. See examples for details.
      # @return [String] The html date field
      #
      def date_field_tag(name, options = {})
        options = { :name => name }.update(options)
        options = convert_attributes_into_datetime("%Y-%m-%d", options)
        input_tag(:date, options)
      end

      ##
      # Constructs a month tag from the given options.
      #
      # @example
      #   month_field_tag('month_with_min_max', :min => DateTime.new(1993, 2, 24),
      #                                         :max => DateTime.new(2000, 4, 1))
      #   month_field_tag('month_with_value', :value => DateTime.new(2000, 4, 1))
      #
      # @param [String] name
      #   The name of the month field.
      # @param [Hash] options
      #   The html options for the month field.
      # @option options [DateTime, String] :min
      #  The min month time of the month field.
      # @option options [DateTime, String] :max
      #  The max month time of the month field.
      # @option options [DateTime, String] :value
      #  The value of the month field. See examples for details.
      # @return [String] The html month field
      #
      def month_field_tag(name, options = {})
        options = { :name => name }.update(options)
        options = convert_attributes_into_datetime("%Y-%m", options)
        input_tag(:month, options)
      end

      ##
      # Constructs a week tag from the given options.
      #
      # @example
      #   week_field_tag('week_with_min_max', :min => DateTime.new(1993, 2, 24),
      #                                       :max => DateTime.new(2000, 4, 1))
      #   week_field_tag('week_with_value', :value => DateTime.new(2000, 4, 1))
      #
      # @param [String] name
      #   The name of the week field.
      # @param [Hash] options
      #   The html options for the week field.
      # @option options [DateTime, String] :min
      #  The min week time of the week field.
      # @option options [DateTime, String] :max
      #  The max week time of the week field.
      # @option options [DateTime, String] :value
      #  The value of the week field. See examples for details.
      # @return [String] The html week field
      #
      def week_field_tag(name, options = {})
        options = { :name => name }.update(options)
        options = convert_attributes_into_datetime("%Y-W%W", options)
        input_tag(:week, options)
      end

      ##
      # Constructs a time tag from the given options.
      #
      # @example
      #   time_field_tag('time_with_min_max', :max => Time.new(1993, 2, 24, 1, 19, 12),
      #                                       :min => Time.new(2008, 6, 21, 13, 30, 0))
      #   time_field_tag('time_with_value', :value => Time.new(2008, 6, 21, 13, 30, 0))
      #
      # @param [String] name
      #   The name of the time field.
      # @param [Hash] options
      #   The html options for the time field.
      # @option options [Time, DateTime, String] :min
      #  The min time of the time field.
      # @option options [Time, DateTime, String] :max
      #  The max time of the time field.
      # @option options [Time, DateTime, String] :value
      #  The value of the time field. See examples for details.
      # @return [String] The html time field
      #
      def time_field_tag(name, options = {})
        options = { :name => name }.update(options)
        options = convert_attributes_into_datetime("%T.%L", options)
        input_tag(:time, options)
      end

      ##
      # Constructs a color tag from the given options.
      #
      # @example
      #   color_field_tag('color', :value => "#ff0000")
      #   color_field_tag('color', :value => "#f00")
      #
      # @param [String] name
      #   The name of the color field.
      # @param [Hash] options
      #   The html options for the color field.
      # @option options [String] :value
      #  The value of the color field. See examples for details.
      #
      def color_field_tag(name, options = {})
        options = { :name => name }.update(options)
        options[:value] = adjust_color(options[:value])
        input_tag(:color, options)
      end

      private

      ##
      # Returns an initialized builder instance for the given object and settings.
      #
      # @example
      #   builder_instance(@account, :nested => { ... }) => <FormBuilder>
      #
      def builder_instance(object, options={})
        default_builder = respond_to?(:settings) && settings.default_builder || 'StandardFormBuilder'
        builder_class = options.delete(:builder) || default_builder
        builder_class = Padrino::Helpers::FormBuilder.const_get(builder_class) if builder_class.is_a?(String)
        builder_class.new(self, object, options)
      end

      ##
      # Converts value into DateTime.
      #
      # @example
      #   datetime_value('1993-02-24T12:30:45') #=> #<DateTime: 1993-02-24T12:30:45+00:00>
      #
      def datetime_value(value)
        if value.kind_of?(String)
          DateTime.parse(value) rescue nil
        else
          value
        end
      end

      ##
      # Converts special attributes into datetime format strings that conforms to RFC 3399.
      #
      def convert_attributes_into_datetime(format, options)
        DATETIME_ATTRIBUTES.each_with_object(options) do |attribute|
          value = datetime_value(options[attribute])
          options[attribute] = value.strftime(format) if value.respond_to?(:strftime)
        end
      end

      ##
      # Adjusts color code for the given color.
      #
      # @example
      #   adust_color("#000")    #=> "#000000"
      #   adust_color("#ff0000") #=> "#ff0000"
      #   adust_color("#foobar") #=> "#000000"
      #
      def adjust_color(color)
        return "#000000" unless color =~ COLOR_CODE_REGEXP
        return color if (color_size = color.size) == 7
        color.slice(1, color_size - 1).each_char.with_object("#") do |chr, obj|
          obj << chr * 2
        end
      end
    end
  end
end
