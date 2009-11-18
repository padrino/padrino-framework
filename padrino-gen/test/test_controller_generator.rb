require File.dirname(__FILE__) + '/helper'
require 'thor'

class TestControllerGenerator < Test::Unit::TestCase
  def setup
    @skeleton = Padrino::Generators::Skeleton.dup
    @contgen = Padrino::Generators::Controller.dup
    `rm -rf /tmp/sample_app`
  end

  context 'the controller generator' do
    should "fail outside app root" do
      output = silence_logger { @contgen.start(['demo', '-r=/tmp']) }
      assert_match(/not at the root/, output)
      assert !File.exist?('/tmp/app/controllers/demo.rb')
    end

    should "generate controller within existing application" do
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=bacon']) }
      silence_logger { @contgen.start(['demo_items', '-r=/tmp/sample_app']) }
      assert_match_in_file(/SampleApp::controllers do/m, '/tmp/sample_app/app/controllers/demo_items.rb')
      assert_match_in_file(/SampleApp::helpers do/m, '/tmp/sample_app/app/helpers/demo_items_helper.rb')
      assert File.exist?('/tmp/sample_app/app/views/demo_items')
    end

    should "generate controller test for bacon" do
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=bacon']) }
      silence_logger { @contgen.start(['demo_items', '-r=/tmp/sample_app']) }
      assert_match_in_file(/describe "DemoItemsController" do/m, '/tmp/sample_app/test/controllers/demo_items_controller_test.rb')
    end

    should "generate controller test for riot" do
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=riot']) }
      silence_logger { @contgen.start(['demo_items', '-r=/tmp/sample_app']) }
      assert_match_in_file(/context "DemoItemsController" do/m, '/tmp/sample_app/test/controllers/demo_items_controller_test.rb')
    end

    should "generate controller test for testspec" do
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=testspec']) }
      silence_logger { @contgen.start(['demo_items', '-r=/tmp/sample_app']) }
      assert_match_in_file(/context "DemoItemsController" do/m, '/tmp/sample_app/test/controllers/demo_items_controller_test.rb')
    end

    should "generate controller test for rspec" do
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=rspec']) }
      silence_logger { @contgen.start(['demo_items', '-r=/tmp/sample_app']) }
      assert_match_in_file(/describe "DemoItemsController" do/m, '/tmp/sample_app/test/controllers/demo_items_controller_spec.rb')
    end

    should "generate controller test for shoulda" do
      silence_logger { @skeleton.start(['sample_app', '/tmp', '--script=none', '-t=shoulda']) }
      silence_logger { @contgen.start(['demo_items', '-r=/tmp/sample_app']) }
      expected_pattern = /class DemoItemsControllerTest < Test::Unit::TestCase/m
      assert_match_in_file(expected_pattern, '/tmp/sample_app/test/controllers/demo_items_controller_test.rb')
    end
  end
end
