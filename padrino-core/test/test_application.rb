require File.dirname(__FILE__) + '/helper'
require 'fixtures/apps/layout'

class TestApplication < Test::Unit::TestCase

  def setup
    @app = Padrino.application
  end

  context 'for application functionality' do

    should 'check default options' do
      assert_match %r{test/helper.rb}, PadrinoTestApp.app_file
      assert_equal :test, PadrinoTestApp.environment
      assert_equal Padrino.root("views"), PadrinoTestApp.views
      assert PadrinoTestApp.raise_errors
      assert !PadrinoTestApp.logging
      assert PadrinoTestApp.sessions
      assert 'PadrinoTestApp', PadrinoTestApp.app_name
    end

    should 'check padrino specific options' do
      assert !PadrinoTestApp.instance_variable_get(:@_configured)
      PadrinoTestApp.send(:setup_application!)
      assert PadrinoTestApp.instance_variable_get(:@_configured)
      assert !PadrinoTestApp.send(:find_view_path)
      assert !PadrinoTestApp.reload?
      assert 'padrino_test_app', PadrinoTestApp.app_name
      assert 'StandardFormBuilder', PadrinoTestApp.default_builder
      assert !PadrinoTestApp.flash
      assert !PadrinoTestApp.padrino_mailer
      assert !PadrinoTestApp.padrino_helpers
    end
  end

  context 'for application layout functionality' do

    should 'get no layout' do
      get "/no_layout"
      assert_equal "no layout", body
    end

    should 'compatible with sinatra layout' do
      get "/sinatra"
      assert_equal "sinatra layout\n", body
    end
  end
end