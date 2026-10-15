require_relative 'helper'
require 'open3'
require 'tmpdir'

describe 'Padrino::Cli' do
  # Runs the script in a temp project whose app is mounted at /runner and keeps its route in
  # app/controllers, so the route exists only after the app is set up with its mount settings.
  def run_in_project(script)
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, 'config'))
      FileUtils.mkdir_p(File.join(dir, 'app', 'controllers'))
      File.write(File.join(dir, 'app', 'app.rb'), "class RunnerDemo < Padrino::Application; end\n")
      File.write(File.join(dir, 'app', 'controllers', 'hello.rb'), "RunnerDemo.controllers { get(:hello) { 'ok' } }\n")
      File.write(File.join(dir, 'config', 'boot.rb'), <<~RUBY)
        PADRINO_ROOT = #{dir.inspect} unless defined?(PADRINO_ROOT)
        require 'padrino-core'
        require_relative '../app/app'
        Padrino.mount('RunnerDemo', app_file: File.expand_path('../app/app.rb', __dir__)).to('/runner')
        Padrino.load!
      RUBY
      lib = File.expand_path('../lib', __dir__)
      env = { 'RACK_ENV' => 'test', 'BUNDLE_GEMFILE' => File.expand_path('../../Gemfile', __dir__) }
      Open3.capture3(env, RbConfig.ruby, '-I', lib, '-e', script, chdir: dir)
    end
  end

  it 'should set up the mounted apps before padrino run runs the code' do
    out, err, status = run_in_project(<<~RUBY)
      require 'padrino-core/cli/base'
      Padrino::Cli::Base.start(['run', 'puts "URL \#{RunnerDemo.url(:hello)}"'])
    RUBY
    assert status.success?, err
    assert_includes out.lines.map(&:strip), 'URL /runner/hello'
  end

  it 'should set up the mounted apps with their mount path in padrino console' do
    out, err, status = run_in_project(<<~RUBY)
      require File.expand_path('config/boot.rb')
      require 'padrino-core/cli/console'
      puts "URL \#{RunnerDemo.url(:hello)}"
    RUBY
    assert status.success?, err
    assert_includes out.lines.map(&:strip), 'URL /runner/hello'
  end

  it 'should say how to add irb when padrino console cannot load it' do
    _, err, status = run_in_project(<<~RUBY)
      # Ruby 4.0 without irb in the bundle
      module Kernel
        alias_method :require_before_test, :require
        def require(name)
          if name == 'irb'
            error = LoadError.new('cannot load such file -- irb')
            error.define_singleton_method(:path) { 'irb' }
            raise error
          end

          require_before_test(name)
        end
      end
      require 'padrino-core/cli/base'
      Padrino::Cli::Base.start(['console'])
    RUBY
    assert_equal 1, status.exitstatus
    assert_includes err, "add gem 'irb' to your Gemfile"
  end

  it 'should not hide a LoadError from inside irb in padrino console' do
    _, err, status = run_in_project(<<~RUBY)
      module Kernel
        alias_method :require_before_test, :require
        def require(name)
          require_before_test(name == 'irb' ? 'padrino_missing_irb_dependency' : name)
        end
      end
      require 'padrino-core/cli/base'
      Padrino::Cli::Base.start(['console'])
    RUBY
    refute status.success?
    assert_includes err, 'padrino_missing_irb_dependency'
    refute_includes err, "add gem 'irb'"
  end

  it 'should load the models in the rake environment task after a skeleton task' do
    out, err, status = run_in_project(<<~RUBY)
      require 'rake'
      FileUtils.mkdir_p('models')
      File.write('models/widget.rb', "class Widget; end\\n")
      load 'padrino-core/cli/rake_tasks.rb'
      Rake::Task[:skeleton].invoke
      puts "SKELETON \#{defined?(Widget).inspect}"
      Rake::Task[:environment].invoke
      puts "ENVIRONMENT \#{defined?(Widget).inspect}"
    RUBY
    assert status.success?, err
    assert_includes out.lines.map(&:strip), 'SKELETON nil'
    assert_includes out.lines.map(&:strip), 'ENVIRONMENT "constant"'
  end

  it 'should set up the mounted apps with their mount path in the rake environment task' do
    out, err, status = run_in_project(<<~RUBY)
      require 'rake'
      load 'padrino-core/cli/rake_tasks.rb'
      Rake::Task[:environment].invoke
      puts "URL \#{RunnerDemo.url(:hello)}"
    RUBY
    assert status.success?, err
    assert_includes out.lines.map(&:strip), 'URL /runner/hello'
  end
end
