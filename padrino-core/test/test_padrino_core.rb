require File.dirname(__FILE__) + '/helper'
require File.dirname(__FILE__) + '/fixtures/simple_app/app'

class TestPadrinoCore < Test::Unit::TestCase
  
  def app
    Padrino.application.tap
  end
  
  def setup
    silence_logger { Padrino.load! }
  end

  context 'for core functionality' do

    should 'check global helpers' do
      assert_respond_to Padrino, :env
      assert_respond_to Padrino, :root
      assert_respond_to Padrino, :load!
      assert_respond_to Padrino, :reload!
      assert_respond_to Padrino, :load_dependencies
      assert_respond_to Padrino, :load_required_gems
      assert_respond_to Padrino, :mounted_root
      assert_respond_to Padrino, :mounted_apps
      assert_respond_to Padrino, :mount
      assert_respond_to Padrino, :mount_core
      assert_respond_to Padrino, :version
    end

    should 'validate global helpers' do
      # We mount a demo app
      Padrino.mount("demo", :app_file => "#{Padrino.root("app.rb")}").to("/demo")
      
      assert_equal Padrino.env, "test"
      assert_equal Padrino.root, File.dirname(__FILE__) + "/fixtures/simple_app"
      assert_equal Padrino.mounted_apps.collect(&:name), ["demo"]
    end
  end
end
