require File.dirname(__FILE__) + '/helper'
require 'fixtures/apps/simple'

class TestSimpleReloader < Test::Unit::TestCase

  context 'for simple reset functionality' do

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

    should 'keep sinatra routes' do
      mock_app do
        get("/"){ "ok" }
      end
      get "/"
      assert_equal 200, status
      get "/__sinatra__/404.png"
      assert_equal 200, status
      assert_equal "image/png", response["Content-Type"]
      @app.reset_routes!
      get "/"
      assert_equal 404, status
      get "/__sinatra__/404.png"
      assert_equal 200, status
      assert_equal "image/png", response["Content-Type"]
    end
  end
  
  context 'for simple reload functionality' do
  
    should 'correctly instantiate SimpleDemo fixture' do
      Padrino.mounted_apps.clear
      Padrino.mount_core("simple_demo")
      assert_equal ["core"], Padrino.mounted_apps.collect(&:name)
      assert SimpleDemo.reload?
      assert_match %r{fixtures/apps/simple.rb}, SimpleDemo.app_file
    end
  
    should 'correctly reload SimpleDemo fixture' do
      @app = SimpleDemo
      get "/"
      assert_equal 200, status
      new_phrase = "The magick number is: #{rand(100)}!"
      buffer     = File.read(SimpleDemo.app_file)
      new_buffer = buffer.gsub(/The magick number is: \d+!/, new_phrase)
      File.open(SimpleDemo.app_file, "w") { |f| f.write(new_buffer) }
      sleep 1.2 # We need at least a cooldown of 1 sec.
      get "/"
      assert_equal new_phrase, body
  
      # Now we need to prevent to commit a new changed file so we revert it
      File.open(SimpleDemo.app_file, "w") { |f| f.write(buffer) }
    end
  end
end