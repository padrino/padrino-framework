require_relative 'helper'
require 'tmpdir'
require_relative '../lib/padrino-gen/padrino-tasks/sql-helpers'

describe 'SqlHelpers.dump_db' do
  def setup
    @dir = Dir.mktmpdir
    @file = File.join(@dir, 'out', 'dump.sql')
  end

  def teardown
    FileUtils.rm_rf(@dir) if @dir
  end

  def partial
    "#{@file}.#{Process.pid}.tmp"
  end

  def succeed
    Process.expects(:wait2).with(42).returns([42, stub(success?: true)])
    File.expects(:rename).with(partial, @file)
  end

  def dump(adapter, password: nil, host: nil, port: nil, socket: nil, user: nil, database: 'app db')
    config = { adapter: adapter, user: user, password: password, host: host, port: port, socket: socket, database: database }
    Padrino::Generators::SqlHelpers.dump_db(config, @file)
  end

  describe 'postgres' do
    it 'runs pg_dump into a temp file with connection flags, database last' do
      succeed
      Process.expects(:spawn).with({}, 'pg_dump', "--file=#{partial}", '--host=db', '--port=5433', '--username=bob', 'app db', {}).returns(42)
      assert_equal @file, dump('postgres', host: 'db', port: 5433, user: 'bob')
    end

    it 'accepts the ActiveRecord adapter name and a Symbol adapter' do
      succeed
      Process.expects(:spawn).with({}, 'pg_dump', "--file=#{partial}", 'app db', {}).returns(42)
      dump('postgresql')
      succeed
      Process.expects(:spawn).with({}, 'pg_dump', "--file=#{partial}", 'app db', {}).returns(42)
      dump(:postgres)
    end

    it 'passes the password through PGPASSWORD as a String' do
      succeed
      Process.expects(:spawn).with({ 'PGPASSWORD' => '1234' }, 'pg_dump', "--file=#{partial}", 'app db', {}).returns(42)
      dump('postgres', password: 1234)
    end

    it 'does not set PGPASSWORD for a blank password' do
      succeed
      Process.expects(:spawn).with({}, 'pg_dump', "--file=#{partial}", 'app db', {}).returns(42)
      dump('postgres', password: '')
    end
  end

  describe 'mysql' do
    it 'runs mysqldump with result file, socket and MYSQL_PWD, and no host or port for localhost, as mysql2' do
      succeed
      Process.expects(:spawn).with(
        { 'MYSQL_PWD' => 'hunter2' }, 'mysqldump', "--result-file=#{partial}",
        '--user=bob', '--socket=/tmp/mysql.sock', 'app db', {}
      ).returns(42)
      dump('mysql2', password: 'hunter2', user: 'bob', host: 'localhost', port: 3307, socket: '/tmp/mysql.sock')
    end

    it 'passes a remote host and port, and leaves 127.0.0.1 without a port to the client default' do
      succeed
      Process.expects(:spawn).with({}, 'mysqldump', "--result-file=#{partial}", '--host=db', '--port=3307', 'app db', {}).returns(42)
      dump('mysql', host: 'db', port: 3307)
      succeed
      Process.expects(:spawn).with({}, 'mysqldump', "--result-file=#{partial}", 'app db', {}).returns(42)
      dump('mysql', host: '127.0.0.1')
    end
  end

  describe 'sqlite' do
    it 'runs sqlite3 .dump with stdout redirected to the temp file' do
      db = File.join(@dir, 'app.db')
      File.write(db, '')
      succeed
      Process.expects(:spawn).with({}, 'sqlite3', db, '.dump', { out: partial }).returns(42)
      dump('sqlite', database: db)
    end

    it 'raises without spawning when the database file is missing' do
      Process.expects(:spawn).never
      error = assert_raises(RuntimeError) { dump('sqlite3', database: File.join(@dir, 'nope.db')) }
      assert_match(/does not exist/, error.message)
      refute File.exist?(File.dirname(@file))
    end

    it 'dumps real data and creates the missing output directory' do
      skip 'sqlite3 CLI not on PATH' unless system('sqlite3 -version', out: File::NULL, err: File::NULL)
      db = File.join(@dir, 'real.db')
      system('sqlite3', db, "CREATE TABLE widgets(name TEXT); INSERT INTO widgets VALUES('sprocket');")
      assert_equal @file, dump('sqlite3', database: db)
      assert_match(/INSERT INTO widgets VALUES\('sprocket'\)/, File.read(@file))
      assert_empty Dir["#{@file}*.tmp"]
    end
  end

  describe 'failures' do
    it 'raises for an unsupported adapter' do
      Process.expects(:spawn).never
      error = assert_raises(RuntimeError) { dump('jdbc') }
      assert_equal 'Adapter jdbc not supported for dumping databases yet.', error.message
    end

    it 'names the binary when it is not on PATH' do
      Process.expects(:spawn).raises(Errno::ENOENT)
      error = assert_raises(RuntimeError) { dump('postgres') }
      assert_equal 'pg_dump not found on PATH', error.message
    end

    it 'removes the temp file when the sqlite3 binary is missing' do
      db = File.join(@dir, 'app.db')
      File.write(db, '')
      saved_path = ENV['PATH']
      ENV['PATH'] = File.join(@dir, 'empty-bin')
      FileUtils.mkdir_p(ENV['PATH'])
      error = assert_raises(RuntimeError) { dump('sqlite3', database: db) }
      assert_equal 'sqlite3 not found on PATH', error.message
      assert_empty Dir["#{@file}*.tmp"]
    ensure
      ENV['PATH'] = saved_path
    end

    it 'keeps an earlier dump and removes the temp file when the tool fails' do
      FileUtils.mkdir_p(File.dirname(@file))
      File.write(@file, 'previous dump')
      Process.expects(:spawn).with do |*args|
        target = args.grep(String).find { |arg| arg.start_with?('--file=') }.sub('--file=', '')
        File.write(target, 'partial')
        true
      end.returns(42)
      Process.expects(:wait2).with(42).returns([42, stub(success?: false)])
      error = assert_raises(RuntimeError) { dump('postgres') }
      assert_equal 'Error dumping database app db', error.message
      assert_equal 'previous dump', File.read(@file)
      assert_empty Dir["#{@file}*.tmp"]
    end

    it 'removes the temp file when the wait is interrupted' do
      Process.expects(:spawn).with do |*args|
        target = args.grep(String).find { |arg| arg.start_with?('--file=') }.sub('--file=', '')
        File.write(target, 'partial')
        true
      end.returns(42)
      Process.expects(:wait2).with(42).raises(Interrupt)
      Process.expects(:kill).with('TERM', 42)
      Process.expects(:wait).with(42)
      assert_raises(Interrupt) { dump('postgres') }
      assert_empty Dir["#{@file}*.tmp"]
    end

    it 'stops and reaps the dump process when the wait is interrupted' do
      skip 'Thread#raise does not interrupt Process.wait2 reliably on JRuby' if RUBY_ENGINE == 'jruby'
      bin = File.join(@dir, 'bin')
      FileUtils.mkdir_p(bin)
      pid_file = File.join(@dir, 'pg_dump.pid')
      File.write(File.join(bin, 'pg_dump'), "#!/bin/sh\necho $$ > #{pid_file}\nexec sleep 30\n")
      File.chmod(0o755, File.join(bin, 'pg_dump'))
      saved_path = ENV['PATH']
      ENV['PATH'] = "#{bin}#{File::PATH_SEPARATOR}#{saved_path}"
      worker = Thread.new do
        Thread.current.report_on_exception = false
        dump('postgres')
      end
      deadline = Time.now + 10
      sleep 0.05 until (File.size?(pid_file) && worker.status == 'sleep') || !worker.alive? || Time.now > deadline
      assert File.size?(pid_file), 'the dump process never started'
      child = File.read(pid_file).to_i
      worker.raise(Interrupt)
      assert_raises(Interrupt) { worker.join }
      assert_raises(Errno::ESRCH) { Process.kill(0, child) }
      assert_empty Dir["#{@file}*.tmp"]
    ensure
      ENV['PATH'] = saved_path
    end
  end
end
