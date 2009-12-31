require File.dirname(__FILE__) + '/helper'
require 'thor'

class TestControllerGenerator < Test::Unit::TestCase
  def setup
    Padrino::Generators.lockup!
    @app = Padrino::Generators::App.dup
    @contgen = Padrino::Generators::Controller.dup
    @controller_path = '/tmp/sample_app/app/controllers/demo_items.rb'
    @controller_test_path = '/tmp/sample_app/test/controllers/demo_items_controller_test.rb'
    @route_path = '/tmp/sample_app/config/urls.rb'
    `rm -rf /tmp/sample_app`
  end

  context 'the controller generator' do
    should "fail outside app root" do
      output = silence_logger { @contgen.start(['demo', '-r=/tmp']) }
      assert_match(/not at the root/, output)
      assert_no_file_exists('/tmp/app/controllers/demo.rb')
    end

    should "generate controller within existing application" do
      silence_logger { @app.start(['sample_app', '/tmp', '--script=none', '-t=bacon']) }
      silence_logger { @contgen.start(['demo_items', '-r=/tmp/sample_app']) }
      assert_match_in_file(/SampleApp.controllers do/m, @controller_path)
      assert_match_in_file(/SampleApp.helpers do/m, '/tmp/sample_app/app/helpers/demo_items_helper.rb')
      assert_file_exists('/tmp/sample_app/app/views/demo_items')
    end

    should "generate controller test for bacon" do
      silence_logger { @app.start(['sample_app', '/tmp', '--script=none', '-t=bacon']) }
      silence_logger { @contgen.start(['demo_items', '-r=/tmp/sample_app']) }
      assert_match_in_file(/describe "DemoItemsController" do/m, @controller_test_path)
    end

    should "generate controller test for riot" do
      silence_logger { @app.start(['sample_app', '/tmp', '--script=none', '-t=riot']) }
      silence_logger { @contgen.start(['demo_items', '-r=/tmp/sample_app']) }
      assert_match_in_file(/context "DemoItemsController" do/m, @controller_test_path)
    end

    should "generate controller test for testspec" do
      silence_logger { @app.start(['sample_app', '/tmp', '--script=none', '-t=testspec']) }
      silence_logger { @contgen.start(['demo_items', '-r=/tmp/sample_app']) }
      assert_match_in_file(/context "DemoItemsController" do/m, @controller_test_path)
    end

    should "generate controller test for rspec" do
      silence_logger { @app.start(['sample_app', '/tmp', '--script=none', '-t=rspec']) }
      silence_logger { @contgen.start(['demo_items', '-r=/tmp/sample_app']) }
      assert_match_in_file(/describe "DemoItemsController" do/m, '/tmp/sample_app/test/controllers/demo_items_controller_spec.rb')
    end

    should "generate controller test for shoulda" do
      silence_logger { @app.start(['sample_app', '/tmp', '--script=none', '-t=shoulda']) }
      silence_logger { @contgen.start(['demo_items', '-r=/tmp/sample_app']) }
      expected_pattern = /class DemoItemsControllerTest < Test::Unit::TestCase/m
      assert_match_in_file(expected_pattern, @controller_test_path)
    end

    # Controller action generation

    should "generate actions for get:test post:yada" do
      silence_logger { @app.start(['sample_app', '/tmp', '--script=none', '-t=shoulda'])}
      silence_logger { @contgen.start(['demo_items', "get:test","post:yada",'-r=/tmp/sample_app']) }
      assert_match_in_file(/get :test do\n  end\n/m,@controller_path)
      assert_match_in_file(/post :yada do\n  end\n/m,@controller_path)
    end

    should "generate url routes for get:yoda post:yada" do
      silence_logger { @app.start(['sample_app', '/tmp', '--script=none', '-t=shoulda'])}
      silence_logger { @contgen.start(['demo_items', "get:yoda","post:yada",'-r=/tmp/sample_app']) }
      assert_match_in_file(/map\(\:yoda\).to\(\"\/demo_items\/yoda\"\)/m,@route_path)
      assert_match_in_file(/map\(\:yada\).to\(\"\/demo_items\/yada\"\)/m,@route_path)
    end

  end

  context "the controller destroy option" do

    should "destroy controller file" do
      silence_logger { @app.start(['sample_app', '/tmp', '--script=none', '-t=shoulda'])}
      silence_logger { @contgen.start(['demo_items','-r=/tmp/sample_app']) }
      silence_logger { @contgen.start(['demo_items','-r=/tmp/sample_app','-d=true'])}
      assert_no_file_exists(@controller_path)
    end

    should "destroy controller test" do
      silence_logger { @app.start(['sample_app', '/tmp', '--script=none', '-t=shoulda'])}
      silence_logger { @contgen.start(['demo_items','-r=/tmp/sample_app']) }
      silence_logger { @contgen.start(['demo_items','-r=/tmp/sample_app','-d=true'])}
      assert_no_file_exists(@controller_test_path)
    end

    should "destroy controller test" do
      silence_logger { @app.start(['sample_app', '/tmp', '--script=none', '-t=rspec'])}
      silence_logger { @contgen.start(['demo_items','-r=/tmp/sample_app']) }
      silence_logger { @contgen.start(['demo_items','-r=/tmp/sample_app','-d=true'])}
      assert_no_file_exists('/tmp/sample_app/test/controllers/demo_items_controller_spec.rb')
    end
    
    should "destroy controller helper" do
      silence_logger { @app.start(['sample_app', '/tmp', '--script=none', '-t=rspec'])}
      silence_logger { @contgen.start(['demo_items','-r=/tmp/sample_app']) }
      silence_logger { @contgen.start(['demo_items','-r=/tmp/sample_app','-d=true'])}
      assert_no_file_exists('/tmp/sample_app/app/helpers/demo_items_helper.rb')
    end

    should "remove url routes" do
      silence_logger { @app.start(['sample_app', '/tmp', '--script=none', '-t=shoulda'])}
      silence_logger { @contgen.start(['demo_items', "get:yoda","post:yada",'-r=/tmp/sample_app']) }
      silence_logger { @contgen.start(['demo_items','-r=/tmp/sample_app','-d=true'])}
      assert_no_match_in_file(/map\(\:yoda\).to\(\"\/demo_items\/yoda\"\)/m,@route_path)
      assert_no_match_in_file(/map\(\:yada\).to\(\"\/demo_items\/yada\"\)/m,@route_path)
    end

  end


end
