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

  def rake(*args)
    libs = %w[padrino-core padrino-gen].flat_map { |name| ['-I', File.expand_path("../../#{name}/lib", __dir__)] }
    env = { 'RACK_ENV' => 'development', 'BUNDLE_GEMFILE' => File.expand_path('../../Gemfile', __dir__) }
    out, err, status = Open3.capture3(env, RbConfig.ruby, *libs, '-e', 'require "rake"; Rake.application.run(ARGV)', *args, chdir: @root)
    assert status.success?, "rake #{args.join(' ')} failed:\n#{out}\n#{err}"
  end

  def schema
    File.read(File.join(@root, 'db', 'schema.rb'))
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

  def rake_failing(*args)
    libs = %w[padrino-core padrino-gen].flat_map { |name| ['-I', File.expand_path("../../#{name}/lib", __dir__)] }
    env = { 'RACK_ENV' => 'development', 'BUNDLE_GEMFILE' => File.expand_path('../../Gemfile', __dir__) }
    out, err, status = Open3.capture3(env, RbConfig.ruby, *libs, '-e', 'require "rake"; Rake.application.run(ARGV)', *args, chdir: @root)
    refute status.success?, "rake #{args.join(' ')} unexpectedly succeeded:\n#{out}"
    err
  end

  def skip_without_sqlite_cli
    skip 'sqlite3 CLI not on PATH' unless system('sqlite3 -version', out: File::NULL, err: File::NULL)
  end

  it 'should dump the data to tmp/<env>_dump.sql through db:dump' do
    skip_without_sqlite_cli
    rake 'ar:migrate'
    rake 'db:dump'
    dump = File.read(File.join(@root, 'tmp', 'development_dump.sql'))
    assert_match(/CREATE TABLE.*"widgets"/, dump)
    assert_match(/INSERT INTO "?schema_migrations"? VALUES\('1'\)/, dump)
  end

  it 'should pass the TLS settings of the config to the dump tool' do
    File.write(File.join(@root, 'config', 'boot.rb'), <<~RUBY)
      require 'padrino-core'
      require 'active_record'
      ActiveRecord::Base.configurations = { development: {
        adapter: 'postgresql', database: 'app', username: 'bob', sslmode: 'verify-full', sslrootcert: '/ca.pem'
      } }
    RUBY
    bin = File.join(@root, 'bin')
    FileUtils.mkdir_p(bin)
    File.write(File.join(bin, 'pg_dump'), <<~SH)
      #!/bin/sh
      for arg; do case "$arg" in --file=*) file="${arg#--file=}";; esac; done
      echo "$PGSSLMODE $PGSSLROOTCERT $*" > "$file"
    SH
    File.chmod(0o755, File.join(bin, 'pg_dump'))
    saved_path = ENV['PATH']
    ENV['PATH'] = "#{bin}#{File::PATH_SEPARATOR}#{saved_path}"
    rake 'ar:dump'
    assert_match(%r{\Averify-full /ca\.pem .*--username=bob app$}, File.read(File.join(@root, 'tmp', 'development_dump.sql')))
  ensure
    ENV['PATH'] = saved_path if saved_path
  end

  describe 'with two databases in one environment' do
    def setup
      super
      skip_without_sqlite_cli
      File.write(File.join(@root, 'config', 'boot.rb'), <<~RUBY)
        require 'padrino-core'
        require 'active_record'
        ActiveRecord::Base.configurations = { development: {
          primary: { adapter: 'sqlite3', database: Padrino.root('db', 'primary.db') },
          animals: { adapter: 'sqlite3', database: Padrino.root('db', 'animals.db') }
        } }
        ActiveRecord::Base.establish_connection(:development)
      RUBY
      %w[primary animals].each do |name|
        system('sqlite3', File.join(@root, 'db', "#{name}.db"), "CREATE TABLE #{name}_marker(id INTEGER);")
      end
    end

    it 'writes one file per database, named after the config' do
      rake 'ar:dump'
      assert_match(/primary_marker/, File.read(File.join(@root, 'tmp', 'development_primary_dump.sql')))
      assert_match(/animals_marker/, File.read(File.join(@root, 'tmp', 'development_animals_dump.sql')))
    end

    it 'refuses FILE= because the target is ambiguous' do
      err = rake_failing 'ar:dump', 'FILE=one.sql'
      assert_match(/FILE= is ambiguous/, err)
      refute File.exist?(File.join(@root, 'one.sql'))
    end
  end
end
