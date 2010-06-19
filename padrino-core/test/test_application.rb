require File.expand_path(File.dirname(__FILE__) + '/helper')

class PadrinoTestApp < Padrino::Application; end

class TestApplication < Test::Unit::TestCase
  def setup
    Padrino.mounted_apps.clear
  end

  def teardown
    remove_views
  end

  context 'for application functionality' do

    should 'check default options' do
      assert File.identical?(__FILE__, PadrinoTestApp.app_file)
      assert_equal :padrino_test_app, PadrinoTestApp.app_name
      assert_equal :test, PadrinoTestApp.environment
      assert_equal Padrino.root("views"), PadrinoTestApp.views
      assert PadrinoTestApp.raise_errors
      assert !PadrinoTestApp.logging
      assert !PadrinoTestApp.sessions
    end

    should 'check padrino specific options' do
      assert !PadrinoTestApp.instance_variable_get(:@_configured)
      PadrinoTestApp.send(:setup_application!)
      assert_equal :padrino_test_app, PadrinoTestApp.app_name
      assert_equal 'StandardFormBuilder', PadrinoTestApp.default_builder
      assert PadrinoTestApp.instance_variable_get(:@_configured)
      assert !PadrinoTestApp.reload?
      assert !PadrinoTestApp.flash
    end

    # compare to: test_routing: allow global provides
    should "set content_type to :html if none can be determined" do
      mock_app do
        provides :xml

        get("/foo"){ "Foo in #{content_type}" }
        get("/bar"){ "Foo in #{content_type}" }
      end

      get '/foo', {}, { 'HTTP_ACCEPT' => 'application/xml' }
      assert_equal 'Foo in xml', body
      get '/foo'
      assert not_found?

      get '/bar', {}, { 'HTTP_ACCEPT' => 'application/xml' }
      assert_equal "Foo in html", body
    end
  end
end
