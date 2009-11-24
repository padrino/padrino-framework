require File.dirname(__FILE__) + '/helper'

class TestPadrinoCore < Test::Unit::TestCase

  context 'for core functionality' do

    should 'check some global methods' do
      assert_respond_to Padrino, :env
      assert_respond_to Padrino, :root
      assert_respond_to Padrino, :load!
      assert_respond_to Padrino, :reload!
      assert_respond_to Padrino, :version
    end

    should 'validate global helpers' do
      assert_equal :test, Padrino.env
      assert_match /\/test/, Padrino.root
    end
    
    should 'raise application error if I instantiate a new padrino application without mounted apps' do
      Padrino.mounted_apps.clear
      assert_raise Padrino::ApplicationLoadError do
        Padrino.application.tap { }
      end
    end
  end
end