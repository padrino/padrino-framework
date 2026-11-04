require_relative '../helper'
require 'open3'
require 'tempfile'

describe 'AccountModelGenerator' do
  before do
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{SecureRandom.hex}"
    `mkdir -p #{@apptmp}`
    # An Account left by another test would make g admin keep the model and skip its migration.
    @account_constant = Object.send(:remove_const, :Account) if defined?(Account)
  end

  after do
    `rm -rf #{@apptmp}`
    Object.send(:remove_const, :Account) if defined?(Account)
    Object.const_set(:Account, @account_constant) if @account_constant
  end

  # bcrypt isn't bundled for these tests, so a stand-in BCrypt::Password records each comparison.
  BCRYPT_STAND_IN = <<~RUBY
    module BCrypt
      class Password < String
        COMPARISONS = []

        def self.create(secret)
          new("hashed:\#{secret}")
        end

        def ==(other)
          COMPARISONS << to_s
          super("hashed:\#{other}")
        end
        alias is_password? ==
      end
    end
  RUBY

  # Runs +script+ in a separate process in the generated project, after the BCrypt stand-in.
  def run_in_project(script, env: {}, stdin: '')
    Open3.capture3(*project_command(script, env), chdir: "#{@apptmp}/sample_project", stdin_data: stdin)
  end

  def project_command(script, env)
    env = { 'BUNDLE_GEMFILE' => ENV['BUNDLE_GEMFILE'] || File.expand_path('../../../Gemfile', __dir__) }.merge(env)
    [env, RbConfig.ruby, '-rbundler/setup', '-e', BCRYPT_STAND_IN + script]
  end

  # Runs +script+ like run_in_project, with a stdin that receives +stdin+ and then stays open
  # without an end of file, as under a process manager. Returns the exit status and the output,
  # or nil for the status when the script was still running after +timeout+ seconds, in which
  # case it is killed.
  def run_with_open_stdin(script, env, stdin, timeout: 30)
    reader, writer = IO.pipe
    output = Tempfile.new('padrino-seed')
    pid = Process.spawn(*project_command(script, env), chdir: "#{@apptmp}/sample_project", in: reader, out: output.path, err: %i[child out])
    reader.close
    writer.write(stdin)
    writer.flush
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
    status = nil
    while status.nil? && Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
      _, status = Process.wait2(pid, Process::WNOHANG)
      sleep 0.1 unless status
    end
    [status, File.read(output.path)]
  ensure
    if pid && status.nil?
      Process.kill('KILL', pid)
      Process.wait(pid)
    end
    reader.close if reader && !reader.closed?
    writer.close if writer && !writer.closed?
    output&.close!
  end

  # Loads the generated account model after +setup+ (Ruby code that defines its ORM and the
  # accounts table), and runs +create+ to add one account. Returns, for each case, the account
  # authenticate gives, how many password comparisons it made and whether one of them was
  # against the account's hash.
  def authenticate_results(setup, create)
    script = <<~RUBY
      #{setup}
      load 'models/account.rb'
      #{create}
      {
        'right' => ['Admin@Example.com', 'secret12'],
        'wrong' => ['admin@example.com', 'wrong'],
        'unknown' => ['nobody@example.com', 'secret12'],
        'dummy' => ['nobody@example.com', 'dummy password'],
        'blank' => ['', 'secret12']
      }.each do |name, (email, password)|
        BCrypt::Password::COMPARISONS.clear
        account = Account.authenticate(email, password)
        puts [name, account ? account.email : 'nil', BCrypt::Password::COMPARISONS.size, BCrypt::Password::COMPARISONS.include?('hashed:secret12')].join(' ')
      end
    RUBY
    out, err, status = run_in_project(script)
    assert status.success?, err
    out.lines.to_h { |line| name, *result = line.split; [name, result] }
  end

  # Loads the generated account model after +setup+, saves an account with the email
  # Admin@Example.com, and validates new accounts that differ from a valid one as each case
  # says. An existing account is one that already has a password hash. Returns, for each case,
  # nil when the account is valid, or its error messages.
  def validation_results(setup)
    script = <<~RUBY
      require 'json'
      #{setup}
      load 'models/account.rb'
      attributes = { email: 'Admin@Example.com', role: 'admin', password: 'password', password_confirmation: 'password' }
      Account.new(attributes).save
      {
        'valid' => {},
        'password of 7 bytes' => { password: 'a' * 7 },
        'password of 8 bytes' => { password: 'a' * 8 },
        'password of 72 bytes' => { password: 'a' * 72 },
        'password of 73 bytes' => { password: 'a' * 73 },
        'password of 36 two-byte characters' => { password: "\u00e9" * 36 },
        'password of 37 two-byte characters' => { password: "\u00e9" * 37 },
        'taken email' => { email: 'admin@example.com' },
        'taken email in another case' => { email: 'ADMIN@EXAMPLE.COM' },
        'email with a trailing newline' => { email: "other@example.com\n" },
        'role with a second line' => { role: "admin\nx" },
        'role with an underscore' => { role: 'super_admin' },
        'role with a hyphen' => { role: 'super-admin' },
        'role with a leading space' => { role: ' admin' },
        'existing, no new password' => { existing: true, password: nil },
        'existing, new password of 7 bytes' => { existing: true, password: 'a' * 7 },
        'existing, new password of 73 bytes' => { existing: true, password: 'a' * 73 }
      }.each do |name, changes|
        existing = changes.delete(:existing)
        changes[:password_confirmation] = changes[:password] if changes.key?(:password)
        account = Account.new(attributes.merge(email: 'other@example.com').merge(changes))
        account.crypted_password = 'hashed:password' if existing
        puts JSON.generate([name, account.valid? ? nil : account.errors.full_messages])
      end
    RUBY
    out, err, status = run_in_project(script)
    assert status.success?, err
    out.lines.grep(/\A\[/).to_h { |line| JSON.parse(line) }
  end

  def assert_validates(results, unique_email: true)
    valid = ['valid', 'password of 8 bytes', 'password of 72 bytes', 'password of 36 two-byte characters', 'role with an underscore',
             'role with a hyphen', 'existing, no new password']
    valid.each { |name| assert_nil results.fetch(name), name }
    too_long = /password is too long \(maximum is 72 bytes\)/i
    { 'password of 7 bytes' => /password.*8/i, 'password of 73 bytes' => too_long, 'password of 37 two-byte characters' => too_long,
      'email with a trailing newline' => /email/i, 'role with a second line' => /role/i, 'role with a leading space' => /role/i,
      'existing, new password of 7 bytes' => /password.*8/i, 'existing, new password of 73 bytes' => too_long }.each do |name, message|
      assert_match message, Array(results.fetch(name)).join("\n"), name
    end
    return unless unique_email

    assert_match(/email.*taken/i, Array(results.fetch('taken email')).join("\n"))
    assert_match(/email.*taken/i, Array(results.fetch('taken email in another case')).join("\n"))
  end

  # Runs the generated seeds with +env+ and +stdin+, after +setup+, then again with +rerun_env+
  # merged into the environment when given. Without +tty_answers+ there is no terminal; with
  # them, the seeds run as in a terminal and each question gets the next answer (nil for
  # Ctrl-D). Returns the process status, its error output, the accounts it left (each as its
  # email, whether the password envpassword authenticates and whether the email itself does),
  # its output and how many questions were asked. +patch+ runs after the model loads.
  def seed_results(setup, env, stdin = '', rerun_env: nil, tty_answers: nil, patch: nil)
    env = { 'ADMIN_EMAIL' => nil, 'ADMIN_PASSWORD' => nil }.merge(env)
    out, err, status = run_in_project(seed_script(setup, rerun_env: rerun_env, tty_answers: tty_answers, patch: patch), env: env, stdin: stdin)
    [status, err, out[/^ACCOUNTS (.*)$/, 1].to_s, out, out[/^ASKED (\d+)$/, 1].to_i]
  end

  def seed_script(setup, rerun_env: nil, tty_answers: nil, patch: nil)
    <<~RUBY
      #{setup}
      load 'models/account.rb'
      #{patch}
      require 'thor'
      #{'def $stdin.tty?; true; end' if tty_answers}
      class ScriptedShell < Thor::Base.shell
        ANSWERS = #{tty_answers.inspect}
        ASKED = []

        def ask(statement, *)
          raise 'shell.ask used without a terminal' unless ANSWERS

          ASKED << statement
          ANSWERS.shift
        end
      end

      def shell
        @shell ||= ScriptedShell.new
      end
      at_exit do
        puts "ASKED \#{ScriptedShell::ASKED.size}"
        puts "ACCOUNTS \#{Account.all.map { |a| [a.email, !!Account.authenticate(a.email, 'envpassword'), !!Account.authenticate(a.email, a.email)].join(':') }.join(',')}"
      end
      load 'db/seeds.rb'
      #{"ENV.update(#{rerun_env.inspect})\nload 'db/seeds.rb'" if rerun_env}
    RUBY
  end

  def assert_seeds(setup)
    env = { 'ADMIN_EMAIL' => 'env@example.com', 'ADMIN_PASSWORD' => 'envpassword' }
    created = 'env@example.com:true:false'

    # Piped input gives the email on the first line and the password on the second; a
    # variable that is set and not blank takes the place of its line. Values are stripped.
    { [env, "piped@example.com\npipedpassword\n"] => created,
      [{ 'ADMIN_EMAIL' => 'env@example.com' }, "env@example.com\nenvpassword\n"] => created,
      [{ 'ADMIN_EMAIL' => 'env@example.com' }, "ignored@example.com\nenvpassword\n"] => created,
      [{ 'ADMIN_EMAIL' => 'env@example.com', 'ADMIN_PASSWORD' => '   ' }, "ignored@example.com\nenvpassword\n"] => created,
      [{ 'ADMIN_EMAIL' => '', 'ADMIN_PASSWORD' => 'envpassword' }, "piped@example.com\nignoredpassword\n"] => 'piped@example.com:true:false',
      [{ 'ADMIN_EMAIL' => 'a@b.com ', 'ADMIN_PASSWORD' => ' envpassword ' }, ''] => 'a@b.com:true:false' }.each do |(seed_env, stdin), expected|
      status, err, accounts = seed_results(setup, seed_env, stdin)
      assert status.success?, err
      assert_equal expected, accounts, [seed_env, stdin].inspect
    end

    # Only the lines whose values are used are read, and none past them, so a stdin that stays
    # open without sending more doesn't hold the seeds up. Each case seeds, then seeds again with
    # its changes to the environment, which finds the account and needs no password.
    [
      [env, '', {}],
      [{ 'ADMIN_PASSWORD' => 'envpassword' }, "env@example.com\nENV@example.com\n", {}],
      [{ 'ADMIN_EMAIL' => 'env@example.com' }, "ignored@example.com\nenvpassword\n", {}],
      [env, '', { 'ADMIN_PASSWORD' => '' }],
      [env, "env@example.com\n", { 'ADMIN_EMAIL' => '', 'ADMIN_PASSWORD' => '' }]
    ].each do |seed_env, stdin, rerun_env|
      seed_env = { 'ADMIN_EMAIL' => nil, 'ADMIN_PASSWORD' => nil }.merge(seed_env)
      status, out = run_with_open_stdin(seed_script(setup, rerun_env: rerun_env), seed_env, stdin)
      refute_nil status, "the seeds waited for input with #{[seed_env, stdin, rerun_env].inspect}"
      assert status.success?, out
      assert_match(/successfully created.*already exists; nothing to do/m, out)
      assert_equal created, out[/^ACCOUNTS (.*)$/, 1]
    end

    # Seeding again with the same email, in any case, keeps the account and its password.
    [{ 'ADMIN_PASSWORD' => 'changedpassword' }, { 'ADMIN_EMAIL' => 'ENV@Example.COM', 'ADMIN_PASSWORD' => 'changedpassword' }].each do |rerun_env|
      status, err, accounts, out = seed_results(setup, env, rerun_env: rerun_env)
      assert status.success?, err
      assert_equal created, accounts, rerun_env.inspect
      assert_match(/#{Regexp.escape(rerun_env.fetch('ADMIN_EMAIL', 'env@example.com'))} already exists; nothing to do/, out)
    end

    # In a terminal the password is asked for only when there is no account to keep.
    status, err, accounts, _, asked = seed_results(setup, {}, tty_answers: ['env@example.com', 'envpassword'])
    assert status.success?, err
    assert_equal [created, 2], [accounts, asked]
    status, err, accounts, out, asked = seed_results(setup, env, rerun_env: { 'ADMIN_EMAIL' => '', 'ADMIN_PASSWORD' => '' }, tty_answers: ['ENV@example.com'])
    assert status.success?, err
    assert_equal [created, 1], [accounts, asked]
    assert_match(/already exists; nothing to do/, out)

    # A save that fails stops the seeds like an invalid account.
    status, err, accounts = seed_results(setup, env, patch: "Account.class_eval { def save(*); errors.add(:email, 'could not be saved'); false; end }")
    refute status.success?
    assert_match(/could not be created:\n.*email could not be saved/i, err)
    assert_equal '', accounts

    # The last two cases set nothing and pipe nothing, and end the input at the email question.
    { [env.merge('ADMIN_PASSWORD' => 'short'), nil] => /password.*8/i, [env.merge('ADMIN_EMAIL' => 'not-an-email'), nil] => /email/i,
      [{}, nil] => /email/i, [{}, [nil]] => /email/i }.each do |(seed_env, answers), message|
      status, err, accounts = seed_results(setup, seed_env, tty_answers: answers)
      refute status.success?, seed_env.inspect
      assert_match(/could not be created/, err)
      assert_match message, err
      assert_equal '', accounts
    end
  end

  # mongoid isn't bundled for these tests: a stand-in document gives the model Active Model's
  # validations and callbacks, keeps saved accounts in memory, finds them by exact or Regexp
  # email, and records how email uniqueness and indexes are declared, which need a database to check.
  MONGOID_STAND_IN = <<~RUBY
    require 'active_model'
    require 'active_support/core_ext/object/blank'
    module Mongoid
      module Document
        ACCOUNTS = []
        UNIQUENESS = []
        INDEXES = []

        def self.included(base)
          base.include ActiveModel::Model
          base.extend(ClassMethods)
        end

        def save
          return false unless valid?

          self.class.save_callbacks.each { |name, condition| send(name) if condition.nil? || send(condition) }
          ACCOUNTS << self unless ACCOUNTS.include?(self)
          true
        end

        module ClassMethods
          def field(name, _options = {})
            attr_accessor name
          end

          def validates_uniqueness_of(*args)
            UNIQUENESS << args
          end

          def index(spec, options = {})
            INDEXES << [spec, options]
          end

          def before_save(name, options = {})
            save_callbacks << [name, options[:if]]
          end

          def save_callbacks
            @save_callbacks ||= []
          end

          def where(conditions)
            ACCOUNTS.select { |account| conditions[:email] === account.email }
          end

          def all
            ACCOUNTS
          end
        end
      end
    end
  RUBY

  def assert_authenticates(results)
    assert_equal %w[admin@example.com 1 true], results['right']
    assert_equal %w[nil 1 true], results['wrong']
    # An unknown email still compares the password, against a hash that isn't the account's.
    assert_equal %w[nil 1 false], results['unknown']
    assert_equal %w[nil 1 false], results['dummy']
    assert_equal %w[nil 1 false], results['blank']
  end

  describe 'activerecord' do
    before do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=activerecord') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      @model = "#{@apptmp}/sample_project/models/account.rb"
    end

    it 'should be an activerecord model instance' do
      assert_match_in_file(/class Account < ActiveRecord::Base/m, @model)
    end

    it 'should authenticate, comparing a password hash even when no account matches' do
      skip 'activerecord and sqlite3 are only bundled on MRI' if RUBY_ENGINE == 'jruby'
      setup = <<~RUBY
        require 'active_record'
        ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
        ActiveRecord::Schema.verbose = false
        ActiveRecord::Schema.define do
          create_table(:accounts) { |t| %i[name surname email crypted_password role].each { |column| t.string column } }
        end
      RUBY
      create = "Account.create!(email: 'admin@example.com', role: 'admin', password: 'secret12', password_confirmation: 'secret12')"
      assert_authenticates authenticate_results(setup, create)
    end

    describe 'with the generated migration' do
      # Generated without Active Record loaded, the migration has no version: give it the current one.
      let(:orm_setup) do
        <<~RUBY
          require 'active_record'
          ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
          ActiveRecord::Migration.verbose = false
          migration = File.read(Dir['db/migrate/*_create_accounts.rb'].first)
          eval(migration.sub(/< ActiveRecord::Migration$/, '< ActiveRecord::Migration[ActiveRecord::Migration.current_version]'))
          CreateAccounts.migrate(:up)
        RUBY
      end

      before { skip 'activerecord and sqlite3 are only bundled on MRI' if RUBY_ENGINE == 'jruby' }

      it 'should validate the password length, a unique email and an anchored role' do
        assert_validates validation_results(orm_setup)
      end

      it 'should create a unique index on email' do
        script = <<~RUBY
          #{orm_setup}
          load 'models/account.rb'
          2.times { Account.new(email: 'same@example.com', role: 'admin', crypted_password: 'hashed:password').save(validate: false) }
        RUBY
        _, err, status = run_in_project(script)
        refute status.success?
        assert_match(/RecordNotUnique/, err)
      end

      it 'should seed from ADMIN_EMAIL and ADMIN_PASSWORD and exit non-zero on invalid input' do
        assert_seeds orm_setup
      end
    end
  end

  describe 'mongoid' do
    before do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=mongoid') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      @model = "#{@apptmp}/sample_project/models/account.rb"
    end

    it 'should include the mongoid document' do
      assert_match_in_file(/include Mongoid::Document/m, @model)
    end

    it 'should authenticate, comparing a password hash even when no account matches' do
      skip 'activesupport is only bundled on MRI' if RUBY_ENGINE == 'jruby'
      # mongoid isn't bundled for these tests: a stand-in document keeps accounts in a list
      # and answers the model's case-insensitive email query.
      setup = <<~RUBY
        require 'active_support/core_ext/object/blank'
        module Mongoid
          module Document
            ACCOUNTS = []

            def self.included(base)
              base.extend(ClassMethods)
            end

            module ClassMethods
              def field(name, _options = {})
                attr_accessor name
              end

              def where(conditions)
                ACCOUNTS.select { |account| conditions[:email].match?(account.email) }
              end

              def method_missing(_name, *_args); end

              def respond_to_missing?(_name, _include_private = false)
                true
              end
            end
          end
        end
      RUBY
      create = <<~RUBY
        account = Account.new
        account.email = 'admin@example.com'
        account.password = 'secret12'
        account.send(:encrypt_password)
        Mongoid::Document::ACCOUNTS << account
      RUBY
      assert_authenticates authenticate_results(setup, create)
    end

    it 'should validate the password length, a case-insensitive unique email and an anchored role' do
      skip 'activemodel is only bundled on MRI' if RUBY_ENGINE == 'jruby'
      setup = "#{MONGOID_STAND_IN}\nat_exit { puts JSON.generate(['uniqueness', Mongoid::Document::UNIQUENESS]) }"
      results = validation_results(setup)
      assert_validates results, unique_email: false
      assert_equal [['email', { 'case_sensitive' => false }]], results['uniqueness']
    end

    it 'should declare a unique index on email' do
      skip 'activemodel is only bundled on MRI' if RUBY_ENGINE == 'jruby'
      script = <<~RUBY
        require 'json'
        #{MONGOID_STAND_IN}
        load 'models/account.rb'
        puts "INDEXES \#{JSON.generate(Mongoid::Document::INDEXES)}"
      RUBY
      out, err, status = run_in_project(script)
      assert status.success?, err
      assert_equal [[{ 'email' => 1 }, { 'unique' => true }]], JSON.parse(out[/^INDEXES (.*)$/, 1])
    end

    it 'should seed from ADMIN_EMAIL and ADMIN_PASSWORD and exit non-zero on invalid input' do
      skip 'activemodel is only bundled on MRI' if RUBY_ENGINE == 'jruby'
      assert_seeds MONGOID_STAND_IN
    end
  end

  describe 'sequel' do
    before do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=sequel') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      @model = "#{@apptmp}/sample_project/models/account.rb"
    end

    it 'should be a sequel model instance' do
      assert_match_in_file(/class Account < Sequel::Model/m, @model)
    end

    it 'should authenticate, comparing a password hash even when no account matches' do
      skip 'activesupport and sqlite3 are only bundled on MRI' if RUBY_ENGINE == 'jruby'
      setup = <<~RUBY
        require 'active_support/core_ext/object/blank'
        require 'sequel'
        Sequel.sqlite.create_table(:accounts) do
          primary_key :id
          %i[name surname email crypted_password role].each { |column| String column }
        end
      RUBY
      create = "Account.create(email: 'admin@example.com', role: 'admin', password: 'secret12', password_confirmation: 'secret12')"
      assert_authenticates authenticate_results(setup, create)
    end

    describe 'with the generated migration' do
      let(:orm_setup) do
        <<~RUBY
          require 'active_support/core_ext/object/blank'
          require 'sequel'
          Sequel.extension :migration
          Sequel::Migrator.run(Sequel.sqlite, 'db/migrate')
        RUBY
      end

      before { skip 'activesupport and sqlite3 are only bundled on MRI' if RUBY_ENGINE == 'jruby' }

      it 'should validate the password length, a case-insensitive unique email and an anchored role' do
        assert_validates validation_results(orm_setup)
      end

      it 'should create a unique index on email' do
        script = <<~RUBY
          #{orm_setup}
          load 'models/account.rb'
          2.times { Account.dataset.insert(email: 'same@example.com', role: 'admin', crypted_password: 'hashed:password') }
        RUBY
        _, err, status = run_in_project(script)
        refute status.success?
        assert_match(/UniqueConstraintViolation/, err)
      end

      it 'should seed from ADMIN_EMAIL and ADMIN_PASSWORD and exit non-zero on invalid input' do
        assert_seeds orm_setup
      end
    end
  end

end
