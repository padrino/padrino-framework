require_relative 'helper'
require 'open3'
require 'tmpdir'

describe 'Sequel tasks' do
  def setup
    skip 'sqlite3 is only bundled on MRI' if RUBY_ENGINE == 'jruby'
    @root = Dir.mktmpdir
    FileUtils.mkdir_p(File.join(@root, 'config'))
    FileUtils.mkdir_p(File.join(@root, 'db', 'migrate'))
    File.write(File.join(@root, 'Rakefile'), <<~RUBY)
      require 'padrino-core/cli/rake'
      PadrinoTasks.use(:sequel)
      PadrinoTasks.init
    RUBY
    # Like a generated project: connecting at boot creates the SQLite file.
    File.write(File.join(@root, 'config', 'boot.rb'), <<~RUBY)
      require 'padrino-core'
      require 'sequel'
      Sequel::Model.db = Sequel.connect('sqlite://db/development.db')
    RUBY
    File.write(File.join(@root, 'db', 'migrate', '001_create_widgets.rb'), <<~RUBY)
      Sequel.migration do
        change { create_table(:widgets) { primary_key :id } }
      end
    RUBY
  end

  def teardown
    FileUtils.rm_rf(@root) if @root
  end

  def rake(*args)
    libs = %w[padrino-core padrino-gen].flat_map { |name| ['-I', File.expand_path("../../#{name}/lib", __dir__)] }
    env = { 'RACK_ENV' => 'development', 'BUNDLE_GEMFILE' => File.expand_path('../../Gemfile', __dir__) }
    out, err, status = Open3.capture3(env, RbConfig.ruby, *libs, '-e', 'require "rake"; Rake.application.run(ARGV)', *args, chdir: @root)
    assert status.success?, "rake #{args.join(' ')} failed:\n#{out}\n#{err}"
    out
  end

  def database
    File.join(@root, 'db', 'development.db')
  end

  it 'should create a SQLite database that connecting already created, then migrate it' do
    assert_includes rake('sq:create'), '<= sq:create executed'
    assert File.file?(database)
    rake 'sq:migrate'
    assert_includes File.binread(database), 'widgets'
  end

  it 'should drop a SQLite database' do
    rake 'sq:create'
    assert_includes rake('sq:drop'), '<= sq:drop executed'
    refute File.exist?(database)
  end
end
