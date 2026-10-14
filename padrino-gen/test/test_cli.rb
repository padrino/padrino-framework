require_relative 'helper'
require 'padrino-gen/generators/cli'

describe 'Cli' do
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{SecureRandom.hex}"
    `mkdir -p #{@apptmp}`
  end

  def teardown
    `rm -rf #{@apptmp}`
  end

  describe 'the cli' do
    it 'should fail without arguments' do
      out, = capture_io { generate(:cli) }
      assert_match(/Please specify generator to use/, out)
    end

    it 'should work correctly if we have a project' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:cli, "--root=#{@apptmp}/sample_project") }
      skip 'Make a great asserition'
    end

    it 'should give back the environment variables it sets while loading the project boot' do
      saved = { 'BUNDLE_GEMFILE' => ENV['BUNDLE_GEMFILE'], 'PADRINO_LOG_LEVEL' => ENV['PADRINO_LOG_LEVEL'] }
      ENV['BUNDLE_GEMFILE'] = '/caller/Gemfile'
      ENV['PADRINO_LOG_LEVEL'] = 'production'
      capture_io { Padrino::Generators::Cli.new([], root: @apptmp).load_boot }
      assert_equal '/caller/Gemfile', ENV['BUNDLE_GEMFILE']
      assert_equal 'production', ENV['PADRINO_LOG_LEVEL']

      ENV.delete('BUNDLE_GEMFILE')
      ENV.delete('PADRINO_LOG_LEVEL')
      capture_io { Padrino::Generators::Cli.new([], root: @apptmp).load_boot }
      assert_nil ENV['BUNDLE_GEMFILE']
      assert_nil ENV['PADRINO_LOG_LEVEL']
    ensure
      ENV.update(saved)
    end
  end
end
