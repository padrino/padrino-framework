require File.expand_path(File.dirname(__FILE__) + '/helper')
require File.expand_path(File.dirname(__FILE__) + '/fixtures/markup_app/app')

class TestFormHelpers < Test::Unit::TestCase
  include Padrino::Helpers::FormHelpers

  def app
    MarkupDemo.tap { |app| app.set :environment, :test }
  end

  context 'for #form_tag method' do
    should "display correct forms in ruby" do
      actual_html = form_tag('/register', :class => 'test', :method => "post") { "Demo" }
      assert_has_tag(:form, :class => "test") { actual_html }
      assert_has_tag('form input', :type => 'hidden', :name => '_method', :count => 0) { actual_html }
    end

    should "display correct text inputs within form_tag" do
      actual_html = form_tag('/register', :class => 'test') { text_field_tag(:username) }
      assert_has_tag('form input', :type => 'text', :name => "username") { actual_html }
    end
    
    should "display correct form with remote" do
      actual_html = form_tag('/update', :class => 'put-form', :remote => true) { "Demo" }
      assert_has_tag(:form, :class => "put-form", "data-remote" => 'true') { actual_html }
      assert_has_no_tag(:form, "data-method" => 'post') { actual_html }
    end
    
    should "display correct form with remote and method is put" do
      actual_html = form_tag('/update', :method => 'put', :remote => true) { "Demo" }
      assert_has_tag(:form, "data-remote" => 'true', "data-method" => 'put') { actual_html }
      assert_has_tag('form input', :type => 'hidden', :name => "_method", :value => 'put') { actual_html }
    end

    should "display correct form with method :put" do
      actual_html = form_tag('/update', :class => 'put-form', :method => "put") { "Demo" }
      assert_has_tag(:form, :class => "put-form", :method => 'post') { actual_html }
      assert_has_tag('form input', :type => 'hidden', :name => "_method", :value => 'put') { actual_html }
    end

    should "display correct form with method :delete" do
      actual_html = form_tag('/remove', :class => 'delete-form', :method => "delete") { "Demo" }
      assert_has_tag(:form, :class => "delete-form", :method => 'post') { actual_html }
      assert_has_tag('form input', :type => 'hidden', :name => "_method", :value => 'delete') { actual_html }
    end

    should "display correct form with multipart encoding" do
      actual_html = form_tag('/remove', :multipart => true) { "Demo" }
      assert_has_tag(:form, :enctype => "multipart/form-data") { actual_html }
    end

    should "display correct forms in erb" do
      visit '/erb/form_tag'
      assert_have_selector 'form.simple-form', :action => '/simple'
      assert_have_selector 'form.advanced-form', :action => '/advanced', :id => 'advanced', :method => 'get'
    end

    should "display correct forms in haml" do
      visit '/haml/form_tag'
      assert_have_selector 'form.simple-form', :action => '/simple'
      assert_have_selector 'form.advanced-form', :action => '/advanced', :id => 'advanced', :method => 'get'
    end
  end

  context 'for #field_set_tag method' do
    should "display correct field_sets in ruby" do
      actual_html = field_set_tag("Basic", :class => 'basic') { "Demo" }
      assert_has_tag(:fieldset, :class => 'basic') { actual_html }
      assert_has_tag('fieldset legend', :content => "Basic") { actual_html }
    end

    should "display correct field_sets in erb" do
      visit '/erb/form_tag'
      assert_have_selector 'form.simple-form fieldset', :count => 1
      assert_have_no_selector 'form.simple-form fieldset legend'
      assert_have_selector 'form.advanced-form fieldset', :count => 1, :class => 'advanced-field-set'
      assert_have_selector 'form.advanced-form fieldset legend', :content => "Advanced"
    end

    should "display correct field_sets in haml" do
      visit '/haml/form_tag'
      assert_have_selector 'form.simple-form fieldset', :count => 1
      assert_have_no_selector 'form.simple-form fieldset legend'
      assert_have_selector 'form.advanced-form fieldset', :count => 1, :class => 'advanced-field-set'
      assert_have_selector 'form.advanced-form fieldset legend', :content => "Advanced"
    end
  end

  context 'for #error_messages_for method' do
    should "display correct error messages list in ruby" do
      user = stub(:class => "User", :errors => { :a => "1", :b => "2" }, :blank? => false)
      actual_html = error_messages_for(user)
      assert_has_tag('div.field-errors') { actual_html }
      assert_has_tag('div.field-errors h2', :content => "2 errors prohibited this User from being saved") { actual_html }
      assert_has_tag('div.field-errors p', :content => "There were problems with the following fields:") { actual_html }
      assert_has_tag('div.field-errors ul') { actual_html }
      assert_has_tag('div.field-errors ul li', :count => 2) { actual_html }
    end

    should "display correct error messages list in erb" do
      visit '/erb/form_tag'
      assert_have_no_selector 'form.simple-form .field-errors'
      assert_have_selector 'form.advanced-form .field-errors'
      assert_have_selector 'form.advanced-form .field-errors h2', :content => "There are problems with saving user!"
      assert_have_selector 'form.advanced-form .field-errors p', :content => "There were problems with the following fields:"
      assert_have_selector 'form.advanced-form .field-errors ul'
      assert_have_selector 'form.advanced-form .field-errors ul li', :count => 4
      assert_have_selector 'form.advanced-form .field-errors ul li', :content => "Email must be a email"
      assert_have_selector 'form.advanced-form .field-errors ul li', :content => "Fake must be valid"
      assert_have_selector 'form.advanced-form .field-errors ul li', :content => "Second must be present"
      assert_have_selector 'form.advanced-form .field-errors ul li', :content => "Third must be a number"
    end

    should "display correct error messages list in haml" do
      visit '/haml/form_tag'
      assert_have_no_selector 'form.simple-form .field-errors'
      assert_have_selector 'form.advanced-form .field-errors'
      assert_have_selector 'form.advanced-form .field-errors h2', :content => "There are problems with saving user!"
      assert_have_selector 'form.advanced-form .field-errors p',  :content => "There were problems with the following fields:"
      assert_have_selector 'form.advanced-form .field-errors ul'
      assert_have_selector 'form.advanced-form .field-errors ul li', :count => 4
      assert_have_selector 'form.advanced-form .field-errors ul li', :content => "Email must be a email"
      assert_have_selector 'form.advanced-form .field-errors ul li', :content => "Fake must be valid"
      assert_have_selector 'form.advanced-form .field-errors ul li', :content => "Second must be present"
      assert_have_selector 'form.advanced-form .field-errors ul li', :content => "Third must be a number"
    end
  end

  context 'for #label_tag method' do
    should "display label tag in ruby" do
      actual_html = label_tag(:username, :class => 'long-label', :caption => "Nickname")
      assert_has_tag(:label, :for => 'username', :class => 'long-label', :content => "Nickname") { actual_html }
    end
    
    should "display label tag in ruby with required" do
      actual_html = label_tag(:username, :caption => "Nickname", :required => true)
      assert_has_tag(:label, :for => 'username', :content => 'Nickname') { actual_html }
      assert_has_tag('label[for=username] span.required', :content => "*") { actual_html }
    end

    should "display label tag in erb for simple form" do
      visit '/erb/form_tag'
      assert_have_selector 'form.simple-form label', :count => 4
      assert_have_selector 'form.simple-form label', :content => "Username", :for => 'username'
      assert_have_selector 'form.simple-form label', :content => "Password", :for => 'password'
      assert_have_selector 'form.simple-form label', :content => "Gender", :for => 'gender'
    end
    should "display label tag in erb for advanced form" do
      visit '/erb/form_tag'
      assert_have_selector 'form.advanced-form label', :count => 6
      assert_have_selector 'form.advanced-form label.first', :content => "Nickname", :for => 'username'
      assert_have_selector 'form.advanced-form label.first', :content => "Password", :for => 'password'
      assert_have_selector 'form.advanced-form label.about', :content => "About Me", :for => 'about'
      assert_have_selector 'form.advanced-form label.photo', :content => "Photo"   , :for => 'photo'
      assert_have_selector 'form.advanced-form label.gender', :content => "Gender"   , :for => 'gender'
    end

    should "display label tag in haml for simple form" do
      visit '/haml/form_tag'
      assert_have_selector 'form.simple-form label', :count => 4
      assert_have_selector 'form.simple-form label', :content => "Username", :for => 'username'
      assert_have_selector 'form.simple-form label', :content => "Password", :for => 'password'
      assert_have_selector 'form.simple-form label', :content => "Gender", :for => 'gender'
    end
    should "display label tag in haml for advanced form" do
      visit '/haml/form_tag'
      assert_have_selector 'form.advanced-form label', :count => 6
      assert_have_selector 'form.advanced-form label.first', :content => "Nickname", :for => 'username'
      assert_have_selector 'form.advanced-form label.first', :content => "Password", :for => 'password'
      assert_have_selector 'form.advanced-form label.about', :content => "About Me", :for => 'about'
      assert_have_selector 'form.advanced-form label.photo', :content => "Photo"   , :for => 'photo'
      assert_have_selector 'form.advanced-form label.gender', :content => "Gender"   , :for => 'gender'
    end
  end

  context 'for #hidden_field_tag method' do
    should "display hidden field in ruby" do
      actual_html = hidden_field_tag(:session_key, :id => 'session_id', :value => '56768')
      assert_has_tag(:input, :type => 'hidden', :id => "session_id", :name => 'session_key', :value => '56768') { actual_html }
    end

    should "display hidden field in erb" do
      visit '/erb/form_tag'
      assert_have_selector 'form.simple-form input[type=hidden]', :count => 1, :name => 'session_id', :value => "__secret__"
      assert_have_selector 'form.advanced-form input[type=hidden]', :count => 1, :name => 'session_id', :value => "__secret__"
    end

    should "display hidden field in haml" do
      visit '/haml/form_tag'
      assert_have_selector 'form.simple-form input[type=hidden]', :count => 1, :name => 'session_id', :value => "__secret__"
      assert_have_selector 'form.advanced-form input[type=hidden]', :count => 1, :name => 'session_id', :value => "__secret__"
    end
  end

  context 'for #text_field_tag method' do
    should "display text field in ruby" do
      actual_html = text_field_tag(:username, :class => 'long')
      assert_has_tag(:input, :type => 'text', :class => "long", :name => 'username') { actual_html }
    end

    should "display text field in erb" do
      visit '/erb/form_tag'
      assert_have_selector 'form.simple-form input[type=text]', :count => 1, :name => 'username'
      assert_have_selector 'form.advanced-form fieldset input[type=text]', :count => 1, :name => 'username', :id => 'the_username'
    end

    should "display text field in haml" do
      visit '/haml/form_tag'
      assert_have_selector 'form.simple-form input[type=text]', :count => 1, :name => 'username'
      assert_have_selector 'form.advanced-form fieldset input[type=text]', :count => 1, :name => 'username', :id => 'the_username'
    end
  end

  context 'for #text_area_tag method' do
    should "display text area in ruby" do
      actual_html = text_area_tag(:about, :class => 'long')
      assert_has_tag(:textarea, :class => "long", :name => 'about') { actual_html }
    end

    should "display text area in ruby with specified content" do
      actual_html = text_area_tag(:about, :value => "a test")
      assert_has_tag(:textarea, :content => "a test", :name => 'about') { actual_html }
    end

    should "display text area in erb" do
      visit '/erb/form_tag'
      assert_have_selector 'form.advanced-form textarea', :count => 1, :name => 'about', :class => 'large'
    end

    should "display text area in haml" do
      visit '/haml/form_tag'
      assert_have_selector 'form.advanced-form textarea', :count => 1, :name => 'about', :class => 'large'
    end
  end

  context 'for #password_field_tag method' do
    should "display password field in ruby" do
      actual_html = password_field_tag(:password, :class => 'long')
      assert_has_tag(:input, :type => 'password', :class => "long", :name => 'password') { actual_html }
    end

    should "display password field in erb" do
      visit '/erb/form_tag'
      assert_have_selector 'form.simple-form input[type=password]', :count => 1, :name => 'password'
      assert_have_selector 'form.advanced-form input[type=password]', :count => 1, :name => 'password'
    end

    should "display password field in haml" do
      visit '/haml/form_tag'
      assert_have_selector 'form.simple-form input[type=password]', :count => 1, :name => 'password'
      assert_have_selector 'form.advanced-form input[type=password]', :count => 1, :name => 'password'
    end
  end

  context 'for #file_field_tag method' do
    should "display file field in ruby" do
      actual_html = file_field_tag(:photo, :class => 'photo')
      assert_has_tag(:input, :type => 'file', :class => "photo", :name => 'photo') { actual_html }
    end

    should "display file field in erb" do
      visit '/erb/form_tag'
      assert_have_selector 'form.advanced-form input[type=file]', :count => 1, :name => 'photo', :class => 'upload'
    end

    should "display file field in haml" do
      visit '/haml/form_tag'
      assert_have_selector 'form.advanced-form input[type=file]', :count => 1, :name => 'photo', :class => 'upload'
    end
  end

  context "for #check_box_tag method" do
    should "display check_box tag in ruby" do
      actual_html = check_box_tag("clear_session")
      assert_has_tag(:input, :type => 'checkbox', :value => '1', :name => 'clear_session') { actual_html }
      assert_has_no_tag(:input, :type => 'hidden') { actual_html }
    end

    should "display check_box tag in ruby with extended attributes" do
      actual_html = check_box_tag("clear_session", :disabled => true, :checked => true)
      assert_has_tag(:input, :type => 'checkbox', :disabled => 'disabled', :checked => 'checked') { actual_html }
    end

    should "display check_box tag in erb" do
      visit '/erb/form_tag'
      assert_have_selector 'form.simple-form input[type=checkbox]', :count => 1
      assert_have_selector 'form.advanced-form input[type=checkbox]', :value => "1", :checked => 'checked'
    end

    should "display check_box tag in haml" do
      visit '/haml/form_tag'
      assert_have_selector 'form.simple-form input[type=checkbox]', :count => 1
      assert_have_selector 'form.advanced-form input[type=checkbox]', :value => "1", :checked => 'checked'
    end
  end

  context "for #radio_button_tag method" do
    should "display radio_button tag in ruby" do
      actual_html = radio_button_tag("gender", :value => 'male')
      assert_has_tag(:input, :type => 'radio', :value => 'male', :name => 'gender') { actual_html }
    end

    should "display radio_button tag in ruby with extended attributes" do
      actual_html = radio_button_tag("gender", :disabled => true, :checked => true)
      assert_has_tag(:input, :type => 'radio', :disabled => 'disabled', :checked => 'checked') { actual_html }
    end

    should "display radio_button tag in erb" do
      visit '/erb/form_tag'
      assert_have_selector 'form.simple-form input[type=radio]', :count => 1, :value => 'male'
      assert_have_selector 'form.simple-form input[type=radio]', :count => 1, :value => 'female'
      assert_have_selector 'form.advanced-form input[type=radio]', :value => "male", :checked => 'checked'
      assert_have_selector 'form.advanced-form input[type=radio]', :value => "female"
    end

    should "display radio_button tag in haml" do
      visit '/haml/form_tag'
      assert_have_selector 'form.simple-form input[type=radio]', :count => 1, :value => 'male'
      assert_have_selector 'form.simple-form input[type=radio]', :count => 1, :value => 'female'
      assert_have_selector 'form.advanced-form input[type=radio]', :value => "male", :checked => 'checked'
      assert_have_selector 'form.advanced-form input[type=radio]', :value => "female"
    end
  end

  context "for #select_tag method" do
    should "display select tag in ruby" do
      actual_html = select_tag(:favorite_color, :options => ['green', 'blue', 'black'], :include_blank => true)
      assert_has_tag(:select, :name => 'favorite_color') { actual_html }
      assert_has_tag('select option:first-child', :content => '') { actual_html }
      assert_has_tag('select option', :content => 'green', :value => 'green') { actual_html }
      assert_has_tag('select option', :content => 'blue', :value => 'blue') { actual_html }
      assert_has_tag('select option', :content => 'black', :value => 'black') { actual_html }
    end

    should "display select tag in ruby with extended attributes" do
      actual_html = select_tag(:favorite_color, :disabled => true, :options => ['only', 'option'])
      assert_has_tag(:select, :disabled => 'disabled') { actual_html }
    end

    should "display select tag in ruby with multiple attribute" do
      actual_html = select_tag(:favorite_color, :multiple => true, :options => ['only', 'option'])
      assert_has_tag(:select, :multiple => 'multiple', :name => 'favorite_color[]') { actual_html }
    end

    should "display options with values and selected" do
      options = [['Green', 'green1'], ['Blue', 'blue1'], ['Black', "black1"]]
      actual_html = select_tag(:favorite_color, :options => options, :selected => 'green1')
      assert_has_tag(:select, :name => 'favorite_color') { actual_html }
      assert_has_tag('select option', :selected => 'selected', :count => 1) { actual_html }
      assert_has_tag('select option', :content => 'Green', :value => 'green1', :selected => 'selected') { actual_html }
      assert_has_tag('select option', :content => 'Blue', :value => 'blue1') { actual_html }
      assert_has_tag('select option', :content => 'Black', :value => 'black1') { actual_html }
    end

    should "display select tag in erb" do
      visit '/erb/form_tag'
      assert_have_selector 'form.simple-form select', :count => 1, :name => 'color'
      assert_have_selector('select option', :content => 'green',  :value => 'green')
      assert_have_selector('select option', :content => 'orange', :value => 'orange')
      assert_have_selector('select option', :content => 'purple', :value => 'purple')
      assert_have_selector 'form.advanced-form select', :name => 'fav_color'
      assert_have_selector('select option', :content => 'green',  :value => '1')
      assert_have_selector('select option', :content => 'orange', :value => '2', :selected => 'selected')
      assert_have_selector('select option', :content => 'purple', :value => '3')
    end

    should "display select tag in haml" do
      visit '/haml/form_tag'
      assert_have_selector 'form.simple-form select', :count => 1, :name => 'color'
      assert_have_selector('select option', :content => 'green',  :value => 'green')
      assert_have_selector('select option', :content => 'orange', :value => 'orange')
      assert_have_selector('select option', :content => 'purple', :value => 'purple')
      assert_have_selector 'form.advanced-form select', :name => 'fav_color'
      assert_have_selector('select option', :content => 'green',  :value => '1')
      assert_have_selector('select option', :content => 'orange', :value => '2', :selected => 'selected')
      assert_have_selector('select option', :content => 'purple', :value => '3')
    end
  end

  context 'for #submit_tag method' do
    should "display submit tag in ruby" do
      actual_html = submit_tag("Update", :class => 'success')
      assert_has_tag(:input, :type => 'submit', :class => "success", :value => 'Update') { actual_html }
    end

    should "display submit tag in erb" do
      visit '/erb/form_tag'
      assert_have_selector 'form.simple-form input[type=submit]', :count => 1, :value => "Submit"
      assert_have_selector 'form.advanced-form input[type=submit]', :count => 1, :value => "Login"
    end

    should "display submit tag in haml" do
      visit '/haml/form_tag'
      assert_have_selector 'form.simple-form input[type=submit]', :count => 1, :value => "Submit"
      assert_have_selector 'form.advanced-form input[type=submit]', :count => 1, :value => "Login"
    end
  end

  context 'for #button_tag method' do
    should "display submit tag in ruby" do
      actual_html = button_tag("Cancel", :class => 'clear')
      assert_has_tag(:input, :type => 'button', :class => "clear", :value => 'Cancel') { actual_html }
    end

    should "display submit tag in erb" do
      visit '/erb/form_tag'
      assert_have_selector 'form.advanced-form input[type=button]', :count => 1, :value => "Cancel"
    end

    should "display submit tag in haml" do
      visit '/haml/form_tag'
      assert_have_selector 'form.advanced-form input[type=button]', :count => 1, :value => "Cancel"
    end
  end

  context 'for #image_submit_tag method' do
    setup do
      @stamp = stop_time_for_test.to_i
    end

    should "display image submit tag in ruby with relative path" do
      actual_html = image_submit_tag('buttons/ok.png', :class => 'success')
      assert_has_tag(:input, :type => 'image', :class => "success", :src => "/images/buttons/ok.png?#{@stamp}") { actual_html }
    end

    should "display image submit tag in ruby with absolute path" do
      actual_html = image_submit_tag('/system/ok.png', :class => 'success')
      assert_has_tag(:input, :type => 'image', :class => "success", :src => "/system/ok.png?#{@stamp}") { actual_html }
    end

    should "display image submit tag in erb" do
      visit '/erb/form_tag'
      assert_have_selector 'form.advanced-form input[type=image]', :count => 1, :src => "/images/buttons/submit.png?#{@stamp}"
    end

    should "display image submit tag in haml" do
      visit '/haml/form_tag'
      assert_have_selector 'form.advanced-form input[type=image]', :count => 1, :src => "/images/buttons/submit.png?#{@stamp}"
    end
  end

end
