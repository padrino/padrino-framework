require File.dirname(__FILE__) + '/helper'

PADRINO_ENV = RACK_ENV = 'test' unless defined?(PADRINO_ENV)
require File.dirname(__FILE__) + '/fixtures/simple_app/app'
require 'padrino-core'

class TestPadrinoCore < Test::Unit::TestCase

  context 'for core functionality' do

    should 'check global methods' do
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
      assert_equal "test", Padrino.env
      assert_equal "./test/fixtures/simple_app", Padrino.root
    end
    
    should 'raise application error if I istantiate a new padrino application without mounted apps' do
      assert_raise Padrino::ApplicationLoadError do
        Padrino.application.tap { }
      end
    end
  end
end
