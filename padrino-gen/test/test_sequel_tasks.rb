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
    @stderr = err
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

  it 'should migrate without migration files, as a new project has none' do
    File.delete(File.join(@root, 'db', 'migrate', '001_create_widgets.rb'))
    %w[sq:migrate sq:migrate:down sq:migrate:auto].each do |task|
      assert_includes rake(task), '<= No migrations in db/migrate'
    end
    FileUtils.rm_rf(File.join(@root, 'db', 'migrate'))
    assert_includes rake('db:migrate'), '<= No migrations in db/migrate'
  end

  it 'should run a migration whose extension is upper case, as Sequel does' do
    File.rename(File.join(@root, 'db', 'migrate', '001_create_widgets.rb'), File.join(@root, 'db', 'migrate', '001_create_widgets.RB'))
    rake 'sq:migrate'
    assert_includes File.binread(database), 'widgets'
  end

  it 'should still reject migration files that are not named like migrations' do
    File.rename(File.join(@root, 'db', 'migrate', '001_create_widgets.rb'), File.join(@root, 'db', 'migrate', 'create_widgets.rb'))
    error = assert_raises(Minitest::Assertion) { rake 'sq:migrate' }
    assert_match(/migration filename convention/, error.message)
  end

  # A Postgres config for the boot. The server connection sq:create and sq:drop open is a mock that
  # logs its options and statements; with +reachable: false+ the app database doesn't exist yet.
  def postgres_boot(reachable:)
    log = File.join(@root, 'server.log')
    File.write(File.join(@root, 'config', 'boot.rb'), <<~RUBY)
      require 'padrino-core'
      require 'sequel'
      db = Sequel.connect('sqlite://db/development.db')
      db.opts.update(adapter: 'postgres', host: 'db.internal', port: 5433, user: 'app', database: 'app_db')
      #{"def db.test_connection\n  raise Sequel::DatabaseConnectionError, 'database \"app_db\" does not exist'\nend" unless reachable}
      Sequel::Model.db = db
      server = Sequel.mock(host: 'postgres')
      Sequel.define_singleton_method(:connect) do |opts, &block|
        block.call(server)
        File.write(#{log.inspect}, [opts.values_at(:host, :port, :user, :database).inspect, *server.sqls].join("\n"))
      end
    RUBY
    log
  end

  it 'should leave a database the boot could reach alone, without connecting to the server' do
    log = postgres_boot(reachable: true)
    assert_includes rake('sq:create'), "<= Database 'app_db' already exists"
    refute File.exist?(log)
  end

  it 'should create a database the boot could not reach through Sequel, without the createdb binary' do
    log = postgres_boot(reachable: false)
    assert_includes rake('sq:create', path: empty_bin), '<= sq:create executed'
    assert_equal ['["db.internal", 5433, "app", "postgres"]', %(CREATE DATABASE "app_db" ENCODING 'utf8')], File.readlines(log, chomp: true)
  end

  it 'should load the SQL helpers once' do
    postgres_boot(reachable: false)
    rake 'sq:create'
    refute_match(/already initialized constant/, @stderr)
  end

  it 'should drop a Postgres database through Sequel, without the dropdb binary' do
    log = postgres_boot(reachable: true)
    assert_includes rake('sq:drop', path: empty_bin), '<= sq:drop executed'
    assert_equal ['["db.internal", 5433, "app", "postgres"]', 'DROP DATABASE IF EXISTS "app_db"'], File.readlines(log, chomp: true)
  end

  # A PATH entry that shadows createdb, dropdb and mysql with failing stand-ins, so a task that
  # still shelled out to them would fail.
  def empty_bin
    bin = File.join(@root, 'bin')
    FileUtils.mkdir_p(bin)
    %w[createdb dropdb mysql].each do |client|
      File.write(File.join(bin, client), "#!/bin/sh\nexit 1\n")
      File.chmod(0o755, File.join(bin, client))
    end
    bin
  end

  it 'should drop a SQLite database' do
    rake 'sq:create'
    assert_includes rake('sq:drop'), '<= sq:drop executed'
    refute File.exist?(database)
  end

  # A widgets row in the SQLite database, written with the sqlite3 CLI that sq:dump shells out to.
  def seed_widget
    skip 'sqlite3 CLI not on PATH' unless system('sqlite3 -version', out: File::NULL, err: File::NULL)
    FileUtils.mkdir_p(File.dirname(database))
    system('sqlite3', database, "CREATE TABLE widgets(name TEXT); INSERT INTO widgets VALUES('sprocket');")
  end

  it 'should dump the data to tmp/<env>_dump.sql through db:dump' do
    seed_widget
    rake 'db:dump'
    assert_match(/INSERT INTO widgets VALUES\('sprocket'\)/, File.read(File.join(@root, 'tmp', 'development_dump.sql')))
    refute_match(/already initialized constant/, @stderr)
  end

  it 'should dump the data to FILE when given' do
    seed_widget
    rake 'sq:dump', 'FILE=backups/latest.sql'
    assert_match(/INSERT INTO widgets/, File.read(File.join(@root, 'backups', 'latest.sql')))
  end
end
