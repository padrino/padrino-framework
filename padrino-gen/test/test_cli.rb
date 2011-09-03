require File.expand_path(File.dirname(__FILE__) + '/helper')
require 'padrino-gen/generators/cli'

describe "Cli" do
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{UUID.new.generate}"
    `mkdir -p #{@apptmp}`
  end

  def teardown
    `rm -rf #{@apptmp}`
  end

  context 'the cli' do

    should "fail without arguments" do
      output = silence_logger { generate(:cli) }
      assert_match "Please specify generator to use", output
    end

    should "work correctly if we have a project" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      silence_logger { generate(:cli, "--root=#{@apptmp}/sample_project") }
      skip "Make a great asserition"
    end
  end
end
