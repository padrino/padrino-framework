require File.dirname(__FILE__) + '/helper'

PADRINO_ENV = RACK_ENV = 'test' unless defined?(PADRINO_ENV)
require File.dirname(__FILE__) + '/fixtures/simple_app/app'
require 'padrino-core'

class TestPadrinoApplication < Test::Unit::TestCase

  def app
    Padrino.application.tap { }
  end

  def setup
    Padrino.mounted_apps.clear
    Padrino.mount("core_1_demo").to("/core_1_demo")
    Padrino.mount("core_2_demo").to("/core_2_demo")
  end

  context 'for application functionality' do
    
    should 'check methods' do
      assert_respond_to Padrino::Application, :new
      assert_respond_to Padrino::Application, :controllers
      assert_respond_to Padrino::Application, :setup_application!
      assert_respond_to Padrino::Application, :default_configuration!
      assert_respond_to Padrino::Application, :calculate_paths
      assert_respond_to Padrino::Application, :register_initializers
      assert_respond_to Padrino::Application, :register_framework_extensions
      assert_respond_to Padrino::Application, :require_load_paths
      assert_respond_to Padrino::Application, :setup_logger
      assert_respond_to Padrino::Application, :load_paths
      assert_respond_to Padrino::Application, :find_view_path
    end

    should 'have controllers' do
      Core1Demo.controllers do
        get("/controller") { "Im a controller" }
      end
      visit "/core_1_demo/controller"
      assert_contain "Im a controller"
    end
    
    
  end
end