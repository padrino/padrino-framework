require File.expand_path(File.dirname(__FILE__) + '/helper')
require File.expand_path(File.dirname(__FILE__) + '/fixtures/markup_app/app')

describe "OutputHelpers" do
  def app
    MarkupDemo
  end

  describe 'for #content_for method' do
    it 'should work for erb templates' do
      visit '/erb/content_for'
      assert_have_selector '.demo h1', :content => "This is content yielded from a content_for", :count => 1
      assert_have_selector '.demo2 h1', :content => "This is content yielded with name Johnny Smith", :count => 1
      assert_have_no_selector '.demo3 p', :content => "One", :class => "duplication"
      assert_have_selector '.demo3 p', :content => "Two", :class => "duplication"
    end

    it 'should work for haml templates' do
      visit '/haml/content_for'
      assert_have_selector '.demo h1', :content => "This is content yielded from a content_for", :count => 1
      assert_have_selector '.demo2 h1', :content => "This is content yielded with name Johnny Smith", :count => 1
      assert_have_no_selector '.demo3 p', :content => "One", :class => "duplication"
      assert_have_selector '.demo3 p', :content => "Two", :class => "duplication"
    end

    it 'should work for slim templates' do
      visit '/slim/content_for'
      assert_have_selector '.demo h1', :content => "This is content yielded from a content_for", :count => 1
      assert_have_selector '.demo2 h1', :content => "This is content yielded with name Johnny Smith", :count => 1
      assert_have_no_selector '.demo3 p', :content => "One", :class => "duplication"
      assert_have_selector '.demo3 p', :content => "Two", :class => "duplication"
    end
  end # content_for

  describe "for #content_for? method" do
    it 'should work for erb templates' do
      visit '/erb/content_for'
      assert_have_selector '.demo_has_content', :content => "true"
      assert_have_selector '.fake_has_content', :content => "false"
    end

    it 'should work for haml templates' do
      visit '/haml/content_for'
      assert_have_selector '.demo_has_content', :content => "true"
      assert_have_selector '.fake_has_content', :content => "false"
    end

    it 'should work for slim templates' do
      visit '/slim/content_for'
      assert_have_selector '.demo_has_content', :content => "true"
      assert_have_selector '.fake_has_content', :content => "false"
    end
  end # content_for?

  describe 'for #capture_html method' do
    it 'should work for erb templates' do
      visit '/erb/capture_concat'
      assert_have_selector 'p span', :content => "Captured Line 1", :count => 1
      assert_have_selector 'p span', :content => "Captured Line 2", :count => 1
    end

    it 'should work for haml templates' do
      visit '/haml/capture_concat'
      assert_have_selector 'p span', :content => "Captured Line 1", :count => 1
      assert_have_selector 'p span', :content => "Captured Line 2", :count => 1
    end

    it 'should work for slim templates' do
      visit '/slim/capture_concat'
      assert_have_selector 'p span', :content => "Captured Line 1", :count => 1
      assert_have_selector 'p span', :content => "Captured Line 2", :count => 1
    end
  end

  describe 'for #concat_content method' do
    it 'should work for erb templates' do
      visit '/erb/capture_concat'
      assert_have_selector 'p', :content => "Concat Line 3", :count => 1
    end

    it 'should work for haml templates' do
      visit '/haml/capture_concat'
      assert_have_selector 'p', :content => "Concat Line 3", :count => 1
    end

    it 'should work for slim templates' do
      visit '/slim/capture_concat'
      assert_have_selector 'p', :content => "Concat Line 3", :count => 1
    end
  end

  describe 'for #block_is_template?' do
    it 'should work for erb templates' do
      visit '/erb/capture_concat'
      assert_have_selector 'p', :content => "The erb block passed in is a template", :class => 'is_template', :count => 1
      assert_have_no_selector 'p', :content => "The ruby block passed in is a template", :class => 'is_template', :count => 1
    end

    it 'should work for haml templates' do
      visit '/haml/capture_concat'
      assert_have_selector 'p', :content => "The haml block passed in is a template", :class => 'is_template', :count => 1
      assert_have_no_selector 'p', :content => "The ruby block passed in is a template", :class => 'is_template', :count => 1
    end

    it 'should work for slim templates' do
      visit '/slim/capture_concat'
      assert_have_selector 'p', :content => "The slim block passed in is a template", :class => 'is_template', :count => 1
      assert_have_no_selector 'p', :content => "The ruby block passed in is a template", :class => 'is_template', :count => 1
    end
  end

  describe 'for #current_engine method' do
    it 'should detect correctly current engine for erb' do
      visit '/erb/current_engine'
      assert_have_selector 'p.start', :content => "erb"
      assert_have_selector 'p.haml',  :content => "haml"
      assert_have_selector 'p.erb',   :content => "erb"
      assert_have_selector 'p.slim',  :content => "slim"
      assert_have_selector 'p.end',   :content => "erb"
    end

    it 'should detect correctly current engine for haml' do
      visit '/haml/current_engine'
      assert_have_selector 'p.start', :content => "haml"
      assert_have_selector 'p.haml',  :content => "haml"
      assert_have_selector 'p.erb',   :content => "erb"
      assert_have_selector 'p.slim',  :content => "slim"
      assert_have_selector 'p.end',   :content => "haml"
    end

    it 'should detect correctly current engine for slim' do
      visit '/slim/current_engine'
      assert_have_selector 'p.start', :content => "slim"
      assert_have_selector 'p.haml',  :content => "haml"
      assert_have_selector 'p.erb',   :content => "erb"
      assert_have_selector 'p.slim',  :content => "slim"
      assert_have_selector 'p.end',   :content => "slim"
    end
  end

  describe 'for #partial method in simple sinatra application' do
    it 'should properly output in erb' do
      visit '/erb/simple_partial'
      assert_have_selector 'p.erb',  :content => "erb"
    end

    it 'should properly output in haml' do
      visit '/haml/simple_partial'
      assert_have_selector 'p.haml',  :content => "haml"
    end

    it 'should properly output in slim' do
      visit '/slim/simple_partial'
      assert_have_selector 'p.slim',  :content => "slim"
    end
  end
end
