require File.dirname(__FILE__) + '/helper'
require File.dirname(__FILE__) + '/fixtures/render_app/app'

class TestRenderHelpers < Test::Unit::TestCase
  def app
    RenderDemo.tap { |app| app.set :environment, :test }
  end

  context 'for #haml_template method' do
    setup { visit '/render_haml' }
    should('render template properly') do
      assert_have_selector "h1", :content => "This is a haml template!"
    end
  end

  context 'for #erb_template method' do
    setup { visit '/render_erb' }
    should('render template properly') do
      assert_have_selector "h1", :content => "This is a erb template!"
    end
  end
  
  context 'for #render_template method with explicit engine' do
    setup { visit '/render_template/haml' }
    should('render template properly') do
      assert_have_selector "h1", :content => "This is a haml template sent from render_template!"
    end
  end
  
  context 'for #render_template method without explicit engine' do
    setup { visit '/render_template' }
    should('render template properly') do
      assert_have_selector "h1", :content => "This is a haml template which was detected!"
    end
  end
  
  context 'for #partial method and object' do
    setup { visit '/partial/object' }
    should "render partial html with object" do
      assert_have_selector "h1", :content => "User name is John"
    end
    should "have no counter index for single item" do
      assert_have_no_selector "p", :content => "My counter is 1", :count => 1
    end
    should "include extra locals information" do
      assert_have_selector 'p', :content => "Extra is bar"
    end
  end
  
  context 'for #partial method and collection' do
    setup { visit '/partial/collection' }
    should "render partial html with collection" do
      assert_have_selector "h1", :content => "User name is John"
      assert_have_selector "h1", :content => "User name is Billy"
    end
    should "include counter which contains item index" do
      assert_have_selector "p", :content => "My counter is 1"
      assert_have_selector "p", :content => "My counter is 2"
    end
    should "include extra locals information" do
      assert_have_selector 'p', :content => "Extra is bar"
    end
  end
  
  context 'for #partial method and locals' do
    setup { visit '/partial/locals' }
    should "render partial html with locals" do
      assert_have_selector "h1", :content => "User name is John"
    end
    should "have no counter index for single item" do
      assert_have_no_selector "p", :content => "My counter is 1", :count => 1
    end
    should "include extra locals information" do
      assert_have_selector 'p', :content => "Extra is bar"
    end
  end

end
