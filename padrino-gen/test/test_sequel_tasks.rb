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

  def rake(*args, path: nil)
    libs = %w[padrino-core padrino-gen].flat_map { |name| ['-I', File.expand_path("../../#{name}/lib", __dir__)] }
    env = { 'RACK_ENV' => 'development', 'BUNDLE_GEMFILE' => File.expand_path('../../Gemfile', __dir__) }
    env['PATH'] = "#{path}#{File::PATH_SEPARATOR}#{ENV['PATH']}" if path
    out, err, status = Open3.capture3(env, RbConfig.ruby, *libs, '-e', 'require "rake"; Rake.application.run(ARGV)', *args, chdir: @root)
    assert status.success?, "rake #{args.join(' ')} failed:\n#{out}\n#{err}"
    out
  end

  def database
    File.join(@root, 'db', 'development.db')
  end

  it 'should treat a database the boot could connect to as already created, then migrate it' do
    assert_includes rake('sq:create'), "<= Database 'db/development.db' already exists"
    assert File.file?(database)
    rake 'sq:migrate'
    assert_includes File.binread(database), 'widgets'
  end

  it 'should leave a database the boot could reach alone, without running createdb' do
    bin = File.join(@root, 'bin')
    FileUtils.mkdir_p(bin)
    File.write(File.join(bin, 'createdb'), "#!/bin/sh\ntouch #{File.join(@root, 'createdb.ran')}\nexit 1\n")
    File.chmod(0o755, File.join(bin, 'createdb'))
    File.write(File.join(@root, 'config', 'boot.rb'), <<~RUBY)
      require 'padrino-core'
      require 'sequel'
      db = Sequel.connect('sqlite://db/development.db')
      db.opts.update(adapter: 'postgres', host: 'db.internal', port: 5433, user: 'app', database: 'app_db')
      Sequel::Model.db = db
    RUBY
    assert_includes rake('sq:create', path: bin), "<= Database 'app_db' already exists"
    refute File.exist?(File.join(@root, 'createdb.ran'))
  end

  it 'should create a database the boot could not reach, with the configured port' do
    bin = File.join(@root, 'bin')
    FileUtils.mkdir_p(bin)
    File.write(File.join(bin, 'createdb'), "#!/bin/sh\necho \"createdb $*\" > #{File.join(@root, 'createdb.log')}\n")
    File.chmod(0o755, File.join(bin, 'createdb'))
    # A Postgres config whose database doesn't exist yet: the connection test fails.
    File.write(File.join(@root, 'config', 'boot.rb'), <<~RUBY)
      require 'padrino-core'
      require 'sequel'
      db = Sequel.connect('sqlite://db/development.db')
      db.opts.update(adapter: 'postgres', host: 'db.internal', port: 5433, user: 'app', database: 'app_db')
      def db.test_connection
        raise Sequel::DatabaseConnectionError, 'database "app_db" does not exist'
      end
      Sequel::Model.db = db
    RUBY
    out = rake('sq:create', path: bin)
    assert_includes out, '<= sq:create executed'
    assert_equal "createdb --encoding=utf8 --host=db.internal --port=5433 --username=app app_db\n", File.read(File.join(@root, 'createdb.log'))
  end

  it 'should drop a SQLite database' do
    rake 'sq:create'
    assert_includes rake('sq:drop'), '<= sq:drop executed'
    refute File.exist?(database)
  end
end
