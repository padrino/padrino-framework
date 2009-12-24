require File.dirname(__FILE__) + '/helper'

class TestApplication < Test::Unit::TestCase

  def with_layout(name=:application)
    # Build a temp layout
    FileUtils.mkdir_p(File.dirname(__FILE__) + "/views/layouts")
    layout = File.dirname(__FILE__) + "/views/layouts/#{name}.erb"
    File.open(layout, 'wb') { |io| io.write "this is a <%= yield %>" }
    yield
  ensure
    # Remove temp layout
    File.unlink(layout) rescue nil
    FileUtils.rm_rf(File.dirname(__FILE__) + "/views")
  end

  def with_view(name, content)
    # Build a temp layout
    FileUtils.mkdir_p(File.dirname(__FILE__) + "/views")
    layout = File.dirname(__FILE__) + "/views/#{name}.erb"
    File.open(layout, 'wb') { |io| io.write content }
    yield
  ensure
    # Remove temp layout
    File.unlink(layout) rescue nil
    FileUtils.rm_rf(File.dirname(__FILE__) + "/views")
  end

  class PadrinoTestApp < Padrino::Application; end

  context 'for application functionality' do

    should 'check default options' do
      assert_match __FILE__, PadrinoTestApp.app_file
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
      mock_app do
        get("/"){ "no layout" }
      end

      get "/"
      assert_equal "no layout", body
    end

    should 'be compatible with sinatra layout' do
      mock_app do
        layout do
          "this is a <%= yield %>"
        end
        
        get("/"){ render :erb, "sinatra layout" }
      end

      get "/"
      assert_equal "this is a sinatra layout", body
    end

    should 'use rails way layout' do
      with_layout do
        mock_app do
          get("/"){ render :erb, "rails way layout" }
        end

        get "/"
        assert_equal "this is a rails way layout", body
      end
    end

    should 'use rails way for a custom layout' do
      with_layout :custom do
        mock_app do
          layout :custom
          get("/"){ render :erb, "rails way custom layout" }
        end

        get "/"
        assert_equal "this is a rails way custom layout", body
      end
    end
  end

  context 'for application render functionality' do

    should 'be compatible with sinatra render' do
      mock_app do
        get("/"){ render :erb, "<%= 1+2 %>" }
      end
      get "/"
      assert_equal "3", body
    end

    should 'be compatible with sinatra views' do
      with_view :index, "<%= 1+2 %>" do
        mock_app do
          get("/foo") { render :erb, :index }
          get("/bar") { erb :index }
          get("/dir") { "3" }
        end
        get "/foo"
        assert_equal "3", body
        get "/bar"
        assert_equal "3", body
        get "/dir"
        assert_equal "3", body
      end
    end

    should 'resolve template engine' do
      with_view :index, "<%= 1+2 %>" do
        mock_app do
          get("/foo") { render :index }
          get("/bar") { render "/index" }
        end
        get "/foo"
        assert_equal "3", body
        get "/bar"
        assert_equal "3", body
      end
    end
  end
end