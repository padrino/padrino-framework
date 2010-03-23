require File.dirname(__FILE__) + '/helper'

class TestApplication < Test::Unit::TestCase

  def create_template(name, content, options={})
    FileUtils.mkdir_p(File.dirname(__FILE__) + "/views")
    FileUtils.mkdir_p(File.dirname(__FILE__) + "/views/layouts")
    path  = "/views/#{name}"
    path += ".#{options.delete(:locale)}" if options[:locale].present?
    path += ".#{options.delete(:format)}" if options[:format].present?
    path += ".erb"
    file  = File.dirname(__FILE__) + path
    File.open(file, 'w') { |io| io.write content }
    file
  end
  alias :create_view   :create_template
  alias :create_layout :create_template

  def remove_views
    FileUtils.rm_rf(File.dirname(__FILE__) + "/views")
  end

  def with_template(name, content, options={})
    # Build a temp layout
    template = create_template(name, content, options)
    yield
  ensure
    # Remove temp layout
    File.unlink(template) rescue nil
    remove_views
  end
  alias :with_view   :with_template
  alias :with_layout :with_template

  def teardown
    remove_views
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
      with_layout :application, "this is a <%= yield %>" do
        mock_app do
          get("/"){ render :erb, "rails way layout" }
        end

        get "/"
        assert_equal "this is a rails way layout", body
      end
    end

    should 'use rails way for a custom layout' do
      with_layout "layouts/custom", "this is a <%= yield %>" do
        mock_app do
          layout :custom
          get("/"){ render :erb, "rails way custom layout" }
        end

        get "/"
        assert_equal "this is a rails way custom layout", body
      end
    end

    should 'not use layout' do
      with_layout :application, "this is a <%= yield %>" do
        with_view :index, "index" do
          mock_app do
            get("/with/layout"){ render :index }
            get("/without/layout"){ render :index, :layout => false }
          end
          get "/with/layout"
          assert_equal "this is a index", body
          get "/without/layout"
          assert_equal "index", body
        end
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
          get("/inj") { erb "<%= 2+1 %>" }
          get("/rnj") { render :erb, "<%= 2+1 %>" }
        end
        get "/foo"
        assert_equal "3", body
        get "/bar"
        assert_equal "3", body
        get "/dir"
        assert_equal "3", body
        get "/inj"
        assert_equal "3", body
        get "/rnj"
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

    should 'resolve template content type' do
      create_view :foo, "Im Js", :format => :js
      create_view :foo, "Im Erb"
      mock_app do
        get("/foo", :respond_to => :js) { render :foo }
        get("/bar.js") { render :foo }
      end
      get "/foo.js"
      assert_equal "Im Js", body
      get "/bar.js"
      assert_equal "Im Js", body
      remove_views
    end

    should 'resolve template locale' do
      create_view :foo, "Im English", :locale => :en
      create_view :foo, "Im Italian", :locale => :it
      mock_app do
        get("/foo") { render :foo }
      end
      I18n.locale = :en
      get "/foo"
      assert_equal "Im English", body
      I18n.locale = :it
      get "/foo"
      assert_equal "Im Italian", body
    end

    should 'resolve template content_type and locale' do
      create_view :foo, "Im Js",          :format => :js
      create_view :foo, "Im Erb"
      create_view :foo, "Im English Erb", :locale => :en
      create_view :foo, "Im Italian Erb", :locale => :it
      create_view :foo, "Im English Js",  :format => :js, :locale => :en
      create_view :foo, "Im Italian Js",  :format => :js, :locale => :it
      mock_app do
        get("/foo", :respond_to => [:html, :js]) { render :foo }
      end
      I18n.locale = :none
      get "/foo.js"
      assert_equal "Im Js", body
      get "/foo"
      assert_equal "Im Erb", body
      I18n.locale = :en
      get "/foo"
      assert_equal "Im English Erb", body
      I18n.locale = :it
      get "/foo"
      assert_equal "Im Italian Erb", body
      I18n.locale = :en
      get "/foo.js"
      assert_equal "Im English Js", body
      I18n.locale = :it
      get "/foo.js"
      assert_equal "Im Italian Js", body
      I18n.locale = :en
      get "/foo.pk"
      assert_equal 404, status
    end

    should 'resolve template content_type and locale with layout' do
      create_layout :foo, "Hello <%= yield %> in a Js layout",     :format => :js
      create_layout :foo, "Hello <%= yield %> in a Js-En layout",  :format => :js, :locale => :en
      create_layout :foo, "Hello <%= yield %> in a Js-It layout",  :format => :js, :locale => :it
      create_layout :foo, "Hello <%= yield %> in a Erb-En layout", :locale => :en
      create_layout :foo, "Hello <%= yield %> in a Erb-It layout", :locale => :it
      create_layout :foo, "Hello <%= yield %> in a Erb layout"
      create_view   :bar, "Im Js",          :format => :js
      create_view   :bar, "Im Erb"
      create_view   :bar, "Im English Erb", :locale => :en
      create_view   :bar, "Im Italian Erb", :locale => :it
      create_view   :bar, "Im English Js",  :format => :js, :locale => :en
      create_view   :bar, "Im Italian Js",  :format => :js, :locale => :it
      create_view   :bar, "Im a json",      :format => :json
      mock_app do
        layout :foo
        get("/bar", :respond_to => [:html, :js, :json]) { render :bar }
      end
      I18n.locale = :none
      get "/bar.js"
      assert_equal "Hello Im Js in a Js layout", body
      get "/bar"
      assert_equal "Hello Im Erb in a Erb layout", body
      I18n.locale = :en
      get "/bar"
      assert_equal "Hello Im English Erb in a Erb-En layout", body
      I18n.locale = :it
      get "/bar"
      assert_equal "Hello Im Italian Erb in a Erb-It layout", body
      I18n.locale = :en
      get "/bar.js"
      assert_equal "Hello Im English Js in a Js-En layout", body
      I18n.locale = :it
      get "/bar.js"
      assert_equal "Hello Im Italian Js in a Js-It layout", body
      I18n.locale = :en
      get "/bar.json"
      assert_equal "Im a json", body
      get "/bar.pk"
      assert_equal 404, status
    end

    should 'renders erb with blocks' do
      mock_app do
        def container
          @_out_buf << "THIS."
          yield
          @_out_buf << "SPARTA!"
        end
        def is; "IS."; end
        get '/' do
          render :erb, '<% container do %> <%= is %> <% end %>'
        end
      end
      get '/'
      assert ok?
      assert_equal 'THIS. IS. SPARTA!', body
    end
  end
end