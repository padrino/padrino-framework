require File.dirname(__FILE__) + '/helper'
require File.dirname(__FILE__) + '/fixtures/markup_app/app'

class TestAssetTagHelpers < Test::Unit::TestCase
  include Padrino::Helpers::AssetTagHelpers

  def app
    MarkupDemo.tap { |app| app.set :environment, :test }
  end

  def flash
    { :notice => "Demo notice" }
  end

  context 'for #flash_tag method' do
    should "display flash with no given attributes" do
      assert_has_tag('div.flash', :content => "Demo notice") { flash_tag(:notice) }
    end
    should "display flash with given attributes" do
      actual_html = flash_tag(:notice, :class => 'notice', :id => 'notice-area')
      assert_has_tag('div.notice#notice-area', :content => "Demo notice") { actual_html }
    end
  end

  context 'for #link_to method' do
    should "display link element with no given attributes" do
      assert_has_tag('a', :content => "Sign up", :href => '/register') { link_to('Sign up', '/register') }
    end
    should "display link element with given attributes" do
      actual_html = link_to('Sign up', '/register', :class => 'first', :id => 'linky')
      assert_has_tag('a#linky.first', :content => "Sign up", :href => '/register') { actual_html }
    end
    should "display link element with ruby block" do
      actual_link = link_to('/register', :class => 'first', :id => 'binky') { "Sign up" }
      assert_has_tag('a#binky.first', :content => "Sign up", :href => '/register') { actual_link }
    end
    should "display link block element in haml" do
      visit '/haml/link_to'
      assert_have_selector :a, :content => "Test 1 No Block", :href => '/test1', :class => 'test', :id => 'test1'
      assert_have_selector :a, :content => "Test 2 With Block", :href => '/test2', :class => 'test', :id => 'test2'
    end
    should "display link block element in erb" do
      visit '/erb/link_to'
      assert_have_selector :a, :content => "Test 1 No Block", :href => '/test1', :class => 'test', :id => 'test1'
      assert_have_selector :a, :content => "Test 2 With Block", :href => '/test2', :class => 'test', :id => 'test2'
    end
  end

  context 'for #mail_to method' do
    should "display link element for mail to no caption" do
      actual_html = mail_to('test@demo.com')
      assert_has_tag(:a, :href => "mailto:test@demo.com", :content => 'test@demo.com') { actual_html }
    end

    should "display link element for mail to with caption" do
      actual_html = mail_to('test@demo.com', "My Email", :class => 'demo')
      assert_has_tag(:a, :href => "mailto:test@demo.com", :content => 'My Email', :class => 'demo') { actual_html }
    end

    should "display link element for mail to with caption and mail options" do
      actual_html = mail_to('test@demo.com', "My Email", :subject => 'demo test', :class => 'demo', :cc => 'foo@test.com')
      assert_has_tag(:a, :class => 'demo') { actual_html }
      assert_match /mailto\:test\@demo.com\?/, actual_html
      assert_match /cc=foo\@test\.com/, actual_html
      assert_match /subject\=demo\%20test/, actual_html
    end

    should "display mail link element in haml" do
      visit '/haml/mail_to'
      assert_have_selector 'p.simple a', :href => 'mailto:test@demo.com', :content => 'test@demo.com'
      assert_have_selector 'p.captioned a', :href => 'mailto:test@demo.com', :content => 'Click my Email'
    end

    should "display mail link element in erb" do
      visit '/erb/mail_to'
      assert_have_selector 'p.simple a', :href => 'mailto:test@demo.com', :content => 'test@demo.com'
      assert_have_selector 'p.captioned a', :href => 'mailto:test@demo.com', :content => 'Click my Email'
    end
  end

  context 'for #image_tag method' do
    should "display image tag absolute link with no options" do
      assert_has_tag('img', :src => "/absolute/pic.gif") { image_tag('/absolute/pic.gif') }
    end
    should "display image tag absolute link with specified uri root" do
      self.class.stubs(:uri_root).returns("/blog")
      assert_has_tag('img', :src => "/blog/images/relative/pic.gif") { image_tag('relative/pic.gif') }
    end
    should "display image tag relative link with options" do
      assert_has_tag('img.photo', :src => "/images/relative/pic.gif") { image_tag('relative/pic.gif', :class => 'photo') }
    end
    should "display image tag uri link with options" do
      assert_has_tag('img.photo', :src => "http://demo.org/pic.gif") { image_tag('http://demo.org/pic.gif', :class => 'photo') }
    end
    should "display image tag relative link with incorrect spacing" do
      assert_has_tag('img.photo', :src => "/images/relative/pic.gif") { image_tag(' relative/ pic.gif  ', :class => 'photo') }
    end
  end

  context 'for #stylesheet_link_tag method' do
    should "display stylesheet link item" do
      time = stop_time_for_test
      expected_options = { :media => "screen", :rel => "stylesheet", :type => "text/css" }
      assert_has_tag('link', expected_options.merge(:href => "/stylesheets/style.css?#{time.to_i}")) { stylesheet_link_tag('style') }
    end
    should "display stylesheet link item with absolute path" do
      time = stop_time_for_test
      expected_options = { :media => "screen", :rel => "stylesheet", :type => "text/css" }
      actual_html = stylesheet_link_tag('/css/style')
      assert_has_tag('link', expected_options.merge(:href => "/css/style.css?#{time.to_i}")) { actual_html }
    end
    should "display stylesheet link item with uri root" do
      self.class.stubs(:uri_root).returns("/blog")
      time = stop_time_for_test
      expected_options = { :media => "screen", :rel => "stylesheet", :type => "text/css" }
      actual_html = stylesheet_link_tag('style')
      assert_has_tag('link', expected_options.merge(:href => "/blog/stylesheets/style.css?#{time.to_i}")) { actual_html }
    end
    should "display stylesheet link items" do
      time = stop_time_for_test
      actual_html = stylesheet_link_tag('style', 'layout.css', 'http://google.com/style.css')
      assert_has_tag('link', :media => "screen", :rel => "stylesheet", :type => "text/css", :count => 3) { actual_html }
      assert_has_tag('link', :href => "/stylesheets/style.css?#{time.to_i}") { actual_html }
      assert_has_tag('link', :href => "/stylesheets/layout.css?#{time.to_i}") { actual_html }
      assert_has_tag('link', :href => "http://google.com/style.css") { actual_html }
    end
  end

  context 'for #javascript_include_tag method' do
    should "display javascript item" do
      time = stop_time_for_test
      actual_html = javascript_include_tag('application')
      assert_has_tag('script', :src => "/javascripts/application.js?#{time.to_i}", :type => "text/javascript") { actual_html }
    end
    should "display javascript item with absolute path" do
      time = stop_time_for_test
      actual_html = javascript_include_tag('/js/application')
      assert_has_tag('script', :src => "/js/application.js?#{time.to_i}", :type => "text/javascript") { actual_html }
    end
    should "display javascript item with uri root" do
      self.class.stubs(:uri_root).returns("/blog")
      time = stop_time_for_test
      actual_html = javascript_include_tag('application')
      assert_has_tag('script', :src => "/blog/javascripts/application.js?#{time.to_i}", :type => "text/javascript") { actual_html }
    end
    should "display javascript items" do
      time = stop_time_for_test
      actual_html = javascript_include_tag('application', 'base.js', 'http://google.com/lib.js')
      assert_has_tag('script', :type => "text/javascript", :count => 3) { actual_html }
      assert_has_tag('script', :src => "/javascripts/application.js?#{time.to_i}") { actual_html }
      assert_has_tag('script', :src => "/javascripts/base.js?#{time.to_i}") { actual_html }
      assert_has_tag('script', :src => "http://google.com/lib.js") { actual_html }
    end
  end
end
