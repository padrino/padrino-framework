require File.dirname(__FILE__) + '/helper'

class TestReloader < Test::Unit::TestCase

  context 'for reloader functionality' do

    should 'reset routes' do
      mock_app do
        1.step(10).each do |i|
          get("/#{i}") { "Foo #{i}" }
        end
      end
      1.step(10).each do |i|
        get "/#{i}"
        assert_equal "Foo #{i}", body
      end
      @app.reset_routes!
      1.step(10).each do |i|
        get "/#{i}"
        assert_equal 404, status
      end
    end
  end
end