require File.dirname(__FILE__) + '/helper'
require 'fixtures/apps/app'

class TestReloader < Test::Unit::TestCase

  context 'for reset functionality' do

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
  
  context 'for reload functionality' do
    
    should 'correctly instantiate single_app fixture' do
      Padrino.mounted_apps.clear
      Padrino.mount_core("single_demo")
      assert_equal ["core"], Padrino.mounted_apps.collect(&:name)
      assert SingleDemo.reload?
      assert_match %r{fixtures/apps/app.rb}, SingleDemo.app_file
    end
    
    should 'correctly reload single_app fixture' do
      @app = SingleDemo
      get "/"
      assert_equal 200, status
      new_phrase =  "The magick number is: #{rand(100)}!"
      buffer = File.read(SingleDemo.app_file).gsub!(/The magick number is: \d+!/, new_phrase)
      File.open(SingleDemo.app_file, "w") { |f| f.write(buffer) }
      sleep 1.2 # We need at least a cooldown of 1 sec.
      get "/"
      assert_equal new_phrase, body
    end
  end
end