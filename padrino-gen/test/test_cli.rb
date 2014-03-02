require File.expand_path(File.dirname(__FILE__) + '/helper')
require 'padrino-gen/generators/cli'

describe "Cli" do
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{SecureRandom.hex}"
    `mkdir -p #{@apptmp}`
  end

  def teardown
    `rm -rf #{@apptmp}`
  end

  describe 'the cli' do

    it 'should fail without arguments' do
      out, err = capture_io { generate(:cli) }
      assert_match(/Please specify generator to use/, out)
    end

    it 'should work correctly if we have a project' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:cli, "--root=#{@apptmp}/sample_project") }
      skip "Make a great asserition"
    end
  end
end
