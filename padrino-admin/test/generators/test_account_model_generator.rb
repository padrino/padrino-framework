require_relative '../helper'
require 'open3'

describe 'AccountModelGenerator' do
  before do
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{SecureRandom.hex}"
    `mkdir -p #{@apptmp}`
  end

  after do
    `rm -rf #{@apptmp}`
  end

  # Loads the generated account model in a separate process, after +setup+ (Ruby code that
  # defines its ORM and the accounts table), and runs +create+ to add one account. bcrypt
  # isn't bundled for these tests, so a stand-in BCrypt::Password records each comparison.
  # Returns, for each case, the account authenticate gives, how many password comparisons
  # it made and whether one of them was against the account's hash.
  def authenticate_results(setup, create)
    script = <<~RUBY
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
      #{setup}
      load 'models/account.rb'
      #{create}
      {
        'right' => ['Admin@Example.com', 'secret1'],
        'wrong' => ['admin@example.com', 'wrong'],
        'unknown' => ['nobody@example.com', 'secret1'],
        'dummy' => ['nobody@example.com', 'dummy password'],
        'blank' => ['', 'secret1']
      }.each do |name, (email, password)|
        BCrypt::Password::COMPARISONS.clear
        account = Account.authenticate(email, password)
        puts [name, account ? account.email : 'nil', BCrypt::Password::COMPARISONS.size, BCrypt::Password::COMPARISONS.include?('hashed:secret1')].join(' ')
      end
    RUBY
    env = { 'BUNDLE_GEMFILE' => ENV['BUNDLE_GEMFILE'] || File.expand_path('../../../Gemfile', __dir__) }
    out, err, status = Open3.capture3(env, RbConfig.ruby, '-rbundler/setup', '-e', script, chdir: "#{@apptmp}/sample_project")
    assert status.success?, err
    out.lines.to_h { |line| name, *result = line.split; [name, result] }
  end

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
      create = "Account.create!(email: 'admin@example.com', role: 'admin', password: 'secret1', password_confirmation: 'secret1')"
      assert_authenticates authenticate_results(setup, create)
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
        account.password = 'secret1'
        account.send(:encrypt_password)
        Mongoid::Document::ACCOUNTS << account
      RUBY
      assert_authenticates authenticate_results(setup, create)
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
      create = "Account.create(email: 'admin@example.com', role: 'admin', password: 'secret1', password_confirmation: 'secret1')"
      assert_authenticates authenticate_results(setup, create)
    end
  end

end
