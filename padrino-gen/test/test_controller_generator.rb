require File.dirname(__FILE__) + '/helper'
require 'thor'

class TestSkeletonGenerator < Test::Unit::TestCase
  def setup
    `rm -rf /tmp/sample_app`
  end
  
  context 'the controller generator' do
    should "fail outside app root" do
      output = silence_logger { Padrino::Generators::Controller.start(['demo', '-r=/tmp']) }
      assert_match(/not at the root/, output)
      assert !File.exist?('/tmp/app/controllers/demo.rb')
    end
    
    should "generate controller within existing application" do
      silence_logger { Padrino::Generators::Skeleton.start(['sample_app', '/tmp', '--script=none']) }
      silence_logger { Padrino::Generators::Controller.start(['demo', '-r=/tmp/sample_app']) } 
      assert File.exist?('/tmp/sample_app/app/controllers/demo.rb')
      assert_match_in_file(/SampleApp::controllers do/m, '/tmp/sample_app/app/controllers/demo.rb')
    end
  end
end