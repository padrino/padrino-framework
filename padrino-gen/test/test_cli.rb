require File.dirname(__FILE__) + '/helper'
require 'thor/group'
require 'fakeweb'

class TestCli < Test::Unit::TestCase
  def setup
    FakeWeb.allow_net_connect = false
    `rm -rf /tmp/sample_project`
    @cli     = Padrino::Generators::Cli.dup
    @project = Padrino::Generators::Project.dup
  end

  context 'the cli' do

    should "fail without arguments" do
      output = silence_logger { @cli.start }
      assert_match "Please specify generator to use", output
    end

    should "work correctly if we have a project" do
      silence_logger { @project.start(['sample_project', '--root=/tmp']) }
      assert_nothing_raised { silence_logger { @cli.start(['--root=/tmp/sample_project']) } }
    end
  end
end
