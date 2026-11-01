require 'fileutils'
require 'net/http'
require 'socket'
require 'yaml'

module Smoke
  # The steps that build and exercise one generated project.
  class Project
    VIEW_EXTENSIONS = { 'erb' => 'erb', 'haml' => 'haml', 'liquid' => 'liquid', 'slim' => 'slim' }.freeze
    # The body of GET /posts. RSpec's placeholders are pending, and a pending example that passes fails
    # the run, so its body differs from the one its placeholder expects.
    EXPECTED_BODY = Hash.new('Hello World').merge('rspec' => 'Smoke rspec').freeze
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
      return if combination.lean?

      padrino('scaffold', %w[g controller posts get:index])
      write("app/views/posts/index.#{VIEW_EXTENSIONS.fetch(combination.renderer)}", view_source)
      # An API project has neither padrino-helpers, which renders views, nor padrino-mailer.
      body = combination.api? ? marker.inspect : "render('posts/index').strip"
      edit('app/controllers/posts.rb') { |source| source.sub(/get :index do\s*end/, "get :index do\n    #{body}\n  end") }
      fill_in_placeholders
      padrino('scaffold', %w[g model post title:string body:text]) unless combination.orm == 'none'
      padrino('scaffold', %w[g mailer notifier]) unless combination.api?
      build_vite if combination.vite?
    end

    def db_tasks!
      each_env do |env|
        if combination.sql?
          run('db_tasks', %w[bundle exec rake db:migrate], env: env)
          run('db_tasks', %w[bundle exec rake db:dump], env: env) if combination.adapter == 'trilogy'
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

    # The admin generator runs only for orms and renderers it supports, and refuses the rest with a message.
    def admin!
      unless combination.admin?
        output = padrino('admin', %w[g admin], expect: :failure)
        raise StepFailed.new('admin', %w[padrino g admin], path, 'backtrace instead of a message', output) if output =~ /\.rb:\d+:in /

        return
      end

      padrino('admin', %w[g admin])
      bundle!
      each_env { |env| run('admin', %w[bundle exec rake db:migrate], env: env) } if combination.sql?
      padrino('admin', %w[g admin_page post])
      output = run('admin', %w[bundle exec rake db:seed], input: "smoke@example.com\nsmokepass1\n")
      raise StepFailed.new('admin', %w[rake db:seed], path, 'no account created', output) unless output.include?('successfully created')
    end

    # The server answers with the rendered view and the admin login redirect, then stops cleanly on TERM (#2395).
    def boot!
      port = free_port
      pid = Shell.spawn(%w[bundle exec padrino start -a] + [combination.server, '-p', port.to_s], chdir: path)
      combination.lean? ? expect_response('boot', port, '/', '404') : expect_response('boot', port, '/posts', '200', marker)
      expect_response('boot', port, '/admin', '302') if combination.admin?
      Process.kill('TERM', pid)
      status = wait_for(pid, 10)
      # Puma re-raises TERM and dies by the signal, which supervisors count as a clean stop.
      stopped = status && (status.success? || status.termsig == Signal.list['TERM'])
      raise StepFailed.new('boot', %w[TERM], path, "server exit #{status.inspect}", server_log) unless stopped
      raise StepFailed.new('boot', %w[TERM], path, 'error logged on shutdown', server_log) if server_log =~ /FATAL|\.rb:\d+:in /
    ensure
      kill(pid)
    end

    # Running the generator again with the same choices leaves an edited project unchanged.
    def rerun_same!
      run('rerun', %w[git init -q])
      run('rerun', %w[git add -A])
      run('rerun', %w[git -c user.email=smoke@example.com -c user.name=smoke commit -q -m base])
      # A test component belongs to an app, so `g component` refuses --test in a project without one.
      flags = combination.lean? ? combination.component_flags.grep_v(/\A--test=/) : combination.component_flags
      padrino('rerun', %w[g component] + flags)
      changes = run('rerun', %w[git status --porcelain])
      raise StepFailed.new('rerun', %w[git status --porcelain], path, 'project changed', changes + run('rerun', %w[git diff])) unless changes.empty?
    end

    # Adding another component to an existing project keeps its test suite working (#2420, #2427).
    def add_component!
      return if combination.add_component.empty?

      flags = combination.add_component.map { |type, value| "--#{type}=#{value}" }
      # Switching a chosen component asks for confirmation once per component.
      padrino('add_component', %w[g component] + flags, input: "yes\n" * flags.size)
      components = YAML.safe_load(File.read(File.join(path, '.components')), permitted_classes: [Symbol])
      combination.add_component.each do |type, value|
        next if components[type.to_sym].to_s == value

        raise StepFailed.new('add_component', %w[padrino g component] + flags, path, "#{type} is #{components[type.to_sym].inspect}, want #{value}", '')
      end
      bundle!
      test_suite!
    end

    def marker
      EXPECTED_BODY[combination.test]
    end

    private

    # The vite component prints the npm install it needs; the build proves its config and entrypoint work.
    def build_vite
      run('vite', %w[npm install])
      run('vite', %w[bundle exec vite build])
    end

    def free_port
      server = TCPServer.new('127.0.0.1', 0)
      server.addr[1]
    ensure
      server&.close
    end

    def expect_response(step, port, url, code, body = nil)
      deadline = Time.now + 60
      begin
        response = Net::HTTP.get_response(URI("http://127.0.0.1:#{port}#{url}"))
      rescue SystemCallError, EOFError, Net::ReadTimeout
        raise StepFailed.new(step, ['GET', url], path, 'server did not answer', server_log) if Time.now > deadline

        sleep 0.5
        retry
      end
      return if response.code == code && (body.nil? || response.body.include?(body))

      raise StepFailed.new(step, ['GET', url], path, "#{response.code} (want #{code}#{" with #{body.inspect}" if body})",
                           "#{response.body}\n--- server log\n#{server_log}")
    end

    def wait_for(pid, seconds)
      deadline = Time.now + seconds
      loop do
        _, status = Process.wait2(pid, Process::WNOHANG)
        return status if status
        return nil if Time.now > deadline

        sleep 0.2
      end
    end

    def kill(pid)
      return unless pid

      Process.kill('KILL', pid)
      Process.wait(pid)
    rescue Errno::ESRCH, Errno::ECHILD
      nil
    end

    def server_log
      File.read(File.join(path, 'log/smoke-server.log'))
    rescue Errno::ENOENT
      ''
    end

    # Do what a developer does with cucumber's sample feature: replace it with one for this project.
    def fill_in_placeholders
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
