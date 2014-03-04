require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "BreadcrumbHelpers" do
  include Padrino::Helpers::Breadcrumbs

  def breadcrumb
    @breadcrumb ||= Padrino::Helpers::Breadcrumb.new
  end

  before(:each) { breadcrumb.reset! }

  describe "for Breadcrumbs#breadcrumbs method" do
    it 'should support breadcrumbs which is Padrino::Helpers::Breadcrumbs instance.' do
      breadcrumb.add "foo", "/foo", "foo link"
      assert_has_tag(:a, :content => "Foo link", :href => "/foo") { breadcrumbs(breadcrumb) }
    end

    it 'should support bootstrap' do
      breadcrumb.add "foo", "/foo", "foo link"
      assert_has_tag(:span, :content => "/", :class => "divider") { breadcrumbs(breadcrumb, true) }
    end

    it 'should support active' do
      breadcrumb.add "foo", "/foo", "foo link"
      assert_has_tag(:li, :class => "custom-active") { breadcrumbs(breadcrumb, nil, "custom-active") }
    end

    it 'should support options' do
      assert_has_tag(:ul, :class => "breadcrumbs-class breadcrumb", :id => "breadcrumbs-id") do
        breadcrumbs(breadcrumb, nil, nil, :id => "breadcrumbs-id", :class => "breadcrumbs-class")
      end
    end
  end

  describe "for #add method" do
    it 'should support name of string and symbol type' do
      breadcrumb.add "foo", "/foo", "Foo Link"
      breadcrumb.add :bar, "/bar", "Bar Link"

      actual_html = breadcrumbs(breadcrumb)
      assert_has_tag(:a, :content => "Foo link", :href => "/foo") { actual_html }
      assert_has_tag(:a, :content => "Bar link", :href => "/bar") { actual_html }
    end

    it 'should support url' do
      breadcrumb.add :foo, "/foo", "Foo Link"
      assert_has_tag(:a, :href => "/foo") { breadcrumbs(breadcrumb) }
    end

    it 'should support caption' do
      breadcrumb.add :foo, "/foo", "Foo Link"
      assert_has_tag(:a, :content => "Foo link") { breadcrumbs(breadcrumb) }
    end

    it 'should support options' do
      breadcrumb.add :foo, "/foo", "Foo Link", :id => "foo-id", :class => "foo-class"
      breadcrumb.add :bar, "/bar", "Bar Link", :id => "bar-id", :class => "bar-class"

      actual_html = breadcrumbs(breadcrumb)
      assert_has_tag(:li, :class => "foo-class", :id => "foo-id") { actual_html }
      assert_has_tag(:li, :class => "bar-class active", :id => "bar-id") { actual_html }
    end
  end

  describe "for #del method" do
    it 'should support name of string type' do
      breadcrumb.add "foo", "/foo", "Foo Link"
      breadcrumb.add :bar, "/bar", "Bar Link"

      breadcrumb.del "foo"
      breadcrumb.del "bar"

      actual_html = breadcrumbs(breadcrumb)
      assert_has_no_tag(:a, :content => "Foo link", :href => "/foo") { actual_html }
      assert_has_no_tag(:a, :content => "Bar link", :href => "/bar") { actual_html }
    end

    it 'should support name of symbol type' do
      breadcrumb.add "foo", "/foo", "Foo Link"
      breadcrumb.add :bar, "/bar", "Bar Link"

      breadcrumb.del :foo
      breadcrumb.del :bar

      actual_html = breadcrumbs(breadcrumb)
      assert_has_no_tag(:a, :content => "Foo link", :href => "/foo") { actual_html }
      assert_has_no_tag(:a, :content => "Bar link", :href => "/bar") { actual_html }
    end
  end

  describe "for #set_home method" do
    it 'should modified home item elements.' do
      breadcrumb.set_home("/custom", "Custom Home Page")
      assert_has_tag(:a, :content => "Custom home page", :href => "/custom") { breadcrumbs(breadcrumb) }
    end

    it 'should support options' do
      breadcrumb.set_home("/custom", "Custom Home Page", :id => "home-id")

      actual_html = breadcrumbs(breadcrumb)
      assert_has_tag(:li, :id => "home-id") { actual_html }
      assert_has_tag(:a, :content => "Custom home page", :href => "/custom") { actual_html }
    end
  end

  describe "for #reset method" do
    it 'should be #items which contains only home item.' do
      breadcrumb.set_home("/custom", "Custom Home Page")
      breadcrumb.add "foo", "/foo", "Foo Link"
      breadcrumb.add :bar, "/bar", "Bar Link"

      breadcrumb.reset

      actual_html = breadcrumbs(breadcrumb)
      assert_has_tag(:a, :content => "Custom home page", :href => "/custom") { actual_html }
      assert_has_no_tag(:a, :content => "Foo link", :href => "/foo") { actual_html }
      assert_has_no_tag(:a, :content => "Bar link", :href => "/bar") { actual_html }
    end
  end

  describe "for #reset! method" do
    it 'should be #items which contains only default home item.' do
      breadcrumb.add "foo", "/foo", "foo link"
      breadcrumb.add :bar, "/bar", "Bar Link"

      breadcrumb.reset!

      actual_html = breadcrumbs(breadcrumb)
      assert_has_tag(:a, :content => "Home Page", :href => "/") { actual_html }
      assert_has_no_tag(:a, :content => "Foo link", :href => "/foo") { actual_html }
      assert_has_no_tag(:a, :content => "Bar link", :href => "/bar") { actual_html }
    end
  end
end
