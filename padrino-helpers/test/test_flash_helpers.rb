require File.expand_path('../helper.rb', __FILE__)
require File.expand_path('../fixtures/render_app/app.rb', __FILE__)

describe 'FlashHelpers' do

  should 'work without sessions' do
    @app = RenderDemo
    visit '/flash'
    assert_have_selector :h1, :content => 'Hello World'
  end

  should 'follow redirects' do
    @app = RenderDemo
    visit '/flash_redirect'
    follow_redirect!
    assert_have_selector :h1, :content => 'Hello Redirect'
  end
end
