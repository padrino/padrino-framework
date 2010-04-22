require File.expand_path(File.dirname(__FILE__) + '/helper')
require 'padrino-gen/generators/cli'

class TestCli < Test::Unit::TestCase
  def setup
    `rm -rf /tmp/sample_project`
  end

  context 'the cli' do

    should "fail without arguments" do
      output = silence_logger { generate(:cli) }
      assert_match "Please specify generator to use", output
    end

    should "work correctly if we have a project" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp') }
      assert_nothing_raised { silence_logger { generate(:cli, '--root=/tmp/sample_project') } }
    end
  end
end