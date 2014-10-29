require File.expand_path(File.dirname(__FILE__) + '/helper')
require File.expand_path(File.dirname(__FILE__) + '/fixtures/render_app/app')

describe "RenderHelpers" do
  def app
    RenderDemo
  end

  describe 'for #partial method and object' do
    before { visit '/partial/object' }
    it 'should render partial html with object' do
      assert_have_selector "h1", :content => "User name is John"
    end
    it 'should have no counter index for single item' do
      assert_have_no_selector "p", :content => "My counter is 1", :count => 1
    end
    it 'should include extra locals information' do
      assert_have_selector 'p', :content => "Extra is bar"
    end
  end

  describe 'for #partial method and collection' do
    before { visit '/partial/collection' }
    it 'should render partial html with collection' do
      assert_have_selector "h1", :content => "User name is John"
      assert_have_selector "h1", :content => "User name is Billy"
    end
    it 'should include counter which contains item index' do
      assert_have_selector "p", :content => "My counter is 1"
      assert_have_selector "p", :content => "My counter is 2"
    end
    it 'should include extra locals information' do
      assert_have_selector 'p', :content => "Extra is bar"
    end
  end

  describe 'for #partial with ext and collection' do
    before { visit '/partial/collection.ext' }
    it 'should not fail horribly with `invalid locals key` RuntimeError' do
      assert_have_selector "h1", :content => "User name is John"
    end
  end

  describe 'for #partial method and locals' do
    before { visit '/partial/locals' }
    it 'should render partial html with locals' do
      assert_have_selector "h1", :content => "User name is John"
    end
    it 'should have no counter index for single item' do
      assert_have_no_selector "p", :content => "My counter is 1", :count => 1
    end
    it 'should include extra locals information' do
      assert_have_selector 'p', :content => "Extra is bar"
    end
  end

  describe 'for #partial method taking a path starting with forward slash' do
    before { visit '/partial/foward_slash' }
    it 'should render partial without throwing an error' do
      assert_have_selector "h1", :content => "User name is John"
    end
  end

  describe 'for #partial method with unsafe engine' do
    it 'should render partial without escaping it' do
      visit '/partial/unsafe'
      assert_have_selector "h1", :content => "User name is John"
    end
    it 'should render partial object without escaping it' do
      visit '/partial/unsafe_one'
      assert_have_selector "h1", :content => "User name is Mary"
    end
    it 'should render partial collection without escaping it' do
      visit '/partial/unsafe_many'
      assert_have_selector "h1", :content => "User name is John"
      assert_have_selector "h1", :content => "User name is Mary"
    end
    it 'should render unsafe partial without escaping it' do
      visit '/partial/unsafe?block=%3Cevil%3E'
      assert_have_selector "h1", :content => "User name is John"
      assert_have_selector "evil"
    end
    it 'should render unsafe partial object without escaping it' do
      visit '/partial/unsafe_one?block=%3Cevil%3E'
      assert_have_selector "h1", :content => "User name is Mary"
      assert_have_selector "evil"
    end
    it 'should render unsafe partial collection without escaping it' do
      visit '/partial/unsafe_many?block=%3Cevil%3E'
      assert_have_selector "h1", :content => "User name is John"
      assert_have_selector "h1", :content => "User name is Mary"
      assert_have_selector "evil"
    end
  end

  describe 'render with block' do
    it 'should render slim with block' do
      visit '/render_block_slim'
      assert_have_selector 'h1', :content => 'prefix'
      assert_have_selector 'h3', :content => 'postfix'
      assert_have_selector '.slim-block'
      assert_have_selector 'div', :content => 'go block!'
    end
    it 'should render erb with block' do
      visit '/render_block_erb'
      assert_have_selector 'h1', :content => 'prefix'
      assert_have_selector 'h3', :content => 'postfix'
      assert_have_selector '.erb-block'
      assert_have_selector 'div', :content => 'go block!'
    end
    it 'should render haml with block' do
      visit '/render_block_haml'
      assert_have_selector 'h1', :content => 'prefix'
      assert_have_selector 'h3', :content => 'postfix'
      assert_have_selector '.haml-block'
      assert_have_selector 'div', :content => 'go block!'
    end
  end

  describe 'partial with block' do
    it 'should show partial slim with block' do
      visit '/partial_block_slim'
      assert_have_selector 'h1', :content => 'prefix'
      assert_have_selector 'h3', :content => 'postfix'
      assert_have_selector '.slim-block'
      assert_have_selector 'div', :content => 'go block!'
      assert_have_selector 'div.deep', :content => 'Done'
    end
    it 'should show partial erb with block' do
      visit '/partial_block_erb'
      assert_have_selector 'h1', :content => 'prefix'
      assert_have_selector 'h3', :content => 'postfix'
      assert_have_selector '.erb-block'
      assert_have_selector 'div', :content => 'go block!'
      assert_have_selector 'div.deep', :content => 'Done'
    end
    it 'should show partial haml with block' do
      visit '/partial_block_haml'
      assert_have_selector 'h1', :content => 'prefix'
      assert_have_selector 'h3', :content => 'postfix'
      assert_have_selector '.haml-block'
      assert_have_selector 'div', :content => 'go block!'
      assert_have_selector 'div.deep', :content => 'Done'
    end
  end

  describe 'for #current_engine method' do
    it 'should detect correctly current engine for a padrino application' do
      visit '/current_engine'
      assert_have_selector 'p.start', :content => "haml"
      assert_have_selector 'p.haml span',  :content => "haml"
      assert_have_selector 'p.erb span',   :content => "erb"
      assert_have_selector 'p.slim span',  :content => "slim"
      assert_have_selector 'p.end',   :content => "haml"
    end

    it 'should detect correctly current engine for explicit engine on partials' do
      visit '/explicit_engine'
      assert_have_selector 'p.start', :content => "haml"
      assert_have_selector 'p.haml span',  :content => "haml"
      assert_have_selector 'p.erb span',   :content => "erb"
      assert_have_selector 'p.slim span',  :content => "slim"
      assert_have_selector 'p.end',   :content => "haml"
    end

    it 'should capture slim template once and only once' do
      $number_of_captures = 0
      visit '/double_capture_slim'
      assert_equal 1,$number_of_captures
    end

    it 'should capture haml template once and only once' do
      $number_of_captures = 0
      visit '/double_capture_haml'
      assert_equal 1,$number_of_captures
    end

    it 'should capture erb template once and only once' do
      $number_of_captures = 0
      visit '/double_capture_erb'
      assert_equal 1,$number_of_captures
    end

    it 'should fail on wrong erb usage' do
      assert_raises(SyntaxError) do
        visit '/wrong_capture_erb'
      end
    end

    it 'should ignore wrong haml usage' do
      visit '/wrong_capture_haml'
      assert_have_no_selector 'p', :content => 'this is wrong'
    end

    it 'should ignore wrong slim usage' do
      visit '/wrong_capture_slim'
      assert_have_no_selector 'p', :content => 'this is wrong'
    end

    it 'should support weird ruby blocks in erb' do
      visit '/ruby_block_capture_erb'
      assert_have_selector 'b', :content => 'c'
    end

    it 'should support weird ruby blocks in haml' do
      visit '/ruby_block_capture_haml'
      assert_have_selector 'b', :content => 'c'
    end
    
    it 'should support weird ruby blocks in slim' do
      visit '/ruby_block_capture_slim'
      assert_have_selector 'b', :content => 'c'
    end
  end

  describe 'rendering with helpers that use render' do
    %W{erb haml slim}.each do |engine|
      it "should work with #{engine}" do
        skip
        visit "/double_dive_#{engine}"
        assert_have_selector '.outer .wrapper form .inner .core'
      end
    end
  end
end
