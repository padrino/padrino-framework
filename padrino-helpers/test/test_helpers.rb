require_relative 'helper'
require 'padrino-core'

describe 'Padrino::Helpers' do
  it 'should allow including without registering' do
    class Foo
      include Padrino::Helpers
    end
    assert_equal '<div>bar</div>', Foo.new.content_tag(:div, 'bar')
  end

  it 'should not overwrite default_builder setting' do
    mock_app do
      set :default_builder, 'FancyBuilder'
      register Padrino::Helpers
    end
    assert_equal 'FancyBuilder', @app.default_builder
  end

  it 'should write a form token that a later POST is accepted with' do
    mock_app do
      enable :sessions
      disable :protection
      set :protect_from_csrf, except: ['/signup']
      get('/signup') { form_tag('/save') { '' } }
      post('/save') { 'saved' }
    end
    get '/signup'
    token = last_response.body[/name="authenticity_token" value="([^"]+)"/, 1]
    post '/save', authenticity_token: token
    assert_equal 200, last_response.status
    assert_equal 'saved', last_response.body
  end
end
