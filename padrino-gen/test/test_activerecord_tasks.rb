require_relative 'helper'
require 'open3'
require 'tmpdir'

describe 'ActiveRecord tasks' do
  def setup
    skip 'activerecord is only bundled on MRI' if RUBY_ENGINE == 'jruby'
    @root = Dir.mktmpdir
    FileUtils.mkdir_p(File.join(@root, 'config'))
    FileUtils.mkdir_p(File.join(@root, 'db', 'migrate'))
    File.write(File.join(@root, 'Rakefile'), <<~RUBY)
      require 'padrino-core/cli/rake'
      PadrinoTasks.use(:activerecord)
      PadrinoTasks.init
    RUBY
    File.write(File.join(@root, 'config', 'boot.rb'), <<~RUBY)
      require 'padrino-core'
      require 'active_record'
      ActiveRecord::Base.configurations = { development: { adapter: 'sqlite3', database: Padrino.root('db', 'development.db') } }
      ActiveRecord::Base.establish_connection(:development)
    RUBY
    File.write(File.join(@root, 'db', 'migrate', '001_create_widgets.rb'), <<~RUBY)
      class CreateWidgets < ActiveRecord::Migration[ActiveRecord::Migration.current_version]
        def change
          create_table(:widgets) { |t| t.string :name }
        end
      end
    RUBY
  end

  def teardown
    FileUtils.rm_rf(@root) if @root
  end

  def run_rake(*args)
    libs = %w[padrino-core padrino-gen].flat_map { |name| ['-I', File.expand_path("../../#{name}/lib", __dir__)] }
    env = { 'RACK_ENV' => 'development', 'BUNDLE_GEMFILE' => File.expand_path('../../Gemfile', __dir__) }
    Open3.capture3(env, RbConfig.ruby, *libs, '-e', 'require "rake"; Rake.application.run(ARGV)', *args, chdir: @root)
  end

  def rake(*args)
    out, err, status = run_rake(*args)
    assert status.success?, "rake #{args.join(' ')} failed:\n#{out}\n#{err}"
    [out, err]
  end

  def schema
    File.read(File.join(@root, 'db', 'schema.rb'))
  end

  def database
    File.join(@root, 'db', 'development.db')
  end

  def use_database(path)
    boot = File.join(@root, 'config', 'boot.rb')
    File.write(boot, File.read(boot).sub("Padrino.root('db', 'development.db')", path.inspect))
  end

  it 'should create the database with ar:create, and report it as existing the second time' do
    rake 'ar:create'
    assert File.exist?(database), 'ar:create did not create the database'
    _, err = rake 'ar:create'
    assert_includes err, "#{database} already exists"
  end

  it 'should create and migrate the database in one run, twice' do
    2.times { rake 'ar:create', 'ar:migrate' }
    assert_match(/create_table "widgets"/, schema)
  end

  it 'should exit with an error when ar:create cannot create the database' do
    blocker = File.join(@root, 'blocker')
    File.write(blocker, '')
    use_database(File.join(blocker, 'development.db'))
    boot = File.join(@root, 'config', 'boot.rb')
    File.write(boot, File.read(boot).sub("adapter: 'sqlite3',", "adapter: 'sqlite3', password: 's3cret-pw',"))
    _, err, status = run_rake 'ar:create'
    refute status.success?, "ar:create succeeded:\n#{err}"
    assert_includes err, "Couldn't create database #{File.join(blocker, 'development.db')}"
    refute_includes err, 's3cret-pw'
  end

  it 'should drop a database that does not exist without an error' do
    rake 'ar:create'
    rake 'ar:drop'
    refute File.exist?(database)
    _, err = rake 'ar:drop'
    refute_includes err, "Couldn't drop"
  end

  it 'should exit with an error when ar:drop cannot drop the database' do
    FileUtils.mkdir_p(database)
    _, err, status = run_rake 'ar:drop'
    refute status.success?, "ar:drop succeeded:\n#{err}"
    assert_includes err, "Couldn't drop #{database}"
  end

  # A boot for a server adapter whose connections are faked: connecting to a database named in
  # +missing+ raises NoDatabaseError, and +probe_error+ is what verifying the app's connection raises.
  def fake_server_boot(adapter, missing:, probe_error: nil, create_error: nil)
    File.write(File.join(@root, 'config', 'boot.rb'), <<~RUBY)
      require 'padrino-core'
      require 'active_record'
      ActiveRecord::Base.configurations = { development: { adapter: #{adapter.inspect}, database: 'app_db' } }
      $calls = []
      fake = Object.new
      fake.define_singleton_method(:verify!) do
        raise #{probe_error || 'ActiveRecord::NoDatabaseError'}, 'probe' if #{missing} || #{!probe_error.nil?}
      end
      fake.define_singleton_method(:drop_database) { |name| $calls << [:drop, name] }
      fake.define_singleton_method(:create_database) do |name, *|
        #{create_error ? "raise #{create_error}, 'create'" : '$calls << [:create, name]'}
      end
      ActiveRecord::Base.define_singleton_method(:establish_connection) do |config = nil|
        db = config.is_a?(Hash) ? config[:database] : 'app_db'
        raise ActiveRecord::NoDatabaseError, 'missing' if #{missing} && db == 'app_db' && $verifying.nil?
        $calls << [:connect, db]
      end
      ActiveRecord::Base.define_singleton_method(:connection) { fake }
      at_exit { $stdout.puts "CALLS \#{$calls.inspect}" }
    RUBY
  end

  it 'should drop a missing mysql database without connecting to it' do
    fake_server_boot('mysql2', missing: true)
    out, err = rake 'ar:drop'
    refute_includes err, "Couldn't drop"
    assert_includes out, '[:connect, nil], [:drop, "app_db"]'
  end

  it 'should report why the connection failed when the database turns out to exist' do
    fake_server_boot('postgresql', missing: false, probe_error: 'ActiveRecord::ConnectionNotEstablished',
                                   create_error: 'ActiveRecord::DatabaseAlreadyExists')
    _, err, status = run_rake 'ar:create'
    refute status.success?
    assert_match(/rake aborted!\nActiveRecord::ConnectionNotEstablished: probe/, err)
  end

  it 'should dump the schema after ar:migrate' do
    rake 'ar:migrate'
    assert_match(/create_table "widgets"/, schema)
  end

  it 'should dump the schema after ar:migrate:down and ar:migrate:up' do
    rake 'ar:migrate'
    rake 'ar:migrate:down', 'MIGRATION_VERSION=1'
    refute_match(/create_table "widgets"/, schema)
    rake 'ar:migrate:up', 'MIGRATION_VERSION=1'
    assert_match(/create_table "widgets"/, schema)
  end

  it 'should dump the schema after ar:rollback' do
    rake 'ar:migrate'
    rake 'ar:rollback'
    refute_match(/create_table "widgets"/, schema)
  end

  it 'should append the migrated versions to the structure dump' do
    rake 'ar:migrate'
    rake 'ar:structure:dump'
    structure = File.read(File.join(@root, 'db', 'development_structure.sql'))
    assert_match(/INSERT INTO "schema_migrations" \(version\) VALUES\s*\('1'\)/, structure)
  end
end
