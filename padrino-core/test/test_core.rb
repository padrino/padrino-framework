require File.dirname(__FILE__) + '/helper'

class TestCore < Test::Unit::TestCase

  context 'for core functionality' do

    should 'check some global methods' do
      assert_respond_to Padrino, :root
      assert_respond_to Padrino, :env
      assert_respond_to Padrino, :application
      assert_respond_to Padrino, :set_encoding
      assert_respond_to Padrino, :load!
      assert_respond_to Padrino, :reload!
      assert_respond_to Padrino, :version
    end

    should 'validate global helpers' do
      assert_equal :test, Padrino.env
      assert_match /\/test/, Padrino.root
    end

    should 'set correct utf-8 encoding' do
      Padrino.set_encoding
      if RUBY_VERSION >= '1.9'
        assert_equal nil, $KCODE
      else
        assert_equal 'UTF8', $KCODE
      end
    end

    should 'have load paths' do
      assert_equal [Padrino.root('lib'), Padrino.root('models'), Padrino.root('shared')], Padrino.load_paths
    end

    should 'raise application error if I instantiate a new padrino application without mounted apps' do
      Padrino.mounted_apps.clear
      assert_raise(Padrino::ApplicationLoadError) { Padrino.application.new }
    end
  end
end