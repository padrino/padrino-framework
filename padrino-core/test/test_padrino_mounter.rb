require File.dirname(__FILE__) + '/helper'

PADRINO_ENV = RACK_ENV = 'test' unless defined?(PADRINO_ENV)
require File.dirname(__FILE__) + '/fixtures/simple_app/app'
require 'padrino-core'

class TestPadrinoMounter < Test::Unit::TestCase

  def app
    Padrino.application.tap { }
  end

  def setup
    Padrino.mounted_apps.clear
    Padrino.mount("core_1_demo").to("/core_1_demo")
    Padrino.mount("core_2_demo").to("/core_2_demo")
  end

  context 'for mounter functionality' do
    
    should 'check methods' do
      mounter = Padrino::Mounter.new("test", :app_file => "/path/to/test.rb")
      mounter.to("/test")
      assert_kind_of Padrino::Mounter, mounter
      assert_respond_to Padrino::Mounter, :new
      assert_respond_to mounter, :to
      assert_respond_to mounter, :map_onto
      assert_equal "test", mounter.name
      assert_equal "/path/to/test.rb", mounter.app_file
      assert_equal "/test", mounter.uri_root
      assert_nil mounter.app_root
    end

    should 'mount some apps' do
      assert_equal ["core_1_demo", "core_2_demo"], Padrino.mounted_apps.collect(&:name)
    end

    should 'mount only a core' do
      Padrino.mounted_apps.clear
      Padrino.mount_core(:app_file => "#{Padrino.root("app.rb")}")
      assert_equal ["core"], Padrino.mounted_apps.collect(&:name)
    end

    should 'correctly instantiate a new padrino application' do
      visit '/core_1_demo'
      assert_contain "Im Core1Demo"
      visit '/core_2_demo'
      assert_contain "Im Core2Demo"
    end
  end
end