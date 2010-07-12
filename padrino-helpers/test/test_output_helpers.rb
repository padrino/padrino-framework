require File.expand_path(File.dirname(__FILE__) + '/helper')
require File.expand_path(File.dirname(__FILE__) + '/fixtures/markup_app/app')

class TestOutputHelpers < Test::Unit::TestCase
  def app
    MarkupDemo.tap { |app| app.set :environment, :test }
  end

  context 'for #content_for method' do
    should 'work for erb templates' do
      visit '/erb/content_for'
      assert_have_selector '.demo h1', :content => "This is content yielded from a content_for"
      assert_have_selector '.demo2 h1', :content => "This is content yielded with name Johnny Smith"
    end

    should "work for haml templates" do
      visit '/haml/content_for'
      assert_have_selector '.demo h1', :content => "This is content yielded from a content_for"
      assert_have_selector '.demo2 h1', :content => "This is content yielded with name Johnny Smith"
    end
  end

  context 'for #capture_html method' do
    should "work for erb templates" do
      visit '/erb/capture_concat'
      assert_have_selector 'p span', :content => "Captured Line 1"
      assert_have_selector 'p span', :content => "Captured Line 2"
    end

    should "work for haml templates" do
      visit '/haml/capture_concat'
      assert_have_selector 'p span', :content => "Captured Line 1"
      assert_have_selector 'p span', :content => "Captured Line 2"
    end
  end

  context 'for #concat_content method' do
    should "work for erb templates" do
      visit '/erb/capture_concat'
      assert_have_selector 'p', :content => "Concat Line 3", :count => 1
    end

    should "work for haml templates" do
      visit '/haml/capture_concat'
      assert_have_selector 'p', :content => "Concat Line 3", :count => 1
    end
  end

  context 'for #block_is_template?' do
    should "work for erb templates" do
      visit '/erb/capture_concat'
      assert_have_selector 'p', :content => "The erb block passed in is a template", :class => 'is_template'
      # TODO Get ERB template detection working (fix block_is_erb? method)
      # assert_have_no_selector 'p', :content => "The ruby block passed in is a template", :class => 'is_template'
    end

    should "work for haml templates" do
      visit '/haml/capture_concat'
      assert_have_selector 'p', :content => "The haml block passed in is a template", :class => 'is_template'
      assert_have_no_selector 'p', :content => "The ruby block passed in is a template", :class => 'is_template'
    end
  end
end