require File.expand_path('../helper.rb', __FILE__)
require File.expand_path('../fixtures/render_app/app.rb', __FILE__)

describe 'FlashHelpers' do

  should 'work without sessions' do
    @app = RenderDemo.tap { |a| a.disable :sessions }
    visit '/flash'
    assert_have_selector :h1, :content => 'Hello World'
  end

  should_eventually 'follow redirects' do
    @app = RenderDemo.tap { |a| a.enable :sessions }
    visit '/flash_redirect'
    assert_have_selector :h1, :content => 'Hello Redirect'
  end
end
