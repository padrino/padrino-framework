require_relative 'helper'
require 'open3'
require 'tmpdir'
require 'padrino-core/cli/binstub'

describe 'Padrino.replace_with_binstub' do
  it 'should tell the user to generate binstubs with bundle binstubs --all' do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'Gemfile'), '')
      File.write(File.join(dir, '.components'), '')
      _, err = capture_io do
        Bundler.stub(:definition, -> { raise Bundler::GemfileNotFound }) do
          Padrino.stub(:exit!, nil) do
            Dir.chdir(dir) { Padrino.replace_with_binstub('padrino') }
          end
        end
      end
      assert_match(/bundle install && bundle binstubs --all/, err)
      refute_match(/--binstubs/, err)
    end
  end

  # Runs the executable outside any bundle in a project without bin/, with its output piped.
  def run_without_binstubs(bin, env = {})
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'Gemfile'), '')
      File.write(File.join(dir, '.components'), '')
      run = -> { Open3.capture3(env, RbConfig.ruby, '-I', File.expand_path('../lib', __dir__), bin, 'version', chdir: dir) }
      defined?(Bundler) ? Bundler.with_unbundled_env(&run) : run.call
    end
  end

  %w[padrino-core/bin/padrino padrino-gen/bin/padrino-gen].each do |executable|
    it "should show the binstubs hint and exit 1 when the output of #{executable} is piped" do
      out, err, status = run_without_binstubs(File.expand_path("../../#{executable}", __dir__))
      assert_equal 1, status.exitstatus
      assert_includes err, 'bundle install && bundle binstubs --all'
      refute_includes out, 'bundle binstubs'
    end
  end

  it 'should show the binstubs hint with warnings turned off' do
    _, err, status = run_without_binstubs(File.expand_path('../../padrino-core/bin/padrino', __dir__), 'RUBYOPT' => '-W0')
    assert_equal 1, status.exitstatus
    assert_includes err, 'bundle install && bundle binstubs --all'
  end
end
