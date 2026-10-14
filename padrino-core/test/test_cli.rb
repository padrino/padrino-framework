require_relative 'helper'
require 'open3'
require 'tmpdir'

describe 'Padrino::Cli::Base' do
  describe 'run' do
    it 'should load the controllers of mounted apps before running the code' do
      Dir.mktmpdir do |dir|
        FileUtils.mkdir_p(File.join(dir, 'config'))
        FileUtils.mkdir_p(File.join(dir, 'app', 'controllers'))
        File.write(File.join(dir, 'app', 'app.rb'), "class RunnerDemo < Padrino::Application; end\n")
        File.write(File.join(dir, 'app', 'controllers', 'hello.rb'), "RunnerDemo.controllers { get(:hello) { 'ok' } }\n")
        File.write(File.join(dir, 'config', 'boot.rb'), <<~RUBY)
          PADRINO_ROOT = #{dir.inspect} unless defined?(PADRINO_ROOT)
          require 'padrino-core'
          require_relative '../app/app'
          Padrino.mount('RunnerDemo', app_file: File.expand_path('../app/app.rb', __dir__)).to('/')
          Padrino.load!
        RUBY
        script = <<~RUBY
          require 'padrino-core/cli/base'
          Padrino::Cli::Base.start(['run', 'puts "URL \#{RunnerDemo.url(:hello)}"'])
        RUBY
        lib = File.expand_path('../lib', __dir__)
        env = { 'RACK_ENV' => 'test', 'BUNDLE_GEMFILE' => File.expand_path('../../Gemfile', __dir__) }
        out, err, status = Open3.capture3(env, RbConfig.ruby, '-I', lib, '-e', script, chdir: dir)
        assert status.success?, err
        assert_includes out.lines.map(&:strip), 'URL /hello'
      end
    end
  end
end
