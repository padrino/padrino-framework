require File.expand_path(File.dirname(__FILE__) + '/helper')
require 'padrino-gen/generators/cli'

class TestCli < Test::Unit::TestCase
  def setup
    `rm -rf /tmp/sample_project`
  end

  context 'the cli' do

    should "fail without arguments" do
      output = silence_logger { Padrino::Generators::Cli.start }
      assert_match "Please specify generator to use", output
    end

    should "work correctly if we have a project" do
      silence_logger { Padrino::Generators::Project.start(['sample_project', '--root=/tmp']) }
      assert_nothing_raised { silence_logger { Padrino::Generators::Cli.start(['--root=/tmp/sample_project']) } }
    end
  end
end