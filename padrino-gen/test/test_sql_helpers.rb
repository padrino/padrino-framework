require_relative 'helper'
require 'tmpdir'
require_relative '../lib/padrino-gen/padrino-tasks/sql-helpers'

describe 'SqlHelpers' do
  # Puts fake createdb, dropdb and mysql first on PATH. Each records its name, arguments
  # and password variables in a log and exits with FAKE_CLIENT_STATUS.
  def setup
    @bin = Dir.mktmpdir
    @log = File.join(@bin, 'calls.log')
    %w[createdb dropdb mysql].each do |client|
      path = File.join(@bin, client)
      File.write(path, <<~SH)
        #!/bin/sh
        {
          echo "client:#{client}"
          for arg in "$@"; do echo "arg:$arg"; done
          echo "PGPASSWORD:${PGPASSWORD-unset}"
          echo "MYSQL_PWD:${MYSQL_PWD-unset}"
        } >> "#{@log}"
        exit "${FAKE_CLIENT_STATUS:-0}"
      SH
      File.chmod(0o755, path)
    end
    @saved_env = ENV.to_h.slice('PATH', 'PGPASSWORD', 'MYSQL_PWD', 'FAKE_CLIENT_STATUS')
    ENV.delete('PGPASSWORD')
    ENV.delete('MYSQL_PWD')
    ENV['PATH'] = "#{@bin}#{File::PATH_SEPARATOR}#{ENV['PATH']}"
  end

  def teardown
    %w[PATH PGPASSWORD MYSQL_PWD FAKE_CLIENT_STATUS].each { |key| ENV[key] = @saved_env[key] }
    FileUtils.rm_rf(@bin)
  end

  def call
    lines = File.readlines(@log, chomp: true)
    {
      client: lines.grep(/\Aclient:/).map { |line| line.sub('client:', '') },
      args: lines.grep(/\Aarg:/).map { |line| line.sub('arg:', '') },
      env: lines.grep(/\A(PGPASSWORD|MYSQL_PWD):/).to_h { |line| line.split(':', 2) }
    }
  end

  # Passes port: only when given, as callers written before it existed do.
  def create(adapter, password: nil, host: nil, **port)
    Padrino::Generators::SqlHelpers.create_db(adapter, 'admin', password, host, 'app_db', 'utf8', 'utf8_unicode_ci', **port)
  end

  def drop(adapter, password: nil, host: nil, **port)
    Padrino::Generators::SqlHelpers.drop_db(adapter, 'admin', password, host, 'app_db', **port)
  end

  describe 'create_db' do
    describe 'postgres' do
      it 'runs createdb with the host, port, user and database' do
        create('postgres', host: 'db.example', port: 5433)
        assert_equal ['createdb'], call[:client]
        assert_equal ['--encoding=utf8', '--host=db.example', '--port=5433', '--username=admin', 'app_db'], call[:args]
      end

      it 'does not pass a port when none is configured' do
        create('postgres', host: 'db.example')
        refute(call[:args].any? { |arg| arg.start_with?('--port') })
      end

      it 'accepts the postgresql scheme and a Symbol adapter' do
        create('postgresql')
        create(:postgres)
        assert_equal %w[createdb createdb], call[:client]
      end

      it 'does not set PGPASSWORD when password is nil' do
        create('postgres')
        assert_equal 'unset', call[:env]['PGPASSWORD']
      end

      it 'does not set PGPASSWORD when password is blank' do
        create('postgres', password: '')
        assert_equal 'unset', call[:env]['PGPASSWORD']
      end

      it 'sets PGPASSWORD when password is present' do
        create('postgres', password: 'hunter2')
        assert_equal 'hunter2', call[:env]['PGPASSWORD']
        refute_includes call[:args].join(' '), 'hunter2'
      end

      it 'raises when createdb fails' do
        ENV['FAKE_CLIENT_STATUS'] = '1'
        error = assert_raises(RuntimeError) { create('postgres') }
        assert_includes error.message, 'createdb exited with status 1'
        assert_includes error.message, 'app_db'
      end
    end

    describe 'mysql' do
      it 'runs mysql with the host and port' do
        create('mysql2', host: 'db.example', port: 3307)
        assert_equal ['mysql'], call[:client]
        assert_equal ['--user=admin', '--host=db.example', '--port=3307', '-e'], call[:args].first(4)
        assert_equal 'CREATE DATABASE app_db DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_unicode_ci', call[:args].last
      end

      it 'does not pass a port when none is configured' do
        create('mysql', host: 'db.example')
        refute(call[:args].any? { |arg| arg.start_with?('--port') })
      end

      it 'uses the local socket for localhost without a port' do
        create('mysql', host: 'localhost')
        assert_equal ['--user=admin', '-e'], call[:args].first(2)
      end

      it 'passes 127.0.0.1 with a port, which the socket would ignore' do
        create('mysql', host: '127.0.0.1', port: 3307)
        assert_equal ['--user=admin', '--host=127.0.0.1', '--port=3307', '-e'], call[:args].first(4)
      end

      it 'passes only the port when no host is configured, as mysql2 does' do
        create('mysql', port: 3307)
        assert_equal ['--user=admin', '--port=3307', '-e'], call[:args].first(3)
      end

      it 'does not set MYSQL_PWD when password is nil' do
        create('mysql')
        assert_equal 'unset', call[:env]['MYSQL_PWD']
      end

      it 'does not set MYSQL_PWD when password is blank' do
        create('mysql', password: '')
        assert_equal 'unset', call[:env]['MYSQL_PWD']
      end

      it 'sets MYSQL_PWD when password is present' do
        create('mysql', password: 'hunter2')
        assert_equal 'hunter2', call[:env]['MYSQL_PWD']
      end

      it 'raises when mysql fails' do
        ENV['FAKE_CLIENT_STATUS'] = '1'
        error = assert_raises(RuntimeError) { create('mysql') }
        assert_includes error.message, 'mysql exited with status 1'
      end
    end

    describe 'sqlite' do
      %w[sqlite sqlite3].each do |adapter|
        it "creates the #{adapter} file and its directory" do
          database = File.join(@bin, 'db', 'app.db')
          Padrino::Generators::SqlHelpers.create_db(adapter, nil, nil, nil, database, nil, nil)
          assert File.file?(database)
        end

        it "keeps an existing #{adapter} file" do
          database = File.join(@bin, 'app.db')
          File.write(database, 'data')
          Padrino::Generators::SqlHelpers.create_db(adapter, nil, nil, nil, database, nil, nil)
          assert_equal 'data', File.read(database)
        end
      end
    end
  end

  describe 'drop_db' do
    describe 'postgres' do
      it 'runs dropdb with the host, port, user and database' do
        drop('postgres', host: 'db.example', port: 5433)
        assert_equal ['dropdb'], call[:client]
        assert_equal ['--if-exists', '--host=db.example', '--port=5433', '--username=admin', 'app_db'], call[:args]
      end

      it 'does not set PGPASSWORD when password is nil' do
        drop('postgres')
        assert_equal 'unset', call[:env]['PGPASSWORD']
      end

      it 'does not set PGPASSWORD when password is blank' do
        drop('postgres', password: '')
        assert_equal 'unset', call[:env]['PGPASSWORD']
      end

      it 'sets PGPASSWORD when password is present' do
        drop('postgres', password: 'hunter2')
        assert_equal 'hunter2', call[:env]['PGPASSWORD']
      end

      it 'raises when dropdb fails' do
        ENV['FAKE_CLIENT_STATUS'] = '1'
        error = assert_raises(RuntimeError) { drop('postgres') }
        assert_includes error.message, 'dropdb exited with status 1'
      end
    end

    describe 'mysql' do
      it 'runs mysql with the host and port' do
        drop('mysql2', host: 'db.example', port: 3307)
        assert_equal ['--user=admin', '--host=db.example', '--port=3307', '-e', 'DROP DATABASE IF EXISTS app_db'], call[:args]
      end

      it 'does not set MYSQL_PWD when password is nil' do
        drop('mysql')
        assert_equal 'unset', call[:env]['MYSQL_PWD']
      end

      it 'does not set MYSQL_PWD when password is blank' do
        drop('mysql', password: '')
        assert_equal 'unset', call[:env]['MYSQL_PWD']
      end

      it 'sets MYSQL_PWD when password is present' do
        drop('mysql', password: 'hunter2')
        assert_equal 'hunter2', call[:env]['MYSQL_PWD']
      end

      it 'raises when mysql fails' do
        ENV['FAKE_CLIENT_STATUS'] = '1'
        error = assert_raises(RuntimeError) { drop('mysql') }
        assert_includes error.message, 'mysql exited with status 1'
      end
    end

    describe 'sqlite' do
      %w[sqlite sqlite3].each do |adapter|
        it "removes the #{adapter} file" do
          database = File.join(@bin, 'app.db')
          File.write(database, 'data')
          Padrino::Generators::SqlHelpers.drop_db(adapter, nil, nil, nil, database)
          refute File.exist?(database)
        end
      end
    end
  end
end
