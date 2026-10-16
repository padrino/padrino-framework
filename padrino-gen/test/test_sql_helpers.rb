require_relative 'helper'
require 'tmpdir'
require 'sequel'
require_relative '../lib/padrino-gen/padrino-tasks/sql-helpers'

describe 'SqlHelpers' do
  def setup
    @dir = Dir.mktmpdir
    @connections = []
  end

  def teardown
    FileUtils.rm_rf(@dir)
  end

  # Replaces Sequel.connect with one that records its options and yields a mock
  # database of the given type, whose sqls lists the statements run on it.
  # Connecting to a database listed in +refuse+ raises, as a server that denies it would.
  def with_server(type, refuse: [])
    server = Sequel.mock(host: type)
    connections = @connections
    original = Sequel.method(:connect)
    Sequel.define_singleton_method(:connect) do |opts, &block|
      connections << opts
      raise Sequel::DatabaseConnectionError, "no access to #{opts[:database]}" if refuse.include?(opts[:database])

      block ? block.call(server) : server
    end
    yield
    server.sqls
  ensure
    Sequel.define_singleton_method(:connect, original)
  end

  def config(adapter, **opts)
    { adapter: adapter, host: 'db.example', port: 5433, user: 'admin', password: 'hunter2', database: 'app_db',
      uri: "#{adapter}://admin:hunter2@db.example:5433/app_db" }.merge(opts)
  end

  def create(config)
    Padrino::Generators::SqlHelpers.create_db(config, 'utf8', 'utf8_unicode_ci')
  end

  def drop(config)
    Padrino::Generators::SqlHelpers.drop_db(config)
  end

  describe 'create_db' do
    describe 'postgres' do
      it 'creates the database over a connection to the postgres database' do
        sqls = with_server('postgres') { create(config('postgres')) }
        assert_equal [%(CREATE DATABASE "app_db" ENCODING 'utf8')], sqls
        assert_equal 'postgres', @connections.first[:database]
      end

      it 'connects with the app connection settings' do
        with_server('postgres') { create(config('postgres', sslmode: 'require')) }
        connection = @connections.first
        assert_equal ['postgres', 'db.example', 5433, 'admin', 'hunter2', 'require'],
                     connection.values_at(:adapter, :host, :port, :user, :password, :sslmode)
        refute connection.key?(:uri)
      end

      it 'falls back to template1 when the postgres database refuses the connection, as createdb does' do
        sqls = with_server('postgres', refuse: ['postgres']) { create(config('postgres')) }
        assert_equal [%(CREATE DATABASE "app_db" ENCODING 'utf8')], sqls
        assert_equal(%w[postgres template1], @connections.map { |connection| connection[:database] })
      end

      it 'raises when template1 refuses the connection too' do
        with_server('postgres', refuse: %w[postgres template1]) do
          assert_raises(Sequel::DatabaseConnectionError) { create(config('postgres')) }
        end
      end

      it 'leaves out the app connection callbacks, which expect the app database' do
        app_hooks = { after_connect: proc {}, connect_sqls: ['SELECT * FROM widgets'], extensions: [:pg_enum],
                      preconnect: true, servers: { read_only: {} } }
        with_server('postgres') { create(config('postgres', **app_hooks)) }
        assert_empty @connections.first.keys & app_hooks.keys
      end

      it 'accepts the postgresql scheme and a Symbol adapter' do
        sqls = with_server('postgres') do
          create(config('postgresql'))
          create(config(:postgres))
        end
        assert_equal 2, sqls.grep(/\ACREATE DATABASE/).size
      end

      it 'quotes the database name' do
        sqls = with_server('postgres') { create(config('postgres', database: 'my"app db')) }
        assert_equal [%(CREATE DATABASE "my""app db" ENCODING 'utf8')], sqls
      end
    end

    describe 'mysql' do
      it 'creates the database over a connection to no database' do
        sqls = with_server('mysql') { create(config('mysql2')) }
        assert_equal ["CREATE DATABASE `app_db` DEFAULT CHARACTER SET 'utf8' DEFAULT COLLATE 'utf8_unicode_ci'"], sqls
        assert @connections.first.key?(:database)
        assert_nil @connections.first[:database]
      end

      it 'connects with the app connection settings' do
        with_server('mysql') { create(config('mysql', socket: '/run/mysqld/mysqld.sock')) }
        assert_equal ['mysql', 'db.example', 5433, 'admin', 'hunter2', '/run/mysqld/mysqld.sock'],
                     @connections.first.values_at(:adapter, :host, :port, :user, :password, :socket)
      end

      it 'quotes the database name' do
        sqls = with_server('mysql') { create(config('mysql2', database: 'my`app')) }
        assert_equal ["CREATE DATABASE `my``app` DEFAULT CHARACTER SET 'utf8' DEFAULT COLLATE 'utf8_unicode_ci'"], sqls
      end
    end

    describe 'sqlite' do
      %w[sqlite sqlite3].each do |adapter|
        it "creates the #{adapter} file and its directory" do
          database = File.join(@dir, 'db', 'app.db')
          create(adapter: adapter, database: database)
          assert File.file?(database)
        end

        it "keeps an existing #{adapter} file" do
          database = File.join(@dir, 'app.db')
          File.write(database, 'data')
          create(adapter: adapter, database: database)
          assert_equal 'data', File.read(database)
        end
      end
    end

    it 'raises for an adapter it does not support' do
      error = assert_raises(RuntimeError) { create(config('oracle')) }
      assert_includes error.message, 'oracle'
    end
  end

  describe 'drop_db' do
    it 'drops a postgres database over a connection to the postgres database' do
      sqls = with_server('postgres') { drop(config('postgres')) }
      assert_equal ['DROP DATABASE IF EXISTS "app_db"'], sqls
      assert_equal 'postgres', @connections.first[:database]
    end

    it 'falls back to template1 to drop a postgres database, as dropdb does' do
      sqls = with_server('postgres', refuse: ['postgres']) { drop(config('postgres')) }
      assert_equal ['DROP DATABASE IF EXISTS "app_db"'], sqls
      assert_equal 'template1', @connections.last[:database]
    end

    it 'drops a postgres database named postgres over a connection to template1, as dropdb does' do
      sqls = with_server('postgres') { drop(config('postgres', database: 'postgres')) }
      assert_equal ['DROP DATABASE IF EXISTS "postgres"'], sqls
      assert_equal(%w[template1], @connections.map { |connection| connection[:database] })
    end

    it 'drops a mysql database over a connection to no database' do
      sqls = with_server('mysql') { drop(config('mysql2')) }
      assert_equal ['DROP DATABASE IF EXISTS `app_db`'], sqls
      assert_nil @connections.first[:database]
    end

    %w[sqlite sqlite3].each do |adapter|
      it "removes the #{adapter} file" do
        database = File.join(@dir, 'app.db')
        File.write(database, 'data')
        drop(adapter: adapter, database: database)
        refute File.exist?(database)
      end
    end

    it 'raises for an adapter it does not support' do
      error = assert_raises(RuntimeError) { drop(config('oracle')) }
      assert_includes error.message, 'oracle'
    end
  end
end
