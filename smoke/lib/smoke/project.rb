require 'fileutils'

module Smoke
  # The steps that build and exercise one generated project.
  class Project
    VIEW_EXTENSIONS = { 'erb' => 'erb', 'haml' => 'haml', 'liquid' => 'liquid', 'slim' => 'slim' }.freeze
    # The body the generated controller test for each test component expects from GET /posts. RSpec's
    # placeholders are pending, and a pending example that passes fails the run, so its body differs.
    EXPECTED_BODY = Hash.new('Hello World').merge('bacon' => 'some text', 'rspec' => 'Smoke rspec').freeze
    # Cucumber's sample feature drives a calculator page no project has; a developer replaces it.
    CUCUMBER_SAMPLE = %w[features/add.feature features/step_definitions/add_steps.rb].freeze

    FAILING_TESTS = {
      'minitest' => ['test/app/smoke_failing_test.rb', <<~RUBY],
        require File.expand_path("\#{__dir__}/../test_config.rb")
        describe 'smoke' do
          it('fails on purpose') { assert_equal 1, 2 }
        end
      RUBY
      'testunit' => ['test/app/smoke_failing_test.rb', <<~RUBY],
        require File.expand_path("\#{__dir__}/../test_config.rb")
        class SmokeFailingTest < Test::Unit::TestCase
          def test_fails_on_purpose
            assert_equal 1, 2
          end
        end
      RUBY
      'shoulda' => ['test/app/smoke_failing_test.rb', <<~RUBY],
        require File.expand_path("\#{__dir__}/../test_config.rb")
        class SmokeFailingTest < Test::Unit::TestCase
          should('fail on purpose') { assert_equal 1, 2 }
        end
      RUBY
      'bacon' => ['test/app/smoke_failing_test.rb', <<~RUBY],
        require File.expand_path("\#{__dir__}/../test_config.rb")
        describe 'smoke' do
          it('fails on purpose') { 1.should == 2 }
        end
      RUBY
      'rspec' => ['spec/app/smoke_failing_spec.rb', <<~RUBY],
        require 'spec_helper'
        RSpec.describe 'smoke' do
          it('fails on purpose') { expect(1).to eq 2 }
        end
      RUBY
      'cucumber' => ['features/smoke_failing.feature', <<~FEATURE]
        Feature: Smoke
          Scenario: Fails on purpose
            Then smoke fails on purpose
      FEATURE
    }.freeze
    CUCUMBER_FAILING_STEP = ['features/step_definitions/smoke_failing_steps.rb', <<~RUBY].freeze
      Then('smoke fails on purpose') { raise 'smoke: failing on purpose' }
    RUBY
    CUCUMBER_POSTS = {
      'features/posts.feature' => <<~FEATURE,
        Feature: Posts
          Scenario: List posts
            When I visit the posts page
            Then I see the smoke marker
      FEATURE
      'features/step_definitions/posts_steps.rb' => <<~RUBY
        When('I visit the posts page') { visit '/posts' }
        Then('I see the smoke marker') { expect(page).to have_content('Hello World') }
      RUBY
    }.freeze

    attr_reader :combination, :root, :path

    def initialize(combination, root:)
      @combination = combination
      @root = root
      @path = File.join(root, 'smoke')
    end

    def generate!
      bin = CHECKOUT.join('padrino-gen/bin/padrino-gen').to_s
      cmd = %w[bundle exec ruby] + [bin, 'project', 'smoke'] + combination.generator_flags + ['--dev', '-r', root]
      Shell.run('generate', cmd, chdir: CHECKOUT.to_s, env: { 'BUNDLE_GEMFILE' => CHECKOUT.join('Gemfile').to_s })
    end

    # Point mysql2 projects at the TCP service: the generated config uses a local socket.
    def configure_db!
      return unless combination.adapter == 'mysql2'

      edit('config/database.rb') do |source|
        source.gsub(/,\s*socket:\s*'[^']*'/, '').gsub("host:      'localhost'", "host:      '127.0.0.1'")
              .gsub('mysql2://localhost/', 'mysql2://root@127.0.0.1/')
      end
    end

    def bundle!
      bundle_path = ENV['SMOKE_BUNDLE_PATH']
      run('bundle', %w[bundle config set --local path] + [bundle_path]) if bundle_path
      run('bundle', %w[bundle install])
    end

    # A new project has no migrations; migrating must still succeed (#2424).
    def migrate_empty!
      return unless combination.sql?

      each_env { |env| run('migrate_empty', %w[bundle exec rake db:create db:migrate], env: env) }
    end

    def scaffold!
      padrino('scaffold', %w[g controller posts get:index])
      write("app/views/posts/index.#{VIEW_EXTENSIONS.fetch(combination.renderer)}", view_source)
      edit('app/controllers/posts.rb') { |source| source.sub(/get :index do\s*end/, "get :index do\n    render('posts/index').strip\n  end") }
      fill_in_placeholders
      padrino('scaffold', %w[g model post title:string body:text]) unless combination.orm == 'none'
      padrino('scaffold', %w[g mailer notifier])
    end

    def db_tasks!
      each_env do |env|
        if combination.sql?
          run('db_tasks', %w[bundle exec rake db:migrate], env: env)
        elsif combination.orm == 'mongoid'
          run('db_tasks', %w[bundle exec rake mi:create_indexes], env: env)
        end
      end
    end

    def test_command
      combination.test == 'cucumber' ? %w[bundle exec cucumber] : %w[bundle exec rake]
    end

    # The suite passes, and a failing test makes it exit non-zero (#2423).
    def test_suite!
      return if combination.test == 'none'

      run('test_suite', test_command)
      failing = [FAILING_TESTS.fetch(combination.test)]
      failing << CUCUMBER_FAILING_STEP if combination.test == 'cucumber'
      failing.each { |file, source| write(file, source) }
      begin
        run('test_suite_failing', test_command, expect: :failure)
      ensure
        failing.map(&:first).each { |file| FileUtils.rm_f(File.join(path, file)) }
      end
    end

    def marker
      EXPECTED_BODY[combination.test]
    end

    private

    # Do what a developer does with the generated placeholder tests: give them the code they describe.
    def fill_in_placeholders
      unless combination.test == 'rspec'
        edit('app/helpers/posts_helper.rb') { |source| source.sub('# def simple_helper_method', "def foo; end\n\n      # def simple_helper_method") }
      end
      return unless combination.test == 'cucumber'

      CUCUMBER_SAMPLE.each { |file| FileUtils.rm_f(File.join(path, file)) }
      CUCUMBER_POSTS.each { |file, source| write(file, source) }
    end

    # The test suite runs against its own database, which the project's rake tasks set up like development's.
    def each_env
      %w[development test].each { |env| yield('RACK_ENV' => env) }
    end

    def view_source
      combination.renderer == 'slim' ? "| #{marker}\n" : "#{marker}\n"
    end

    def run(step, cmd, **options)
      Shell.run(step, cmd, chdir: path, **options)
    end

    def padrino(step, args, **options)
      run(step, %w[bundle exec padrino] + args, **options)
    end

    def write(file, source)
      full = File.join(path, file)
      FileUtils.mkdir_p(File.dirname(full))
      File.write(full, source)
    end

    def edit(file)
      full = File.join(path, file)
      File.write(full, yield(File.read(full)))
    end
  end
end
