require File.expand_path(File.dirname(__FILE__) + '/helper')
require File.expand_path(File.dirname(__FILE__) + '/fixtures/markup_app/app')

describe "FormHelpers" do
  include Padrino::Helpers::FormHelpers

  def app
    MarkupDemo
  end

  class UnprotectedApp
    def protect_from_csrf; false; end
  end

  describe 'for #form_tag method' do
    it 'should display correct forms in ruby' do
      actual_html = form_tag('/register', :"accept-charset" => "UTF-8", :class => 'test', :method => "post") { "Demo" }
      assert_has_tag(:form, :"accept-charset" => "UTF-8", :class => "test") { actual_html }
      assert_has_tag('form input', :type => 'hidden', :name => '_method', :count => 0) { actual_html }
    end

    it 'should display correct text inputs within form_tag' do
      actual_html = form_tag('/register', :"accept-charset" => "UTF-8", :class => 'test') { text_field_tag(:username) }
      assert_has_tag('form input', :type => 'text', :name => "username") { actual_html }
    end

    it 'should display correct form with remote' do
      actual_html = form_tag('/update', :"accept-charset" => "UTF-8", :class => 'put-form', :remote => true) { "Demo" }
      assert_has_tag(:form, :class => "put-form", :"accept-charset" => "UTF-8", :"data-remote" => 'true') { actual_html }
      assert_has_no_tag(:form, "data-method" => 'post') { actual_html }
    end

    it 'should display correct form with remote and method is put' do
      actual_html = form_tag('/update', :"accept-charset" => "UTF-8", :method => 'put', :remote => true) { "Demo" }
      assert_has_tag(:form, "data-remote" => 'true', :"accept-charset" => "UTF-8") { actual_html }
      assert_has_tag('form input', :type => 'hidden', :name => "_method", :value => 'put') { actual_html }
    end

    it 'should display correct form with method :put' do
      actual_html = form_tag('/update', :"accept-charset" => "UTF-8", :class => 'put-form', :method => "put") { "Demo" }
      assert_has_tag(:form, :class => "put-form", :"accept-charset" => "UTF-8", :method => 'post') { actual_html }
      assert_has_tag('form input', :type => 'hidden', :name => "_method", :value => 'put') { actual_html }
    end

    it 'should display correct form with method :delete and charset' do
      actual_html = form_tag('/remove', :"accept-charset" => "UTF-8", :class => 'delete-form', :method => "delete") { "Demo" }
      assert_has_tag(:form, :class => "delete-form", :"accept-charset" => "UTF-8", :method => 'post') { actual_html }
      assert_has_tag('form input', :type => 'hidden', :name => "_method", :value => 'delete') { actual_html }
    end

    it 'should display correct form with charset' do
      actual_html = form_tag('/charset', :"accept-charset" => "UTF-8", :class => 'charset-form') { "Demo" }
      assert_has_tag(:form, :class => "charset-form", :"accept-charset" => "UTF-8", :method => 'post') { actual_html }
    end

    it 'should display correct form with multipart encoding' do
      actual_html = form_tag('/remove', :"accept-charset" => "UTF-8", :multipart => true) { "Demo" }
      assert_has_tag(:form, :enctype => "multipart/form-data") { actual_html }
    end

    it 'should have an authenticity_token for method :post, :put or :delete' do
      %w(post put delete).each do |method|
        actual_html = form_tag('/modify', :method => method) { "Demo" }
        assert_has_tag(:input, :name => 'authenticity_token') { actual_html }
      end
    end

    it 'should not have an authenticity_token if method: :get' do
      actual_html = form_tag('/get', :method => :get) { "Demo" }
      assert_has_no_tag(:input, :name => 'authenticity_token') { actual_html }
    end

    it 'should have an authenticity_token by default' do
      actual_html = form_tag('/superadmindelete') { "Demo" }
      assert_has_tag(:input, :name => 'authenticity_token') { actual_html }
    end

    it 'should create csrf meta tags with token and param - #csrf_meta_tags' do
      actual_html = csrf_meta_tags
      assert_has_tag(:meta, :name => 'csrf-param') { actual_html }
      assert_has_tag(:meta, :name => 'csrf-token') { actual_html }
    end

    it 'should have an authenticity_token by default' do
      actual_html = form_tag('/superadmindelete') { "Demo" }
      assert_has_tag(:input, :name => 'authenticity_token') { actual_html }
    end

    it 'should not have an authenticity_token if passing protect_from_csrf: false' do
      actual_html = form_tag('/superadmindelete', :protect_from_csrf => false) { "Demo" }
      assert_has_no_tag(:input, :name => 'authenticity_token') { actual_html }
    end

    it 'should not have an authenticity_token if protect_from_csrf is false on app settings' do
      self.expects(:settings).returns(UnprotectedApp.new)
      actual_html = form_tag('/superadmindelete') { "Demo" }
      assert_has_no_tag(:input, :name => 'authenticity_token') { actual_html }
    end

    it 'should not include protect_from_csrf as an attribute of form element' do
      actual_html = form_tag('/superadmindelete', :protect_from_csrf => true){ "Demo" }
      assert_has_no_tag(:form, protect_from_csrf: "true"){ actual_html }
    end

    it 'should display correct forms in erb' do
      visit '/erb/form_tag'
      assert_have_selector 'form.simple-form', :action => '/simple'
      assert_have_selector 'form.advanced-form', :action => '/advanced', :id => 'advanced', :method => 'get'
      assert_have_selector 'form.simple-form input', :name => 'authenticity_token'
      assert_have_no_selector 'form.no-protection input', :name => 'authenticity_token'
    end

    it 'should display correct forms in haml' do
      visit '/haml/form_tag'
      assert_have_selector 'form.simple-form', :action => '/simple'
      assert_have_selector 'form.advanced-form', :action => '/advanced', :id => 'advanced', :method => 'get'
      assert_have_selector 'form.simple-form input', :name => 'authenticity_token'
      assert_have_no_selector 'form.no-protection input', :name => 'authenticity_token'
    end

    it 'should display correct forms in slim' do
      visit '/slim/form_tag'
      assert_have_selector 'form.simple-form', :action => '/simple'
      assert_have_selector 'form.advanced-form', :action => '/advanced', :id => 'advanced', :method => 'get'
      assert_have_selector 'form.simple-form input', :name => 'authenticity_token'
      assert_have_no_selector 'form.no-protection input', :name => 'authenticity_token'
    end
  end

  describe 'for #field_set_tag method' do
    it 'should display correct field_sets in ruby' do
      actual_html = field_set_tag("Basic", :class => 'basic') { "Demo" }
      assert_has_tag(:fieldset, :class => 'basic') { actual_html }
      assert_has_tag('fieldset legend', :content => "Basic") { actual_html }
    end

    it 'should display correct field_sets in erb' do
      visit '/erb/form_tag'
      assert_have_selector 'form.simple-form fieldset', :count => 1
      assert_have_no_selector 'form.simple-form fieldset legend'
      assert_have_selector 'form.advanced-form fieldset', :count => 1, :class => 'advanced-field-set'
      assert_have_selector 'form.advanced-form fieldset legend', :content => "Advanced"
    end

    it 'should display correct field_sets in haml' do
      visit '/haml/form_tag'
      assert_have_selector 'form.simple-form fieldset', :count => 1
      assert_have_no_selector 'form.simple-form fieldset legend'
      assert_have_selector 'form.advanced-form fieldset', :count => 1, :class => 'advanced-field-set'
      assert_have_selector 'form.advanced-form fieldset legend', :content => "Advanced"
    end

    it 'should display correct field_sets in slim' do
      visit '/slim/form_tag'
      assert_have_selector 'form.simple-form fieldset', :count => 1
      assert_have_no_selector 'form.simple-form fieldset legend'
      assert_have_selector 'form.advanced-form fieldset', :count => 1, :class => 'advanced-field-set'
      assert_have_selector 'form.advanced-form fieldset legend', :content => "Advanced"
    end
  end

  describe 'for #error_messages_for method' do
    it 'should display correct error messages list in ruby' do
      user = mock_model("User", :errors => { :a => "1", :b => "2" }, :blank? => false)
      actual_html = error_messages_for(user)
      assert_has_tag('div.field-errors') { actual_html }
      assert_has_tag('div.field-errors h2', :content => "2 errors prohibited this User from being saved") { actual_html }
      assert_has_tag('div.field-errors p', :content => "There were problems with the following fields:") { actual_html }
      assert_has_tag('div.field-errors ul') { actual_html }
      assert_has_tag('div.field-errors ul li', :count => 2) { actual_html }
    end

    it 'should display correct error messages list in erb' do
      visit '/erb/form_tag'
      assert_have_no_selector 'form.simple-form .field-errors'
      assert_have_selector 'form.advanced-form .field-errors'
      assert_have_selector 'form.advanced-form .field-errors h2', :content => "There are problems with saving user!"
      assert_have_selector 'form.advanced-form .field-errors p', :content => "There were problems with the following fields:"
      assert_have_selector 'form.advanced-form .field-errors ul'
      assert_have_selector 'form.advanced-form .field-errors ul li', :count => 4
      assert_have_selector 'form.advanced-form .field-errors ul li', :content => "Email must be an email"
      assert_have_selector 'form.advanced-form .field-errors ul li', :content => "Fake must be valid"
      assert_have_selector 'form.advanced-form .field-errors ul li', :content => "Second must be present"
      assert_have_selector 'form.advanced-form .field-errors ul li', :content => "Third must be a number"
    end

    it 'should display correct error messages list in haml' do
      visit '/haml/form_tag'
      assert_have_no_selector 'form.simple-form .field-errors'
      assert_have_selector 'form.advanced-form .field-errors'
      assert_have_selector 'form.advanced-form .field-errors h2', :content => "There are problems with saving user!"
      assert_have_selector 'form.advanced-form .field-errors p',  :content => "There were problems with the following fields:"
      assert_have_selector 'form.advanced-form .field-errors ul'
      assert_have_selector 'form.advanced-form .field-errors ul li', :count => 4
      assert_have_selector 'form.advanced-form .field-errors ul li', :content => "Email must be an email"
      assert_have_selector 'form.advanced-form .field-errors ul li', :content => "Fake must be valid"
      assert_have_selector 'form.advanced-form .field-errors ul li', :content => "Second must be present"
      assert_have_selector 'form.advanced-form .field-errors ul li', :content => "Third must be a number"
    end

    it 'should display correct error messages list in slim' do
      visit '/slim/form_tag'
      assert_have_no_selector 'form.simple-form .field-errors'
      assert_have_selector 'form.advanced-form .field-errors'
      assert_have_selector 'form.advanced-form .field-errors h2', :content => "There are problems with saving user!"
      assert_have_selector 'form.advanced-form .field-errors p',  :content => "There were problems with the following fields:"
      assert_have_selector 'form.advanced-form .field-errors ul'
      assert_have_selector 'form.advanced-form .field-errors ul li', :count => 4
      assert_have_selector 'form.advanced-form .field-errors ul li', :content => "Email must be an email"
      assert_have_selector 'form.advanced-form .field-errors ul li', :content => "Fake must be valid"
      assert_have_selector 'form.advanced-form .field-errors ul li', :content => "Second must be present"
      assert_have_selector 'form.advanced-form .field-errors ul li', :content => "Third must be a number"
    end
  end

  describe 'for #error_message_on method' do
    it 'should display correct error message on specified model name in ruby' do
      @user = mock_model("User", :errors => { :a => "1", :b => "2" }, :blank? => false)
      actual_html = error_message_on(:user, :a, :prepend => "foo", :append => "bar")
      assert_has_tag('span.error', :content => "foo 1 bar") { actual_html }
    end

    it 'should display correct error message on specified object in ruby' do
      @bob = mock_model("User", :errors => { :a => "1", :b => "2" }, :blank? => false)
      actual_html = error_message_on(@bob, :a, :prepend => "foo", :append => "bar")
      assert_has_tag('span.error', :content => "foo 1 bar") { actual_html }
    end

    it 'should display no message when error is not present' do
      @user = mock_model("User", :errors => { :a => "1", :b => "2" }, :blank? => false)
      actual_html = error_message_on(:user, :fake, :prepend => "foo", :append => "bar")
      assert actual_html.blank?
    end

    it 'should display no message when error is not present in an Array' do
      @user = mock_model("User", :errors => { :a => [], :b => "2" }, :blank? => false)
      actual_html = error_message_on(:user, :a, :prepend => "foo", :append => "bar")
      assert actual_html.blank?
    end
  end

  describe 'for #label_tag method' do
    it 'should display label tag in ruby' do
      actual_html = label_tag(:username, :class => 'long-label', :caption => "Nickname")
      assert_has_tag(:label, :for => 'username', :class => 'long-label', :content => "Nickname") { actual_html }
    end

    it 'should display label tag in ruby with required' do
      actual_html = label_tag(:username, :caption => "Nickname", :required => true)
      assert_has_tag(:label, :for => 'username', :content => 'Nickname') { actual_html }
      assert_has_tag('label[for=username] span.required', :content => "*") { actual_html }
    end

    it 'should display label tag in ruby with a block' do
      actual_html = label_tag(:admin, :class => 'long-label') { input_tag :checkbox }
      assert_has_tag(:label, :for => 'admin', :class => 'long-label', :content => "Admin") { actual_html }
      assert_has_tag('label input[type=checkbox]') { actual_html }
    end

    it 'should display label tag in erb for simple form' do
      visit '/erb/form_tag'
      assert_have_selector 'form.simple-form label', :count => 9
      assert_have_selector 'form.simple-form label', :content => "Username", :for => 'username'
      assert_have_selector 'form.simple-form label', :content => "Password", :for => 'password'
      assert_have_selector 'form.simple-form label', :content => "Gender", :for => 'gender'
    end

    it 'should display label tag in erb for advanced form' do
      visit '/erb/form_tag'
      assert_have_selector 'form.advanced-form label', :count => 11
      assert_have_selector 'form.advanced-form label.first', :content => "Nickname", :for => 'username'
      assert_have_selector 'form.advanced-form label.first', :content => "Password", :for => 'password'
      assert_have_selector 'form.advanced-form label.about', :content => "About Me", :for => 'about'
      assert_have_selector 'form.advanced-form label.photo', :content => "Photo"   , :for => 'photo'
      assert_have_selector 'form.advanced-form label.gender', :content => "Gender"   , :for => 'gender'
    end

    it 'should display label tag in haml for simple form' do
      visit '/haml/form_tag'
      assert_have_selector 'form.simple-form label', :count => 9
      assert_have_selector 'form.simple-form label', :content => "Username", :for => 'username'
      assert_have_selector 'form.simple-form label', :content => "Password", :for => 'password'
      assert_have_selector 'form.simple-form label', :content => "Gender", :for => 'gender'
    end

    it 'should display label tag in haml for advanced form' do
      visit '/haml/form_tag'
      assert_have_selector 'form.advanced-form label', :count => 11
      assert_have_selector 'form.advanced-form label.first', :content => "Nickname", :for => 'username'
      assert_have_selector 'form.advanced-form label.first', :content => "Password", :for => 'password'
      assert_have_selector 'form.advanced-form label.about', :content => "About Me", :for => 'about'
      assert_have_selector 'form.advanced-form label.photo', :content => "Photo"   , :for => 'photo'
      assert_have_selector 'form.advanced-form label.gender', :content => "Gender"   , :for => 'gender'
    end

    it 'should display label tag in slim for simple form' do
      visit '/slim/form_tag'
      assert_have_selector 'form.simple-form label', :count => 9
      assert_have_selector 'form.simple-form label', :content => "Username", :for => 'username'
      assert_have_selector 'form.simple-form label', :content => "Password", :for => 'password'
      assert_have_selector 'form.simple-form label', :content => "Gender", :for => 'gender'
    end

    it 'should display label tag in slim for advanced form' do
      visit '/slim/form_tag'
      assert_have_selector 'form.advanced-form label', :count => 11
      assert_have_selector 'form.advanced-form label.first', :content => "Nickname", :for => 'username'
      assert_have_selector 'form.advanced-form label.first', :content => "Password", :for => 'password'
      assert_have_selector 'form.advanced-form label.about', :content => "About Me", :for => 'about'
      assert_have_selector 'form.advanced-form label.photo', :content => "Photo"   , :for => 'photo'
      assert_have_selector 'form.advanced-form label.gender', :content => "Gender"   , :for => 'gender'
    end
  end

  describe 'for #hidden_field_tag method' do
    it 'should display hidden field in ruby' do
      actual_html = hidden_field_tag(:session_key, :id => 'session_id', :value => '56768')
      assert_has_tag(:input, :type => 'hidden', :id => "session_id", :name => 'session_key', :value => '56768') { actual_html }
    end

    it 'should display hidden field in erb' do
      visit '/erb/form_tag'
      assert_have_selector 'form.simple-form input[type=hidden]', :count => 1, :name => 'session_id', :value => "__secret__"
      assert_have_selector 'form.advanced-form input[type=hidden]', :count => 1, :name => 'session_id', :value => "__secret__"
    end

    it 'should display hidden field in haml' do
      visit '/haml/form_tag'
      assert_have_selector 'form.simple-form input[type=hidden]', :count => 1, :name => 'session_id', :value => "__secret__"
      assert_have_selector 'form.advanced-form input[type=hidden]', :count => 1, :name => 'session_id', :value => "__secret__"
    end

    it 'should display hidden field in slim' do
      visit '/slim/form_tag'
      assert_have_selector 'form.simple-form input[type=hidden]', :count => 1, :name => 'session_id', :value => "__secret__"
      assert_have_selector 'form.advanced-form input[type=hidden]', :count => 1, :name => 'session_id', :value => "__secret__"
    end
  end

  describe 'for #text_field_tag method' do
    it 'should display text field in ruby' do
      actual_html = text_field_tag(:username, :class => 'long')
      assert_has_tag(:input, :type => 'text', :class => "long", :name => 'username') { actual_html }
    end

    it 'should display text field in erb' do
      visit '/erb/form_tag'
      assert_have_selector 'form.simple-form input[type=text]', :count => 1, :name => 'username'
      assert_have_selector 'form.advanced-form fieldset input[type=text]', :count => 1, :name => 'username', :id => 'the_username'
    end

    it 'should display text field in haml' do
      visit '/haml/form_tag'
      assert_have_selector 'form.simple-form input[type=text]', :count => 1, :name => 'username'
      assert_have_selector 'form.advanced-form fieldset input[type=text]', :count => 1, :name => 'username', :id => 'the_username'
    end

    it 'should display text field in slim' do
      visit '/slim/form_tag'
      assert_have_selector 'form.simple-form input[type=text]', :count => 1, :name => 'username'
      assert_have_selector 'form.advanced-form fieldset input[type=text]', :count => 1, :name => 'username', :id => 'the_username'
    end
  end

  describe 'for #number_field_tag method' do
    it 'should display number field in ruby' do
      actual_html = number_field_tag(:age, :class => 'numeric')
      assert_has_tag(:input, :type => 'number', :class => 'numeric', :name => 'age') { actual_html }
    end

    it 'should display number field in erb' do
      visit '/erb/form_tag'
      assert_have_selector 'form.simple-form input[type=number]', :count => 1, :name => 'age'
      assert_have_selector 'form.advanced-form fieldset input[type=number]', :count => 1, :name => 'age', :class => 'numeric'
    end

    it 'should display number field in haml' do
      visit '/haml/form_tag'
      assert_have_selector 'form.simple-form input[type=number]', :count => 1, :name => 'age'
      assert_have_selector 'form.advanced-form fieldset input[type=number]', :count => 1, :name => 'age', :class => 'numeric'
    end

    it 'should display number field in slim' do
      visit '/slim/form_tag'
      assert_have_selector 'form.simple-form input[type=number]', :count => 1, :name => 'age'
      assert_have_selector 'form.advanced-form fieldset input[type=number]', :count => 1, :name => 'age', :class => 'numeric'
    end
  end

  describe 'for #telephone_field_tag method' do
    it 'should display number field in ruby' do
      actual_html = telephone_field_tag(:telephone, :class => 'numeric')
      assert_has_tag(:input, :type => 'tel', :class => 'numeric', :name => 'telephone') { actual_html }
    end

    it 'should display telephone field in erb' do
      visit '/erb/form_tag'
      assert_have_selector 'form.simple-form input[type=tel]', :count => 1, :name => 'telephone'
      assert_have_selector 'form.advanced-form fieldset input[type=tel]', :count => 1, :name => 'telephone', :class => 'numeric'
    end

    it 'should display telephone field in haml' do
      visit '/haml/form_tag'
      assert_have_selector 'form.simple-form input[type=tel]', :count => 1, :name => 'telephone'
      assert_have_selector 'form.advanced-form fieldset input[type=tel]', :count => 1, :name => 'telephone', :class => 'numeric'
    end

    it 'should display telephone field in slim' do
      visit '/slim/form_tag'
      assert_have_selector 'form.simple-form input[type=tel]', :count => 1, :name => 'telephone'
      assert_have_selector 'form.advanced-form fieldset input[type=tel]', :count => 1, :name => 'telephone', :class => 'numeric'
    end
  end

  describe 'for #search_field_tag method' do
    it 'should display search field in ruby' do
      actual_html = search_field_tag(:search, :class => 'string')
      assert_has_tag(:input, :type => 'search', :class => 'string', :name => 'search') { actual_html }
    end

    it 'should display search field in erb' do
      visit '/erb/form_tag'
      assert_have_selector 'form.simple-form input[type=search]', :count => 1, :name => 'search'
      assert_have_selector 'form.advanced-form fieldset input[type=search]', :count => 1, :name => 'search', :class => 'string'
    end

    it 'should display search field in haml' do
      visit '/haml/form_tag'
      assert_have_selector 'form.simple-form input[type=search]', :count => 1, :name => 'search'
      assert_have_selector 'form.advanced-form fieldset input[type=search]', :count => 1, :name => 'search', :class => 'string'
    end

    it 'should display search field in slim' do
      visit '/slim/form_tag'
      assert_have_selector 'form.simple-form input[type=search]', :count => 1, :name => 'search'
      assert_have_selector 'form.advanced-form fieldset input[type=search]', :count => 1, :name => 'search', :class => 'string'
    end
  end

  describe 'for #email_field_tag method' do
    it 'should display email field in ruby' do
      actual_html = email_field_tag(:email, :class => 'string')
      assert_has_tag(:input, :type => 'email', :class => 'string', :name => 'email') { actual_html }
    end

    it 'should display email field in erb' do
      visit '/erb/form_tag'
      assert_have_selector 'form.simple-form input[type=email]', :count => 1, :name => 'email'
      assert_have_selector 'form.advanced-form fieldset input[type=email]', :count => 1, :name => 'email', :class => 'string'
    end

    it 'should display email field in haml' do
      visit '/haml/form_tag'
      assert_have_selector 'form.simple-form input[type=email]', :count => 1, :name => 'email'
      assert_have_selector 'form.advanced-form fieldset input[type=email]', :count => 1, :name => 'email', :class => 'string'
    end

    it 'should display email field in slim' do
      visit '/slim/form_tag'
      assert_have_selector 'form.simple-form input[type=email]', :count => 1, :name => 'email'
      assert_have_selector 'form.advanced-form fieldset input[type=email]', :count => 1, :name => 'email', :class => 'string'
    end
  end

  describe 'for #url_field_tag method' do
    it 'should display url field in ruby' do
      actual_html = url_field_tag(:webpage, :class => 'string')
      assert_has_tag(:input, :type => 'url', :class => 'string', :name => 'webpage') { actual_html }
    end

    it 'should display url field in erb' do
      visit '/erb/form_tag'
      assert_have_selector 'form.simple-form input[type=url]', :count => 1, :name => 'webpage'
      assert_have_selector 'form.advanced-form fieldset input[type=url]', :count => 1, :name => 'webpage', :class => 'string'
    end

    it 'should display url field in haml' do
      visit '/haml/form_tag'
      assert_have_selector 'form.simple-form input[type=url]', :count => 1, :name => 'webpage'
      assert_have_selector 'form.advanced-form fieldset input[type=url]', :count => 1, :name => 'webpage', :class => 'string'
    end

    it 'should display url field in slim' do
      visit '/slim/form_tag'
      assert_have_selector 'form.simple-form input[type=url]', :count => 1, :name => 'webpage'
      assert_have_selector 'form.advanced-form fieldset input[type=url]', :count => 1, :name => 'webpage', :class => 'string'
    end
  end

  describe 'for #text_area_tag method' do
    it 'should display text area in ruby' do
      actual_html = text_area_tag(:about, :class => 'long')
      assert_has_tag(:textarea, :class => "long", :name => 'about') { actual_html }
    end

    it 'should display text area in ruby with specified content' do
      actual_html = text_area_tag(:about, :value => "a test", :rows => 5, :cols => 6)
      assert_has_tag(:textarea, :content => "a test", :name => 'about', :rows => "5", :cols => "6") { actual_html }
    end

    it 'should insert newline to before of content' do
      actual_html = text_area_tag(:about, :value => "\na test&".html_safe)
      assert_has_tag(:textarea, :content => "\na test&".html_safe, :name => 'about') { actual_html }
      assert_match(%r{<textarea[^>]*>\n\na test&</textarea>}, actual_html)
    end

    it 'should display text area in erb' do
      visit '/erb/form_tag'
      assert_have_selector 'form.advanced-form textarea', :count => 1, :name => 'about', :class => 'large'
    end

    it 'should display text area in haml' do
      visit '/haml/form_tag'
      assert_have_selector 'form.advanced-form textarea', :count => 1, :name => 'about', :class => 'large'
    end

    it 'should display text area in slim' do
      visit '/slim/form_tag'
      assert_have_selector 'form.advanced-form textarea', :count => 1, :name => 'about', :class => 'large'
    end
  end

  describe 'for #password_field_tag method' do
    it 'should display password field in ruby' do
      actual_html = password_field_tag(:password, :class => 'long')
      assert_has_tag(:input, :type => 'password', :class => "long", :name => 'password') { actual_html }
    end

    it 'should display password field in erb' do
      visit '/erb/form_tag'
      assert_have_selector 'form.simple-form input[type=password]', :count => 1, :name => 'password'
      assert_have_selector 'form.advanced-form input[type=password]', :count => 1, :name => 'password'
    end

    it 'should display password field in haml' do
      visit '/haml/form_tag'
      assert_have_selector 'form.simple-form input[type=password]', :count => 1, :name => 'password'
      assert_have_selector 'form.advanced-form input[type=password]', :count => 1, :name => 'password'
    end

    it 'should display password field in slim' do
      visit '/slim/form_tag'
      assert_have_selector 'form.simple-form input[type=password]', :count => 1, :name => 'password'
      assert_have_selector 'form.advanced-form input[type=password]', :count => 1, :name => 'password'
    end
  end

  describe 'for #file_field_tag method' do
    it 'should display file field in ruby' do
      actual_html = file_field_tag(:photo, :class => 'photo')
      assert_has_tag(:input, :type => 'file', :class => "photo", :name => 'photo') { actual_html }
    end

    it 'should have an array name with multiple option' do
      actual_html = file_field_tag(:photos, :multiple => true)
      assert_has_tag(:input, :name => 'photos[]') { actual_html }
    end

    it 'should display file field in erb' do
      visit '/erb/form_tag'
      assert_have_selector 'form.advanced-form input[type=file]', :count => 1, :name => 'photo', :class => 'upload'
    end

    it 'should display file field in haml' do
      visit '/haml/form_tag'
      assert_have_selector 'form.advanced-form input[type=file]', :count => 1, :name => 'photo', :class => 'upload'
    end

    it 'should display file field in slim' do
      visit '/slim/form_tag'
      assert_have_selector 'form.advanced-form input[type=file]', :count => 1, :name => 'photo', :class => 'upload'
    end
  end

  describe "for #check_box_tag method" do
    it 'should display check_box tag in ruby' do
      actual_html = check_box_tag("clear_session")
      assert_has_tag(:input, :type => 'checkbox', :value => '1', :name => 'clear_session') { actual_html }
      assert_has_no_tag(:input, :type => 'hidden') { actual_html }
    end

    it 'should display check_box tag in ruby with extended attributes' do
      actual_html = check_box_tag("clear_session", :disabled => true, :checked => true)
      assert_has_tag(:input, :type => 'checkbox', :disabled => 'disabled', :checked => 'checked') { actual_html }
    end

    it 'should display check_box tag in erb' do
      visit '/erb/form_tag'
      assert_have_selector 'form.simple-form input[type=checkbox]', :count => 1
      assert_have_selector 'form.advanced-form input[type=checkbox]', :value => "1", :checked => 'checked'
    end

    it 'should display check_box tag in haml' do
      visit '/haml/form_tag'
      assert_have_selector 'form.simple-form input[type=checkbox]', :count => 1
      assert_have_selector 'form.advanced-form input[type=checkbox]', :value => "1", :checked => 'checked'
    end

    it 'should display check_box tag in slim' do
      visit '/slim/form_tag'
      assert_have_selector 'form.simple-form input[type=checkbox]', :count => 1
      assert_have_selector 'form.advanced-form input[type=checkbox]', :value => "1", :checked => 'checked'
    end
  end

  describe "for #radio_button_tag method" do
    it 'should display radio_button tag in ruby' do
      actual_html = radio_button_tag("gender", :value => 'male')
      assert_has_tag(:input, :type => 'radio', :value => 'male', :name => 'gender') { actual_html }
    end

    it 'should display radio_button tag in ruby with extended attributes' do
      actual_html = radio_button_tag("gender", :disabled => true, :checked => true)
      assert_has_tag(:input, :type => 'radio', :disabled => 'disabled', :checked => 'checked') { actual_html }
    end

    it 'should display radio_button tag in erb' do
      visit '/erb/form_tag'
      assert_have_selector 'form.simple-form input[type=radio]', :count => 1, :value => 'male'
      assert_have_selector 'form.simple-form input[type=radio]', :count => 1, :value => 'female'
      assert_have_selector 'form.advanced-form input[type=radio]', :value => "male", :checked => 'checked'
      assert_have_selector 'form.advanced-form input[type=radio]', :value => "female"
    end

    it 'should display radio_button tag in haml' do
      visit '/haml/form_tag'
      assert_have_selector 'form.simple-form input[type=radio]', :count => 1, :value => 'male'
      assert_have_selector 'form.simple-form input[type=radio]', :count => 1, :value => 'female'
      assert_have_selector 'form.advanced-form input[type=radio]', :value => "male", :checked => 'checked'
      assert_have_selector 'form.advanced-form input[type=radio]', :value => "female"
    end

    it 'should display radio_button tag in slim' do
      visit '/slim/form_tag'
      assert_have_selector 'form.simple-form input[type=radio]', :count => 1, :value => 'male'
      assert_have_selector 'form.simple-form input[type=radio]', :count => 1, :value => 'female'
      assert_have_selector 'form.advanced-form input[type=radio]', :value => "male", :checked => 'checked'
      assert_have_selector 'form.advanced-form input[type=radio]', :value => "female"
    end
  end

  describe "for #select_tag method" do
    it 'should display select tag in ruby' do
      actual_html = select_tag(:favorite_color, :options => ['green', 'blue', 'black'], :include_blank => true)
      assert_has_tag(:select, :name => 'favorite_color') { actual_html }
      assert_has_tag('select option:first-child', :content => '') { actual_html }
      assert_has_tag('select option', :content => 'green', :value => 'green') { actual_html }
      assert_has_tag('select option', :content => 'blue',  :value => 'blue')  { actual_html }
      assert_has_tag('select option', :content => 'black', :value => 'black') { actual_html }
    end

    it 'should display select tag in ruby with extended attributes' do
      actual_html = select_tag(:favorite_color, :disabled => true, :options => ['only', 'option'])
      assert_has_tag(:select, :disabled => 'disabled') { actual_html }
    end

    it 'should take a range as a collection for options' do
      actual_html = select_tag(:favorite_color, :options => (1..3))
      assert_has_tag(:select) { actual_html }
      assert_has_tag('select option', :content => '1', :value => '1') { actual_html }
      assert_has_tag('select option', :content => '2', :value => '2') { actual_html }
      assert_has_tag('select option', :content => '3', :value => '3') { actual_html }
    end

    it 'should include blank for grouped options' do
      opts = { "Red"  => ["Rose","Fire"], "Blue" => ["Sky","Sea"] }
      actual_html = select_tag( 'color', :grouped_options => opts, :include_blank => true )
      assert_has_tag('select option:first-child', :value => "", :content => "") { actual_html }
    end

    it 'should include blank as caption' do
      opts = { "Red"  => ["Rose","Fire"], "Blue" => ["Sky","Sea"] }
      actual_html = select_tag( 'color', :grouped_options => opts, :include_blank => 'Choose your destiny' )
      assert_has_tag('select option:first-child', :value => "", :content => "Choose your destiny") { actual_html }
      assert_has_no_tag('select[include_blank]') { actual_html }
    end

    it 'should display select tag with grouped options for a nested array' do
      opts = [
        ["Friends",["Yoda",["Obiwan",2]]],
        ["Enemies", ["Palpatine",['Darth Vader',3]]]
      ]
      actual_html = select_tag( 'name', :grouped_options => opts )
      assert_has_tag(:select,   :name => "name") { actual_html }
      assert_has_tag(:optgroup, :label => "Friends") { actual_html }
      assert_has_tag(:option,   :value => "Yoda", :content => "Yoda") { actual_html }
      assert_has_tag(:option,   :value => "2",  :content => "Obiwan") { actual_html }
      assert_has_tag(:optgroup, :label => "Enemies") { actual_html }
      assert_has_tag(:option,   :value => "Palpatine", :content => "Palpatine") { actual_html }
      assert_has_tag(:option,   :value => "3", :content => "Darth Vader") { actual_html }
    end

    it 'should display select tag with grouped options for a nested array and accept disabled groups' do
      opts = [
        ["Friends",["Yoda",["Obiwan",2]]],
        ["Enemies", ["Palpatine",['Darth Vader',3]], {:disabled => true}]
      ]
      actual_html = select_tag( 'name', :grouped_options => opts )
      assert_has_tag(:select,   :name => "name") { actual_html }
      assert_has_tag(:option,   :disabled => 'disabled', :count => 0) { actual_html }
      assert_has_tag(:optgroup, :disabled => 'disabled', :count => 1) { actual_html }
      assert_has_tag(:optgroup, :label => "Enemies", :disabled => 'disabled') { actual_html }
    end

    it 'should display select tag with grouped options for a nested array and accept disabled groups and/or with disabled options' do
      opts = [
        ["Friends",["Yoda",["Obiwan",2, {:disabled => true}]]],
        ["Enemies", [["Palpatine", "Palpatine", {:disabled => true}],['Darth Vader',3]], {:disabled => true}]
      ]
      actual_html = select_tag( 'name', :grouped_options => opts )
      assert_has_tag(:select,   :name => "name") { actual_html }
      assert_has_tag(:option,   :disabled => 'disabled', :count => 2) { actual_html }
      assert_has_tag(:optgroup, :disabled => 'disabled', :count => 1) { actual_html }
      assert_has_tag(:option,   :content => "Obiwan", :disabled => 'disabled') { actual_html }
      assert_has_tag(:optgroup, :label => "Enemies", :disabled => 'disabled') { actual_html }
      assert_has_tag(:option,   :value => "Palpatine", :content => "Palpatine", :disabled => 'disabled') { actual_html }
    end

    it 'should display select tag with grouped options for a hash' do
      opts = {
        "Friends" => ["Yoda",["Obiwan",2]],
        "Enemies" => ["Palpatine",['Darth Vader',3]]
      }
      actual_html = select_tag( 'name', :grouped_options => opts )
      assert_has_tag(:select,   :name  => "name")    { actual_html }
      assert_has_tag(:optgroup, :label => "Friends") { actual_html }
      assert_has_tag(:option,   :value => "Yoda", :content => "Yoda")   { actual_html }
      assert_has_tag(:option,   :value => "2",    :content => "Obiwan") { actual_html }
      assert_has_tag(:optgroup, :label => "Enemies") { actual_html }
      assert_has_tag(:option,   :value => "Palpatine", :content => "Palpatine") { actual_html }
      assert_has_tag(:option,   :value => "3", :content => "Darth Vader") { actual_html }
    end

    it 'should display select tag with grouped options for a hash and accept disabled groups and/or with disabled options' do
      opts = {
        "Friends" => ["Yoda",["Obiwan",2,{:disabled => true}]],
        "Enemies" => [["Palpatine","Palpatine",{:disabled => true}],["Darth Vader",3], {:disabled => true}]
      }
      actual_html = select_tag( 'name', :grouped_options => opts )
      assert_has_tag(:select,   :name => "name") { actual_html }
      assert_has_tag(:option,   :disabled => 'disabled', :count => 2) { actual_html }
      assert_has_tag(:optgroup, :disabled => 'disabled', :count => 1) { actual_html }
      assert_has_tag(:option,   :content => "Obiwan", :disabled => 'disabled') { actual_html }
      assert_has_tag(:optgroup, :label => "Enemies", :disabled => 'disabled') { actual_html }
      assert_has_tag(:option,   :value => "Palpatine", :content => "Palpatine", :disabled => 'disabled') { actual_html }
    end

    it 'should display select tag with grouped options for a rails-style attribute hash' do
      opts = {
        "Friends" => ["Yoda",["Obiwan",2,{:magister=>'no'}],{:lame=>'yes'}],
        "Enemies" => [["Palpatine","Palpatine",{:scary=>'yes',:old=>'yes'}],["Darth Vader",3,{:disabled=>true}]]
      }
      actual_html = select_tag( 'name', :grouped_options => opts, :disabled_options => [2], :selected => ['Yoda'] )
      assert_has_tag(:optgroup, :label => "Friends", :lame => 'yes') { actual_html }
      assert_has_tag(:option,   :value => "Palpatine", :content => "Palpatine", :scary => 'yes', :old => 'yes') { actual_html }
      assert_has_tag(:option,   :content => "Darth Vader", :disabled => 'disabled') { actual_html }
      assert_has_tag(:option,   :content => "Obiwan", :disabled => 'disabled') { actual_html }
      assert_has_tag(:option,   :content => "Yoda", :selected => 'selected') { actual_html }
    end

    it 'should display select tag in ruby with multiple attribute' do
      actual_html = select_tag(:favorite_color, :multiple => true, :options => ['only', 'option'])
      assert_has_tag(:select, :multiple => 'multiple', :name => 'favorite_color[]') { actual_html }
    end

    it 'should display options with values and single selected' do
      options = [['Green', 'green1'], ['Blue', 'blue1'], ['Black', "black1"]]
      actual_html = select_tag(:favorite_color, :options => options, :selected => 'green1')
      assert_has_tag(:select, :name => 'favorite_color') { actual_html }
      assert_has_tag('select option', :selected => 'selected', :count => 1) { actual_html }
      assert_has_tag('select option', :content => 'Green', :value => 'green1', :selected => 'selected') { actual_html }
      assert_has_tag('select option', :content => 'Blue', :value => 'blue1') { actual_html }
      assert_has_tag('select option', :content => 'Black', :value => 'black1') { actual_html }
    end

    it 'should display options with values and accept disabled options' do
      options = [['Green', 'green1', {:disabled => true}], ['Blue', 'blue1'], ['Black', "black1"]]
      actual_html = select_tag(:favorite_color, :options => options)
      assert_has_tag(:select, :name => 'favorite_color') { actual_html }
      assert_has_tag('select option', :disabled => 'disabled', :count => 1) { actual_html }
      assert_has_tag('select option', :content => 'Green', :value => 'green1', :disabled => 'disabled') { actual_html }
      assert_has_tag('select option', :content => 'Blue', :value => 'blue1') { actual_html }
      assert_has_tag('select option', :content => 'Black', :value => 'black1') { actual_html }
    end

    it 'should display option with values and multiple selected' do
      options = [['Green', 'green1'], ['Blue', 'blue1'], ['Black', "black1"]]
      actual_html = select_tag(:favorite_color, :options => options, :selected => ['green1', 'Black'])
      assert_has_tag(:select, :name => 'favorite_color') { actual_html }
      assert_has_tag('select option', :selected => 'selected', :count => 2) { actual_html }
      assert_has_tag('select option', :content => 'Green', :value => 'green1', :selected => 'selected') { actual_html }
      assert_has_tag('select option', :content => 'Blue', :value => 'blue1') { actual_html }
      assert_has_tag('select option', :content => 'Black', :value => 'black1', :selected => 'selected') { actual_html }
    end

    it 'should not misselect options with default value' do
      options = ['Green', 'Blue']
      actual_html = select_tag(:favorite_color, :options => options, :selected => ['Green', ''])
      assert_has_tag('select option', :selected => 'selected', :count => 1) { actual_html }
      assert_has_tag('select option', :content => 'Green', :value => 'Green', :selected => 'selected') { actual_html }
    end

    it 'should display options selected only for exact match' do
      options = [['One', '1'], ['1', '10'], ['Two', "-1"]]
      actual_html = select_tag(:range, :options => options, :selected => '-1')
      assert_has_tag(:select, :name => 'range') { actual_html }
      assert_has_tag('select option', :selected => 'selected', :count => 1) { actual_html }
      assert_has_tag('select option', :content => 'Two', :value => '-1', :selected => 'selected') { actual_html }
    end

    it 'should display select tag in erb' do
      visit '/erb/form_tag'
      assert_have_selector 'form.simple-form select', :count => 1, :name => 'color'
      assert_have_selector('select option', :content => 'green',  :value => 'green')
      assert_have_selector('select option', :content => 'orange', :value => 'orange')
      assert_have_selector('select option', :content => 'purple', :value => 'purple')
      assert_have_selector('form.advanced-form select', :name => 'fav_color')
      assert_have_selector('select option', :content => 'green',  :value => '1')
      assert_have_selector('select option', :content => 'orange', :value => '2', :selected => 'selected')
      assert_have_selector('select option', :content => 'purple', :value => '3')
      assert_have_selector('select optgroup', :label => 'foo')
      assert_have_selector('select optgroup', :label => 'bar')
      assert_have_selector('select optgroup option', :content => 'foo', :value => 'foo')
      assert_have_selector('select optgroup option', :content => 'bar', :value => 'bar')
      assert_have_selector('select optgroup', :label => 'Friends')
      assert_have_selector('select optgroup', :label => 'Enemies')
      assert_have_selector('select optgroup option', :content => 'Yoda', :value => 'Yoda')
      assert_have_selector('select optgroup option', :content => 'Obiwan', :value => '1')
      assert_have_selector('select optgroup option', :content => 'Palpatine', :value => 'Palpatine')
      assert_have_selector('select optgroup option', :content => 'Darth Vader', :value => '3')
    end

    it 'should display select tag in haml' do
      visit '/haml/form_tag'
      assert_have_selector 'form.simple-form select', :count => 1, :name => 'color'
      assert_have_selector('select option', :content => 'green',  :value => 'green')
      assert_have_selector('select option', :content => 'orange', :value => 'orange')
      assert_have_selector('select option', :content => 'purple', :value => 'purple')
      assert_have_selector('form.advanced-form select', :name => 'fav_color')
      assert_have_selector('select option', :content => 'green',  :value => '1')
      assert_have_selector('select option', :content => 'orange', :value => '2', :selected => 'selected')
      assert_have_selector('select option', :content => 'purple', :value => '3')
      assert_have_selector('select optgroup', :label => 'foo')
      assert_have_selector('select optgroup', :label => 'bar')
      assert_have_selector('select optgroup option', :content => 'foo', :value => 'foo')
      assert_have_selector('select optgroup option', :content => 'bar', :value => 'bar')
      assert_have_selector('select optgroup', :label => 'Friends')
      assert_have_selector('select optgroup', :label => 'Enemies')
      assert_have_selector('select optgroup option', :content => 'Yoda', :value => 'Yoda')
      assert_have_selector('select optgroup option', :content => 'Obiwan', :value => '1')
      assert_have_selector('select optgroup option', :content => 'Palpatine', :value => 'Palpatine')
      assert_have_selector('select optgroup option', :content => 'Darth Vader', :value => '3')
    end

    it 'should display select tag in slim' do
      visit '/slim/form_tag'
      assert_have_selector 'form.simple-form select', :count => 1, :name => 'color'
      assert_have_selector('select option', :content => 'green',  :value => 'green')
      assert_have_selector('select option', :content => 'orange', :value => 'orange')
      assert_have_selector('select option', :content => 'purple', :value => 'purple')
      assert_have_selector('form.advanced-form select', :name => 'fav_color')
      assert_have_selector('select option', :content => 'green',  :value => '1')
      assert_have_selector('select option', :content => 'orange', :value => '2', :selected => 'selected')
      assert_have_selector('select option', :content => 'purple', :value => '3')
      assert_have_selector('select optgroup', :label => 'foo')
      assert_have_selector('select optgroup', :label => 'bar')
      assert_have_selector('select optgroup option', :content => 'foo', :value => 'foo')
      assert_have_selector('select optgroup option', :content => 'bar', :value => 'bar')
      assert_have_selector('select optgroup', :label => 'Friends')
      assert_have_selector('select optgroup', :label => 'Enemies')
      assert_have_selector('select optgroup option', :content => 'Yoda', :value => 'Yoda')
      assert_have_selector('select optgroup option', :content => 'Obiwan', :value => '1')
      assert_have_selector('select optgroup option', :content => 'Palpatine', :value => 'Palpatine')
      assert_have_selector('select optgroup option', :content => 'Darth Vader', :value => '3')
    end
  end

  describe 'for #submit_tag method' do
    it 'should display submit tag in ruby' do
      actual_html = submit_tag("Update", :class => 'success')
      assert_has_tag(:input, :type => 'submit', :class => "success", :value => 'Update') { actual_html }
    end

    it 'should display submit tag in erb' do
      visit '/erb/form_tag'
      assert_have_selector 'form.simple-form input[type=submit]', :count => 1, :value => "Submit"
      assert_have_selector 'form.advanced-form input[type=submit]', :count => 1, :value => "Login"
    end

    it 'should display submit tag in haml' do
      visit '/haml/form_tag'
      assert_have_selector 'form.simple-form input[type=submit]', :count => 1, :value => "Submit"
      assert_have_selector 'form.advanced-form input[type=submit]', :count => 1, :value => "Login"
    end

    it 'should display submit tag in slim' do
      visit '/slim/form_tag'
      assert_have_selector 'form.simple-form input[type=submit]', :count => 1, :value => "Submit"
      assert_have_selector 'form.advanced-form input[type=submit]', :count => 1, :value => "Login"
    end

    describe 'for omitted args' do
      it 'should display submit tag with default caption' do
        actual_html = submit_tag()
        assert_has_tag(:input, :type => 'submit', :value => 'Submit') { actual_html }
      end
    end

    describe 'for omitted caption arg' do
      it 'should display submit tag with default caption' do
        actual_html = submit_tag(:class => 'success')
        assert_has_tag(:input, :type => 'submit', :class => 'success', :value => 'Submit') { actual_html }
      end

      it 'should display submit tag without caption value when nil' do
        actual_html = submit_tag(nil, :class => 'success')
        assert_has_tag(:input, :type => 'submit', :class => 'success') { actual_html }
        assert_has_no_tag(:input, :type => 'submit', :class => 'success', :value => 'Submit') { actual_html }
      end
    end
  end

  describe 'for #button_tag method' do
    it 'should display submit tag in ruby' do
      actual_html = button_tag("Cancel", :class => 'clear')
      assert_has_tag(:input, :type => 'button', :class => "clear", :value => 'Cancel') { actual_html }
    end

    it 'should display submit tag in erb' do
      visit '/erb/form_tag'
      assert_have_selector 'form.advanced-form input[type=button]', :count => 1, :value => "Cancel"
    end

    it 'should display submit tag in haml' do
      visit '/haml/form_tag'
      assert_have_selector 'form.advanced-form input[type=button]', :count => 1, :value => "Cancel"
    end

    it 'should display submit tag in slim' do
      visit '/slim/form_tag'
      assert_have_selector 'form.advanced-form input[type=button]', :count => 1, :value => "Cancel"
    end
  end

  describe 'for #image_submit_tag method' do
    before do
      @stamp = stop_time_for_test.to_i
    end

    it 'should display image submit tag in ruby with relative path' do
      actual_html = image_submit_tag('buttons/ok.png', :class => 'success')
      assert_has_tag(:input, :type => 'image', :class => "success", :src => "/images/buttons/ok.png?#{@stamp}") { actual_html }
    end

    it 'should display image submit tag in ruby with absolute path' do
      actual_html = image_submit_tag('/system/ok.png', :class => 'success')
      assert_has_tag(:input, :type => 'image', :class => "success", :src => "/system/ok.png") { actual_html }
    end

    it 'should display image submit tag in erb' do
      visit '/erb/form_tag'
      assert_have_selector 'form.advanced-form input[type=image]', :count => 1, :src => "/images/buttons/submit.png?#{@stamp}"
    end

    it 'should display image submit tag in haml' do
      visit '/haml/form_tag'
      assert_have_selector 'form.advanced-form input[type=image]', :count => 1, :src => "/images/buttons/submit.png?#{@stamp}"
    end

    it 'should display image submit tag in slim' do
      visit '/slim/form_tag'
      assert_have_selector 'form.advanced-form input[type=image]', :count => 1, :src => "/images/buttons/submit.png?#{@stamp}"
    end
  end

  describe 'for #button_to method' do
    it 'should have a form and set the method properly' do
      actual_html = button_to('Delete', '/users/1', :method => :delete)
      assert_has_tag('form', :action => '/users/1') { actual_html }
      assert_has_tag('form input', :type => 'hidden', :name => "_method", :value => 'delete') { actual_html }
      assert_has_tag('form input', :type => 'hidden', :name => "authenticity_token") { actual_html }
    end

    it 'should add a submit button by default if no content is specified' do
      actual_html = button_to('My Delete Button', '/users/1', :method => :delete)
      assert_has_tag('form input', :type => 'submit', :value => 'My Delete Button') { actual_html }
    end

    it 'should set specific content inside the form if a block was sent' do
      actual_html = button_to('My Delete Button', '/users/1', :method => :delete) do
        content_tag :button, "My button's content", :type => :submit, :title => "My button"
      end
      assert_has_tag('form button', :type => 'submit', :content => "My button's content", :title => "My button") { actual_html }
    end

    it 'should pass options on submit button when submit_options are given' do
      actual_html = button_to("Fancy button", '/users/1', :submit_options => { :class => :fancy })
      assert_has_tag('form input', :type => 'submit', :value => 'Fancy button', :class => 'fancy') { actual_html }
      assert_has_no_tag('form', :"submit_options-class" => 'fancy'){ actual_html }
    end

    it 'should display correct button_to in erb' do
      visit '/erb/button_to'
      assert_have_selector('form', :action => '/foo')
      assert_have_selector('form label', :for => 'username', :content => 'Username: ')
      assert_have_selector('form', :action => '/bar')
      assert_have_selector('#test-point ~ form > input[type=submit]', :value => 'Bar button')
    end

    it 'should display correct button_to in haml' do
      visit '/haml/button_to'
      assert_have_selector('form', :action => '/foo')
      assert_have_selector('form label', :for => 'username', :content => 'Username: ')
      assert_have_selector('form', :action => '/bar')
      assert_have_selector('#test-point ~ form > input[type=submit]', :value => 'Bar button')
    end

    it 'should display correct button_to in slim' do
      visit '/slim/button_to'
      assert_have_selector('form', :action => '/foo')
      assert_have_selector('form label', :for => 'username', :content => 'Username: ')
      assert_have_selector('form', :action => '/bar')
      assert_have_selector('#test-point ~ form > input[type=submit]', :value => 'Bar button')
    end
  end

  describe 'for #range_field_tag' do
    it 'should create an input tag with min and max options' do
      actual_html = range_field_tag('ranger', :min => 20, :max => 50)
      assert_has_tag('input', :type => 'range', :name => 'ranger', :min => '20', :max => '50') { actual_html }
    end

    it 'should create an input tag with range' do
      actual_html = range_field_tag('ranger', :range => 1..20)
      assert_has_tag('input', :min => '1', :max => '20') { actual_html }
    end

    it 'should display correct range_field_tag in erb' do
      visit '/erb/form_tag'
      assert_have_selector 'input', :type => 'range', :name => 'ranger_with_min_max', :min => '1', :max => '50', :count => 1
      assert_have_selector 'input', :type => 'range', :name => 'ranger_with_range', :min => '1', :max => '5', :count => 1
    end

    it 'should display correct range_field_tag in haml' do
      visit '/haml/form_tag'
      assert_have_selector 'input', :type => 'range', :name => 'ranger_with_min_max', :min => '1', :max => '50', :count => 1
      assert_have_selector 'input', :type => 'range', :name => 'ranger_with_range', :min => '1', :max => '5', :count => 1
    end

    it 'should display correct range_field_tag in slim' do
      visit '/slim/form_tag'
      assert_have_selector 'input', :type => 'range', :name => 'ranger_with_min_max', :min => '1', :max => '50', :count => 1
      assert_have_selector 'input', :type => 'range', :name => 'ranger_with_range', :min => '1', :max => '5', :count => 1
    end
  end
end
