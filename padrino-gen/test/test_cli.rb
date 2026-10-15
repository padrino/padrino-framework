require_relative 'helper'
require 'open3'
require 'padrino-gen/generators/cli'

describe 'Cli' do
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{SecureRandom.hex}"
    `mkdir -p #{@apptmp}`
  end

  def teardown
    `rm -rf #{@apptmp}`
  end

  # Cli#setup reads the generator and its arguments from ARGV.
  def cli(*argv)
    saved = ARGV.dup
    ARGV.replace(argv)
    generate(:cli, "--root=#{@apptmp}")
  ensure
    ARGV.replace(saved)
  end

  describe 'the cli' do
    it 'should fail without arguments' do
      out, = capture_io { assert_equal 1, assert_raises(SystemExit) { cli }.status }
      assert_match(/Please specify generator to use/, out)
    end

    it 'should fail with an unknown generator' do
      out, = capture_io { assert_equal 1, assert_raises(SystemExit) { cli('nosuchgen') }.status }
      assert_match(/Please specify generator to use/, out)
    end

    it 'should list the generators for help' do
      out, = capture_io { cli('help') }
      assert_match(/Please specify generator to use/, out)
    end

    it 'should print the usage and fail when the name is missing' do
      out, = capture_io { assert_equal 1, assert_raises(SystemExit) { cli('model') }.status }
      assert_match(/padrino-gen model \[name\] \[fields\]/, out)
    end

    it 'should print the usage for -h' do
      out, = capture_io { cli('model', '-h') }
      assert_match(/padrino-gen model \[name\] \[fields\]/, out)
    end

    it 'should work correctly if we have a project' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:cli, "--root=#{@apptmp}/sample_project") }.status }
      skip 'Make a great asserition'
    end

    it 'should load the project boot from the project root' do
      caller_dir = File.join(@apptmp, 'elsewhere')
      FileUtils.mkdir_p(caller_dir)
      %w[absolute relative elsewhere/below].each do |name|
        FileUtils.mkdir_p(File.join(@apptmp, name, 'config'))
        File.write(File.join(@apptmp, name, 'Gemfile'), '')
        File.write(File.join(@apptmp, name, 'db.txt'), "#{name} db")
        File.write(File.join(@apptmp, name, 'config/boot.rb'),
                   "$padrino_test_boot = [File.read('db.txt'), File.exist?(ENV['BUNDLE_GEMFILE'])]\n")
      end

      Dir.chdir(caller_dir) do
        roots = { File.join(@apptmp, 'absolute') => 'absolute db', '../relative' => 'relative db', 'below' => 'elsewhere/below db' }
        roots.each do |root, db|
          $padrino_test_boot = nil
          out, = capture_io { Padrino::Generators::Cli.new([], root: root).load_boot }
          assert_equal [db, true], $padrino_test_boot, out
          assert_equal File.realpath(caller_dir), File.realpath(Dir.pwd)
        end
      end
    ensure
      $padrino_test_boot = nil
    end

    it 'should give back the environment variables it sets while loading the project boot' do
      saved = { 'BUNDLE_GEMFILE' => ENV['BUNDLE_GEMFILE'], 'PADRINO_LOG_LEVEL' => ENV['PADRINO_LOG_LEVEL'] }
      ENV['BUNDLE_GEMFILE'] = '/caller/Gemfile'
      ENV['PADRINO_LOG_LEVEL'] = 'production'
      capture_io { Padrino::Generators::Cli.new([], root: @apptmp).load_boot }
      assert_equal '/caller/Gemfile', ENV['BUNDLE_GEMFILE']
      assert_equal 'production', ENV['PADRINO_LOG_LEVEL']

      ENV.delete('BUNDLE_GEMFILE')
      ENV.delete('PADRINO_LOG_LEVEL')
      capture_io { Padrino::Generators::Cli.new([], root: @apptmp).load_boot }
      assert_nil ENV['BUNDLE_GEMFILE']
      assert_nil ENV['PADRINO_LOG_LEVEL']
    ensure
      ENV.update(saved)
    end
  end

  describe 'the executables' do
    def run_bin(bin, *args)
      env = { 'BUNDLE_GEMFILE' => File.expand_path('../../Gemfile', __dir__) }
      out, status = Open3.capture2e(env, RbConfig.ruby, bin, *args, chdir: @apptmp)
      [out, status.exitstatus]
    end

    def padrino_gen(*args)
      run_bin(File.expand_path('../bin/padrino-gen', __dir__), *args)
    end

    def padrino(*args)
      run_bin(File.expand_path('../../padrino-core/bin/padrino', __dir__), *args)
    end

    it 'should exit with status 1 when padrino-gen fails' do
      out, status = padrino_gen('nosuchgen')
      assert_equal 1, status, out
      assert_match(/Please specify generator to use/, out)

      out, status = padrino_gen('controller', 'demo')
      assert_equal 1, status, out
      assert_match(/not at the root/, out)
    end

    it 'should exit with status 1 when the name is missing and 0 for -h' do
      out, status = padrino_gen('model')
      assert_equal 1, status, out
      assert_match(/padrino-gen model \[name\] \[fields\]/, out)

      out, status = padrino_gen('model', '-h')
      assert_equal 0, status, out
      assert_match(/padrino-gen model \[name\] \[fields\]/, out)
    end

    it 'should pass the exit status through padrino g' do
      out, status = padrino('g', 'controller', 'demo')
      assert_equal 1, status, out
      assert_match(/not at the root/, out)

      out, status = padrino('g')
      assert_equal 0, status, out
      assert_match(/Please specify generator to use/, out)
    end

    # Runs with stdin at its end, as in CI or a Dockerfile, and returns stderr and the exit status.
    # The prompt goes through rb-readline from this repository's Gemfile, which isn't frozen-literal safe,
    # so the frozen-literal CI job's flag is kept from the child.
    def run_without_input(bin, *args)
      rubyopt = ENV['RUBYOPT'].to_s.split.grep_v(/frozen.string.literal/).join(' ')
      env = { 'BUNDLE_GEMFILE' => File.expand_path('../../Gemfile', __dir__), 'RUBYOPT' => rubyopt }
      _, err, status = Open3.capture3(env, RbConfig.ruby, bin, *args, stdin_data: '', chdir: @apptmp)
      [err, status.exitstatus]
    end

    def assert_stopped_without_backtrace(message, err, status)
      assert_equal 1, status, err
      assert_includes err.lines.map(&:strip), message
      refute(err.lines.any? { |line| line =~ /\A\s+from \S+:\d+|\((RuntimeError|Thor::Error)\)/ }, err)
    end

    it 'should print only the message when a prompt runs out of input' do
      message = 'No input left to choose a valid --stylesheet; pass one of: sass, scss, tailwind, none'
      padrino_gen_bin = File.expand_path('../bin/padrino-gen', __dir__)
      padrino_bin = File.expand_path('../../padrino-core/bin/padrino', __dir__)

      assert_stopped_without_backtrace(message, *run_without_input(padrino_gen_bin, 'project', 'demo', '-c', 'bogus'))
      assert_stopped_without_backtrace(message, *run_without_input(padrino_bin, 'g', 'project', 'demo', '-c', 'bogus'))
      assert_stopped_without_backtrace('No input left to choose a valid --adapter; pass one of: mysql, mysql2, mysql-gem, postgres, sqlite',
                                       *run_without_input(padrino_gen_bin, 'project', 'demo', '-d', 'sequel', '-a', 'bogus'))
      assert_no_dir_exists("#{@apptmp}/demo")

      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      components = File.read("#{@apptmp}/sample_project/.components")
      assert_stopped_without_backtrace(message, *run_without_input(padrino_bin, 'g', 'component', '-c', 'bogus', '-r', 'sample_project'))
      assert_equal components, File.read("#{@apptmp}/sample_project/.components")
    end
  end
end
