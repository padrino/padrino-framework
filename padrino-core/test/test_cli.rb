require_relative 'helper'
require 'open3'
require 'tmpdir'

describe 'Padrino::Cli' do
  # Runs the script in a temp project with one app mounted at /.
  def run_in_project(script)
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, 'config'))
      FileUtils.mkdir_p(File.join(dir, 'app'))
      File.write(File.join(dir, 'app', 'app.rb'), "class CliDemo < Padrino::Application; end\n")
      File.write(File.join(dir, 'config', 'boot.rb'), <<~RUBY)
        PADRINO_ROOT = #{dir.inspect} unless defined?(PADRINO_ROOT)
        require 'padrino-core'
        require_relative '../app/app'
        Padrino.mount('CliDemo', app_file: File.expand_path('../app/app.rb', __dir__)).to('/')
        Padrino.load!
      RUBY
      lib = File.expand_path('../lib', __dir__)
      env = { 'RACK_ENV' => 'test', 'BUNDLE_GEMFILE' => File.expand_path('../../Gemfile', __dir__) }
      Open3.capture3(env, RbConfig.ruby, '-I', lib, '-e', script, chdir: dir)
    end
  end

  it 'should say how to add irb when padrino console cannot load it' do
    _, err, status = run_in_project(<<~RUBY)
      # Ruby 4.0 without irb in the bundle
      module Kernel
        alias_method :require_before_test, :require
        def require(name)
          raise LoadError, 'cannot load such file -- irb' if name == 'irb'

          require_before_test(name)
        end
      end
      require 'padrino-core/cli/base'
      Padrino::Cli::Base.start(['console'])
    RUBY
    assert_equal 1, status.exitstatus
    assert_includes err, "add gem 'irb' to your Gemfile"
  end
end
