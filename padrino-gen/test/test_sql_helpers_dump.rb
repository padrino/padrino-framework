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

  def dump(adapter, password: nil, host: nil, port: nil, socket: nil, user: nil, database: 'app db', **tls)
    config = { adapter: adapter, user: user, password: password, host: host, port: port, socket: socket, database: database }
    Padrino::Generators::SqlHelpers.dump_db(config.merge(tls), @file)
  end

  def sqlite_cli?
    system('sqlite3 -version', out: File::NULL, err: File::NULL)
  end

  # Puts a shell script named +name+ first on PATH for the block.
  def with_binary(name, script)
    saved_path = ENV['PATH']
    bin = File.join(@dir, 'bin')
    FileUtils.mkdir_p(bin)
    File.write(File.join(bin, name), "#!/bin/sh\n#{script}\n")
    File.chmod(0o755, File.join(bin, name))
    ENV['PATH'] = "#{bin}#{File::PATH_SEPARATOR}#{saved_path}"
    yield
  ensure
    ENV['PATH'] = saved_path if saved_path
  end

  def write_earlier_dump
    FileUtils.mkdir_p(File.dirname(@file))
    File.write(@file, 'previous dump')
  end

  def assert_earlier_dump_kept
    assert_equal 'previous dump', File.read(@file)
    assert_empty Dir["#{@file}*.tmp"]
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

    it 'passes the TLS settings through the libpq environment, as Rails does' do
      succeed
      Process.expects(:spawn).with(
        { 'PGSSLMODE' => 'verify-full', 'PGSSLCERT' => '/c.pem', 'PGSSLKEY' => '/k.pem', 'PGSSLROOTCERT' => '/ca.pem' },
        'pg_dump', "--file=#{partial}", 'app db', {}
      ).returns(42)
      dump('postgres', sslmode: :'verify-full', sslcert: '/c.pem', sslkey: '/k.pem', sslrootcert: '/ca.pem')
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

    it 'passes a remote host and port' do
      succeed
      Process.expects(:spawn).with({}, 'mysqldump', "--result-file=#{partial}", '--host=db', '--port=3307', 'app db', {}).returns(42)
      dump('mysql', host: 'db', port: 3307)
    end

    it 'passes 127.0.0.1 without a port as the host, so the client uses TCP as mysql2 does' do
      succeed
      Process.expects(:spawn).with({}, 'mysqldump', "--result-file=#{partial}", '--host=127.0.0.1', 'app db', {}).returns(42)
      dump('mysql', host: '127.0.0.1')
    end

    it 'passes the TLS settings as mysqldump options, as Rails does' do
      succeed
      Process.expects(:spawn).with(
        {}, 'mysqldump', "--result-file=#{partial}", '--ssl-ca=/ca.pem', '--ssl-cert=/c.pem', '--ssl-capath=/certs',
        '--ssl-cipher=AES256-SHA', '--ssl-key=/k.pem', '--ssl-mode=VERIFY_IDENTITY', 'app db', {}
      ).returns(42)
      dump('mysql2', sslca: '/ca.pem', sslcert: '/c.pem', sslkey: '/k.pem', sslcapath: '/certs', sslcipher: 'AES256-SHA',
                     ssl_mode: :VERIFY_IDENTITY)
    end
  end

  describe 'sqlite' do
    it 'runs sqlite3 .dump with a busy timeout, stdout redirected to the temp file and stderr captured' do
      db = File.join(@dir, 'app.db')
      File.write(db, '')
      succeed
      Process.expects(:spawn).with({}, 'sqlite3', '-cmd', '.timeout 5000', db, '.dump', has_entries(out: partial, err: instance_of(File))).returns(42)
      dump('sqlite', database: db)
    end

    # The sqlite3 shell exits 0 after a failed .dump, as with a locked database.
    it 'fails and keeps the earlier dump when sqlite3 reports an error on stderr but exits 0' do
      db = File.join(@dir, 'app.db')
      File.write(db, '')
      write_earlier_dump
      script = "printf 'PRAGMA foreign_keys=OFF;\\nBEGIN TRANSACTION;\\n/**** ERROR: (5) database is locked *****/\\n" \
               "ROLLBACK; -- due to errors\\n'\necho 'sql error: database is locked (5)' >&2"
      with_binary('sqlite3', script) do
        error = assert_raises(RuntimeError) { dump('sqlite3', database: db) }
        assert_equal "Error dumping database #{db}: sql error: database is locked (5)", error.message
      end
      assert_earlier_dump_kept
    end

    it 'fails when the dump ends with the rollback sqlite3 writes after an error, even with nothing on stderr' do
      db = File.join(@dir, 'app.db')
      File.write(db, '')
      write_earlier_dump
      with_binary('sqlite3', "printf 'BEGIN TRANSACTION;\\n/****** CORRUPTION ERROR *******/\\nROLLBACK; -- due to errors\\n'") do
        error = assert_raises(RuntimeError) { dump('sqlite3', database: db) }
        assert_match(/ends with "ROLLBACK; -- due to errors"/, error.message)
      end
      assert_earlier_dump_kept
    end

    it 'includes the sqlite3 error when it exits non-zero' do
      db = File.join(@dir, 'app.db')
      File.write(db, '')
      with_binary('sqlite3', "echo 'Error: unknown option: -cmd' >&2; exit 1") do
        error = assert_raises(RuntimeError) { dump('sqlite3', database: db) }
        assert_equal "Error dumping database #{db}: Error: unknown option: -cmd", error.message
      end
      assert_empty Dir["#{@file}*.tmp"]
    end

    it 'fails and keeps the earlier dump for a file that is not a database' do
      skip 'sqlite3 CLI not on PATH' unless sqlite_cli?
      db = File.join(@dir, 'notes.db')
      File.write(db, 'these are notes, not a database; ' * 10)
      write_earlier_dump
      error = assert_raises(RuntimeError) { dump('sqlite3', database: db) }
      assert_match(/file is not a database/, error.message)
      assert_earlier_dump_kept
    end

    it 'waits for a lock held briefly by another connection' do
      skip 'sqlite3 CLI not on PATH' unless sqlite_cli?
      db = File.join(@dir, 'busy.db')
      system('sqlite3', db, "CREATE TABLE widgets(name TEXT); INSERT INTO widgets VALUES('sprocket');")
      IO.popen(['sqlite3', db], 'r+') do |holder|
        holder.puts "BEGIN EXCLUSIVE; INSERT INTO widgets VALUES('pending');", '.print locked'
        holder.flush
        assert IO.select([holder], nil, nil, 10), 'the lock was never taken'
        assert_equal "locked\n", holder.gets
        releaser = Thread.new do
          sleep 1
          holder.puts 'ROLLBACK;', '.quit'
          holder.flush
        end
        begin
          assert_equal @file, dump('sqlite3', database: db)
        ensure
          releaser.join
        end
      end
      assert_match(/INSERT INTO widgets VALUES\('sprocket'\);\nCOMMIT;\n\z/, File.read(@file))
      refute_match(/pending/, File.read(@file))
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

  describe 'permissions' do
    it 'makes the dump readable by its owner only' do
      skip 'POSIX file modes only' if Gem.win_platform?
      saved_umask = File.umask(0o022)
      with_binary('pg_dump', 'for arg; do case "$arg" in --file=*) echo data > "${arg#--file=}";; esac; done') do
        dump('postgres')
      end
      assert_equal 'data', File.read(@file).strip
      assert_equal 0o600, File.stat(@file).mode & 0o777
    ensure
      File.umask(saved_umask) if saved_umask
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
      ENV['PATH'] = saved_path if saved_path
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

    it 'removes the temp file when a second interrupt arrives while the dump is being stopped' do
      Process.expects(:spawn).with do |*args|
        target = args.grep(String).find { |arg| arg.start_with?('--file=') }.sub('--file=', '')
        File.write(target, 'partial')
        true
      end.returns(42)
      Process.expects(:wait2).with(42).raises(Interrupt)
      Process.expects(:kill).with('TERM', 42)
      Process.expects(:wait).with(42).raises(Interrupt)
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
      ENV['PATH'] = saved_path if saved_path
    end
  end
end
