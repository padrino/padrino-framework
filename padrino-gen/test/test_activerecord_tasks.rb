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
end
