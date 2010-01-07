require 'helper'

class JamlTest < Test::Unit::TestCase

  should 'render correctly a template' do
    @foo     = "bar"
    template = Padrino::JamlTemplate.new(File.dirname(__FILE__) + "/fixtures/test.jml")
    config   = template.render(self)

    assert_match "\"test_two\":function(){ alert('nested fn') }", config
    assert_match "\"nested\":{\"fn\":function(){ alert('nested fn') }}", config
    assert_match "\"test_one\":function(){ alert('fn') }", config
    assert_match "\"array\":[function(){ alert('array') },\"perfect\"]", config
    assert_match "\"test_three\":\"bar\"", config
    assert_match "\"fn\":function(){ alert('fn') }}", config
  end

  should 'render correctly a template from app' do
    mock_app do
      set :views, File.dirname(__FILE__)
      
      get "/" do
        @foo = "bar"
        render 'fixtures/test'
      end
    end
    
    get "/"
    assert_match "\"test_two\":function(){ alert('nested fn') }", body
    assert_match "\"nested\":{\"fn\":function(){ alert('nested fn') }}", body
    assert_match "\"test_one\":function(){ alert('fn') }", body
    assert_match "\"array\":[function(){ alert('array') },\"perfect\"]", body
    assert_match "\"test_three\":\"bar\"", body
    assert_match "\"fn\":function(){ alert('fn') }}", body
  end

end