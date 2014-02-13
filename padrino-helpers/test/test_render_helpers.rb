require File.expand_path(File.dirname(__FILE__) + '/helper')
require File.expand_path(File.dirname(__FILE__) + '/fixtures/render_app/app')

describe "RenderHelpers" do
  def app
    RenderDemo
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

  context 'for #partial method taking a path starting with forward slash' do
    setup { visit '/partial/foward_slash' }
    should "render partial without throwing an error" do
      assert_have_selector "h1", :content => "User name is John"
    end
  end

  context 'render with block' do
    should 'render slim with block' do
      visit '/render_block_slim'
      assert_have_selector 'h1', :content => 'prefix'
      assert_have_selector 'h3', :content => 'postfix'
      assert_have_selector '.slim-block'
      assert_have_selector 'div', :content => 'go block!'
    end
    should 'render erb with block' do
      visit '/render_block_erb'
      assert_have_selector 'h1', :content => 'prefix'
      assert_have_selector 'h3', :content => 'postfix'
      assert_have_selector '.erb-block'
      assert_have_selector 'div', :content => 'go block!'
    end
    should 'render haml with block' do
      visit '/render_block_haml'
      assert_have_selector 'h1', :content => 'prefix'
      assert_have_selector 'h3', :content => 'postfix'
      assert_have_selector '.haml-block'
      assert_have_selector 'div', :content => 'go block!'
    end
  end

  context 'partial with block' do
    should 'show partial slim with block' do
      visit '/partial_block_slim'
      assert_have_selector 'h1', :content => 'prefix'
      assert_have_selector 'h3', :content => 'postfix'
      assert_have_selector '.slim-block'
      assert_have_selector 'div', :content => 'go block!'
      assert_have_selector 'div.deep', :content => 'Done'
    end
    should 'show partial erb with block' do
      visit '/partial_block_erb'
      assert_have_selector 'h1', :content => 'prefix'
      assert_have_selector 'h3', :content => 'postfix'
      assert_have_selector '.erb-block'
      assert_have_selector 'div', :content => 'go block!'
      assert_have_selector 'div.deep', :content => 'Done'
    end
    should 'show partial haml with block' do
      visit '/partial_block_haml'
      assert_have_selector 'h1', :content => 'prefix'
      assert_have_selector 'h3', :content => 'postfix'
      assert_have_selector '.haml-block'
      assert_have_selector 'div', :content => 'go block!'
      assert_have_selector 'div.deep', :content => 'Done'
    end
  end

  context 'for #current_engine method' do
    should 'detect correctly current engine for a padrino application' do
      visit '/current_engine'
      assert_have_selector 'p.start', :content => "haml"
      assert_have_selector 'p.haml span',  :content => "haml"
      assert_have_selector 'p.erb span',   :content => "erb"
      assert_have_selector 'p.slim span',  :content => "slim"
      assert_have_selector 'p.end',   :content => "haml"
    end

    should "detect correctly current engine for explicit engine on partials" do
      visit '/explicit_engine'
      assert_have_selector 'p.start', :content => "haml"
      assert_have_selector 'p.haml span',  :content => "haml"
      assert_have_selector 'p.erb span',   :content => "erb"
      assert_have_selector 'p.slim span',  :content => "slim"
      assert_have_selector 'p.end',   :content => "haml"
    end

    should "capture slim template once and only once" do
      $number_of_captures = 0
      visit '/double_capture_slim'
      assert_equal 1,$number_of_captures
    end

    should "capture haml template once and only once" do
      $number_of_captures = 0
      visit '/double_capture_haml'
      assert_equal 1,$number_of_captures
    end

    should "capture erb template once and only once" do
      $number_of_captures = 0
      visit '/double_capture_erb'
      assert_equal 1,$number_of_captures
    end

    should "fail on wrong erb usage" do
      assert_raises(SyntaxError) do
        visit '/wrong_capture_erb'
      end
    end

    should "ignore wrong haml usage" do
      visit '/wrong_capture_haml'
      assert_have_no_selector 'p', :content => 'this is wrong'
    end

    should "ignore wrong slim usage" do
      visit '/wrong_capture_slim'
      assert_have_no_selector 'p', :content => 'this is wrong'
    end

    should "support weird ruby blocks in erb" do
      visit '/ruby_block_capture_erb'
      assert_have_selector 'b', :content => 'c'
    end

    should "support weird ruby blocks in haml" do
      visit '/ruby_block_capture_haml'
      assert_have_selector 'b', :content => 'c'
    end
    
    should "support weird ruby blocks in slim" do
      visit '/ruby_block_capture_slim'
      assert_have_selector 'b', :content => 'c'
    end
  end
end
