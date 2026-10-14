require_relative 'helper'

describe 'ProjectGenerator' do
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{SecureRandom.hex}"
    `mkdir -p #{@apptmp}`
    stub_static_files
  end

  def teardown
    `rm -rf #{@apptmp}`
    `rm -rf /tmp/project`
  end

  describe 'the project generator' do
    it 'should allow simple generator to run and create base_app with no options' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      assert_dir_exists("#{@apptmp}/sample_project")
      assert_match_in_file(/module SampleProject/, "#{@apptmp}/sample_project/app/app.rb")
      assert_match_in_file(/class App < Padrino::Application/, "#{@apptmp}/sample_project/app/app.rb")
      assert_match_in_file("Padrino.mount('SampleProject::App', app_file: Padrino.root('app/app.rb')).to('/')", "#{@apptmp}/sample_project/config/apps.rb")
      assert_match_in_file('set :protect_from_csrf, Padrino.env != :test', "#{@apptmp}/sample_project/config/apps.rb")
      assert_file_exists("#{@apptmp}/sample_project/config/boot.rb")
      assert_file_exists("#{@apptmp}/sample_project/Rakefile")
      assert_file_exists("#{@apptmp}/sample_project/exe/sample_project")
      assert_file_exists("#{@apptmp}/sample_project/public/favicon.ico")
      assert_dir_exists("#{@apptmp}/sample_project/public/images")
      assert_dir_exists("#{@apptmp}/sample_project/public/javascripts")
      assert_dir_exists("#{@apptmp}/sample_project/public/stylesheets")
      assert_dir_exists("#{@apptmp}/sample_project/app/views")
      assert_dir_exists("#{@apptmp}/sample_project/app/views/layouts")
    end

    it 'should generate a valid name' do
      capture_io { generate(:project, 'project.com', "--root=#{@apptmp}") }
      assert_dir_exists("#{@apptmp}/project.com")
      assert_match_in_file(/module ProjectCom/, "#{@apptmp}/project.com/app/app.rb")
      assert_match_in_file(/class App < Padrino::Application/, "#{@apptmp}/project.com/app/app.rb")
      assert_match_in_file("Padrino.mount('ProjectCom::App', app_file: Padrino.root('app/app.rb')).to('/')", "#{@apptmp}/project.com/config/apps.rb")

      capture_io { generate(:app, 'ws-dci-2011', "--root=#{@apptmp}/project.com") }
      assert_dir_exists("#{@apptmp}/project.com/ws_dci_2011")
      assert_match_in_file(/module ProjectCom/, "#{@apptmp}/project.com/ws_dci_2011/app.rb")
      assert_match_in_file(/class WsDci2011 < Padrino::Application/, "#{@apptmp}/project.com/ws_dci_2011/app.rb")
      assert_match_in_file("Padrino.mount('ProjectCom::WsDci2011', app_file: Padrino.root('ws_dci_2011/app.rb')).to('/ws_dci_2011')", "#{@apptmp}/project.com/config/apps.rb")
    end

    it 'should generate nested path with dashes in name' do
      capture_io { generate(:project, 'sample-project', "--root=#{@apptmp}") }
      assert_dir_exists("#{@apptmp}/sample-project")
      assert_match_in_file(/module SampleProject/, "#{@apptmp}/sample-project/app/app.rb")
      assert_match_in_file(/class App < Padrino::Application/, "#{@apptmp}/sample-project/app/app.rb")
      assert_match_in_file("Padrino.mount('SampleProject::App', app_file: Padrino.root('app/app.rb')).to('/')", "#{@apptmp}/sample-project/config/apps.rb")

      capture_io { generate(:app, 'ws-dci-2011', "--root=#{@apptmp}/sample-project") }
      assert_dir_exists("#{@apptmp}/sample-project/ws_dci_2011")
      assert_match_in_file(/module SampleProject/, "#{@apptmp}/sample-project/ws_dci_2011/app.rb")
      assert_match_in_file(/class WsDci2011 < Padrino::Application/, "#{@apptmp}/sample-project/ws_dci_2011/app.rb")
      assert_match_in_file("Padrino.mount('SampleProject::WsDci2011', app_file: Padrino.root('ws_dci_2011/app.rb')).to('/ws_dci_2011')", "#{@apptmp}/sample-project/config/apps.rb")
    end

    it 'should raise an Error when given invalid constant names' do
      assert_raises(::NameError) { capture_io { generate(:project, '123asdf', "--root=#{@apptmp}") } }
      assert_raises(::NameError) { capture_io { generate(:project, './sample_project', "--root=#{@apptmp}") } }
    end

    it 'should display the right path' do
      out, = capture_io { generate(:project, 'project', '--root=/tmp') }
      assert_dir_exists('/tmp/project')
      assert_match(%r{cd /tmp/project}, out)
    end

    it 'should run bundle install then bundle binstubs --all with --bundle' do
      generator = Padrino::Generators::Project.any_instance
      generator.stubs(:run)
      generator.expects(:run).with('bundle install').once
      generator.expects(:run).with('bundle binstubs --all').once
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--bundle') }
    end

    it 'should tell the user to run bundle binstubs --all without --bundle' do
      out, = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      assert_match(/\$ bundle install && bundle binstubs --all/, out)
      refute_match(/--binstubs/, out)
    end

    it 'should allow specifying alternate application name' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--app=base_app') }
      assert_dir_exists("#{@apptmp}/sample_project")
      assert_match_in_file(/module SampleProject/, "#{@apptmp}/sample_project/app/app.rb")
      assert_match_in_file(/class BaseApp < Padrino::Application/, "#{@apptmp}/sample_project/app/app.rb")
      assert_match_in_file("Padrino.mount('SampleProject::BaseApp', app_file: Padrino.root('app/app.rb')).to('/')", "#{@apptmp}/sample_project/config/apps.rb")
      assert_file_exists("#{@apptmp}/sample_project/config/boot.rb")
      assert_file_exists("#{@apptmp}/sample_project/public/favicon.ico")
    end

    it 'should add database tasks to Rakefile if an ORM is defined' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--app=base_app', '--orm=activerecord') }
      assert_match_in_file('PadrinoTasks.use(:database)', "#{@apptmp}/sample_project/Rakefile")
    end

    it 'should avoid add database tasks on Rakefile if no ORM is specified' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--app=base_app') }
      assert_no_match_in_file('PadrinoTasks.use(:database)', "#{@apptmp}/sample_project/Rakefile")
    end

    it 'should generate lean project' do
      capture_io { generate(:project, 'sample_project', '--lean', "--root=#{@apptmp}") }
      assert_file_exists("#{@apptmp}/sample_project/public/favicon.ico")
      assert_file_exists("#{@apptmp}/sample_project/config/boot.rb")
      assert_no_file_exists("#{@apptmp}/sample_project/app/app.rb")
      assert_no_match_in_file(/Padrino.mount\('SampleProject::App'/, "#{@apptmp}/sample_project/config/apps.rb")
    end

    it 'should generate lean project correctly even if the component is specified' do
      _, err = capture_io { generate(:project, 'sample_project', '--lean', "--root=#{@apptmp}", '--orm=activerecord', '--stylesheet=scss') }
      assert_match('', err)
    end

    it 'should generate tiny skeleton' do
      capture_io { generate(:project, 'sample_project', '--tiny', "--root=#{@apptmp}") }
      assert_dir_exists("#{@apptmp}/sample_project")
      assert_dir_exists("#{@apptmp}/sample_project/app")
      assert_file_exists("#{@apptmp}/sample_project/app/controllers.rb")
      assert_file_exists("#{@apptmp}/sample_project/app/helpers.rb")
      assert_file_exists("#{@apptmp}/sample_project/app/mailers.rb")
      assert_dir_exists("#{@apptmp}/sample_project/public/images")
      assert_dir_exists("#{@apptmp}/sample_project/public/javascripts")
      assert_dir_exists("#{@apptmp}/sample_project/public/stylesheets")
      assert_match_in_file(/:notifier/, "#{@apptmp}/sample_project/app/mailers.rb")
      assert_match_in_file(/module Helper/, "#{@apptmp}/sample_project/app/helpers.rb")
      assert_match_in_file(/helpers Helper/, "#{@apptmp}/sample_project/app/helpers.rb")
      assert_no_file_exists("#{@apptmp}/sample_project/demo/helpers")
      assert_no_file_exists("#{@apptmp}/sample_project/demo/controllers")
    end

    it 'should generate gemspec and special files if gem is expected' do
      capture_io { generate(:project, 'sample_gem', '--gem', "--root=#{@apptmp}") }
      assert_file_exists("#{@apptmp}/sample_gem/sample_gem.gemspec")
      assert_match_in_file(/^gemspec/, "#{@apptmp}/sample_gem/Gemfile")
      assert_match_in_file(/^module SampleGem/, "#{@apptmp}/sample_gem/app/app.rb")
      assert_match_in_file(/class App/, "#{@apptmp}/sample_gem/app/app.rb")
      assert_file_exists("#{@apptmp}/sample_gem/README.md")
      assert_no_file_exists("#{@apptmp}/sample_gem/tmp/.keep")
      assert_no_file_exists("#{@apptmp}/sample_gem/log/.keep")
    end

    it 'should generate gemspec and special files with dashes in name' do
      capture_io { generate(:project, 'sample-gem', '--gem', "--root=#{@apptmp}") }
      assert_file_exists("#{@apptmp}/sample-gem/sample-gem.gemspec")
      assert_file_exists("#{@apptmp}/sample-gem/README.md")
      assert_match_in_file(%r{/lib/sample-gem/version}, "#{@apptmp}/sample-gem/sample-gem.gemspec")
      assert_match_in_file(/"sample-gem"/, "#{@apptmp}/sample-gem/sample-gem.gemspec")
      assert_match_in_file(/SampleGem::VERSION/, "#{@apptmp}/sample-gem/sample-gem.gemspec")
      assert_match_in_file(/^# SampleGem/, "#{@apptmp}/sample-gem/README.md")
      assert_match_in_file(/SampleGem::App/, "#{@apptmp}/sample-gem/README.md")
      assert_match_in_file(/^module SampleGem/, "#{@apptmp}/sample-gem/lib/sample-gem.rb")
      assert_match_in_file(/gem! "sample-gem"/, "#{@apptmp}/sample-gem/lib/sample-gem.rb")
      assert_match_in_file(/^module SampleGem/, "#{@apptmp}/sample-gem/lib/sample-gem/version.rb")
      assert_match_in_file(/^module SampleGem/, "#{@apptmp}/sample-gem/app/app.rb")
      assert_match_in_file(/class App/, "#{@apptmp}/sample-gem/app/app.rb")
    end

    it 'should not create models folder if no orm is chosen' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '--orm=none') }
      assert_no_dir_exists("#{@apptmp}/sample_project/models")
    end

    it 'should not create tests folder if no test framework is chosen' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '--test=none') }
      assert_no_dir_exists("#{@apptmp}/sample_project/test")
    end

    it 'should place app specific names into correct files' do
      capture_io { generate(:project, 'warepedia', "--root=#{@apptmp}", '--script=none') }
      assert_match_in_file(/module Warepedia/m, "#{@apptmp}/warepedia/app/app.rb")
      assert_match_in_file(/class App < Padrino::Application/m, "#{@apptmp}/warepedia/app/app.rb")
      assert_match_in_file("Padrino.mount('Warepedia::App', app_file: Padrino.root('app/app.rb')).to('/')", "#{@apptmp}/warepedia/config/apps.rb")
    end

    it 'should store and apply session_secret' do
      capture_io { generate(:project, 'sample_project', '--tiny', "--root=#{@apptmp}") }
      assert_match_in_file(/set :session_secret, '[0-9A-z]*'/, "#{@apptmp}/sample_project/config/apps.rb")
    end

    it 'should create components file containing options chosen with defaults' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
      assert_equal 'none', components_chosen[:orm]
      assert_equal 'none', components_chosen[:test]
      assert_equal 'none', components_chosen[:mock]
      assert_equal 'none', components_chosen[:script]
      assert_equal 'none', components_chosen[:renderer]
    end

    it 'should create components file containing options chosen' do
      component_options = ['--orm=sequel', '--test=rspec', '--mock=mocha', '--script=prototype', '--renderer=erb', '--stylesheet=less']
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", *component_options) }
      components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
      assert_equal 'sequel', components_chosen[:orm]
      assert_equal 'rspec',      components_chosen[:test]
      assert_equal 'mocha',      components_chosen[:mock]
      assert_equal 'prototype',  components_chosen[:script]
      assert_equal 'erb',        components_chosen[:renderer]
      assert_equal 'less',       components_chosen[:stylesheet]
    end

    it 'should output to log components being applied' do
      component_options = ['--orm=sequel', '--test=rspec', '--mock=mocha', '--script=prototype', '--renderer=erb', '--stylesheet=less']
      out, = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", *component_options) }
      assert_match(/applying.*?sequel.*?orm/, out)
      assert_match(/applying.*?rspec.*?test/, out)
      assert_match(/applying.*?mocha.*?mock/, out)
      assert_match(/applying.*?prototype.*?script/, out)
      assert_match(/applying.*?erb.*?renderer/, out)
      assert_match(/applying.*?less.*?stylesheet/, out)
    end

    it 'should output gem files for base app' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none') }
      assert_match_in_file(/gem 'padrino'/, "#{@apptmp}/sample_project/Gemfile")
    end

    it 'should create .keep files for empty directories that are required for running application' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--stylesheet=sass', '--orm=sequel') }
      assert_file_exists("#{@apptmp}/sample_project/tmp/.keep")
      assert_file_exists("#{@apptmp}/sample_project/log/.keep")
    end

    it 'should allow to pass upcased name as the app name' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--app=API') }
      assert_file_exists("#{@apptmp}/sample_project/app/app.rb")
      assert_match_in_file(/class API < Padrino::Application/, "#{@apptmp}/sample_project/app/app.rb")
    end
  end

  describe 'a generator for mock component' do
    it 'should properly generate for rr and minitest' do
      out, = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--mock=rr', '--test=minitest', '--script=none') }
      assert_match(/applying.*?rr.*?mock/, out)
      assert_match_in_file(/gem 'rr'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/include RR::Adapters::MiniTest/, "#{@apptmp}/sample_project/test/test_config.rb")
    end

    it 'should properly generater for rr and bacon' do
      out, = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--mock=rr', '--test=bacon', '--script=none') }
      assert_match(/applying.*?rr.*?mock/, out)
      assert_match_in_file(/gem 'rr'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/include RR::Adapters::TestUnit/m, "#{@apptmp}/sample_project/test/test_config.rb")
    end

    it 'should properly generate for rr and rspec' do
      out, = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=rspec', '--mock=rr', '--script=none') }
      assert_match(/applying.*?rr.*?mock/, out)
      assert_match_in_file(/gem 'rr', require: false/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/require 'rr'/m, "#{@apptmp}/sample_project/spec/spec_helper.rb")
    end

    it 'should properly generate for mocha and rspec' do
      out, = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=rspec', '--mock=mocha', '--script=none') }
      assert_match(/applying.*?mocha.*?mock/, out)
      assert_match_in_file(/gem 'mocha'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/conf.mock_with :mocha/m, "#{@apptmp}/sample_project/spec/spec_helper.rb")
    end
  end

  describe 'the generator for HTTP server' do
    it 'should properly generate for webrick by default' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      assert_match_in_file(/# Server requirements\ngem 'webrick'\n/, "#{@apptmp}/sample_project/Gemfile")
    end

    it 'should properly generate for puma' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--server=puma') }
      assert_match_in_file(/# Server requirements\ngem 'puma'\n/, "#{@apptmp}/sample_project/Gemfile")
    end

    it 'should properly generate for falcon' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--server=falcon') }
      assert_match_in_file(/# Server requirements\ngem 'falcon', '>= 0.43'\n/, "#{@apptmp}/sample_project/Gemfile")
    end

    it 'should enable fiber concurrency for sequel on falcon' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--server=falcon', '--orm=sequel') }
      assert_match_in_file(/\A# Falcon serves each request in a fiber.*\nSequel\.extension :fiber_concurrency\n\n/, "#{@apptmp}/sample_project/config/database.rb")
    end

    it 'should not enable fiber concurrency for sequel on other servers' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--server=puma', '--orm=sequel') }
      assert_no_match_in_file(/fiber_concurrency/, "#{@apptmp}/sample_project/config/database.rb")
    end

    it 'should enable fiber isolation for activerecord on falcon' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--server=falcon', '--orm=activerecord') }
      assert_match_in_file(/\A# Falcon serves each request in a fiber.*\nActiveSupport::IsolatedExecutionState\.isolation_level = :fiber\n\n/, "#{@apptmp}/sample_project/config/database.rb")
    end

    it 'should not enable fiber isolation for activerecord on other servers' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--server=puma', '--orm=activerecord') }
      assert_no_match_in_file(/isolation_level/, "#{@apptmp}/sample_project/config/database.rb")
    end

    it 'should enable fiber isolation for minirecord on falcon' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--server=falcon', '--orm=minirecord') }
      assert_match_in_file(/\A# Falcon serves each request in a fiber.*\nActiveSupport::IsolatedExecutionState\.isolation_level = :fiber\n\n/, "#{@apptmp}/sample_project/config/database.rb")
    end

    it 'should not enable fiber isolation for minirecord on other servers' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--server=puma', '--orm=minirecord') }
      assert_no_match_in_file(/isolation_level/, "#{@apptmp}/sample_project/config/database.rb")
    end

    it 'should enable fiber isolation for mongoid on falcon' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--server=falcon', '--orm=mongoid') }
      assert_match_in_file(/\A# Falcon serves each request in a fiber(.*\n)+?Mongoid::Config\.isolation_level = :fiber if /, "#{@apptmp}/sample_project/config/database.rb")
    end

    it 'should not enable fiber isolation for mongoid on other servers' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--server=puma', '--orm=mongoid') }
      assert_no_match_in_file(/isolation_level/, "#{@apptmp}/sample_project/config/database.rb")
    end

    it 'should properly generate for thin' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--server=thin') }
      assert_match_in_file(/# Server requirements\ngem 'thin'\n/, "#{@apptmp}/sample_project/Gemfile")
    end

    it 'should properly generate for mongrel' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--server=mongrel') }
      assert_match_in_file(/# Server requirements\ngem 'mongrel'\n/, "#{@apptmp}/sample_project/Gemfile")
    end

    it 'should properly generate for spider-gazelle' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--server=spider-gazelle') }
      assert_match_in_file(/# Server requirements\ngem 'spider-gazelle'\n/, "#{@apptmp}/sample_project/Gemfile")
    end

    it 'should properly generate for trinidad' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--server=trinidad') }
      assert_match_in_file(/# Server requirements\ngem 'trinidad', platform: 'jruby'\n/, "#{@apptmp}/sample_project/Gemfile")
    end
  end

  describe 'the generator for orm components' do
    describe 'for sequel' do
      it 'should properly generate default' do
        @app.send(:undef, :setup_orm) if @app.respond_to?(:setup_orm)
        out, = capture_io { generate(:project, 'project.com', "--root=#{@apptmp}", '--orm=sequel', '--script=none') }
        assert_match(/applying.*?sequel.*?orm/, out)
        assert_match_in_file(/gem 'sequel'/, "#{@apptmp}/project.com/Gemfile")
        assert_match_in_file(/gem 'sqlite3'/, "#{@apptmp}/project.com/Gemfile")
        assert_match_in_file(/Sequel.connect/, "#{@apptmp}/project.com/config/database.rb")
        assert_match_in_file(%r{sqlite://}, "#{@apptmp}/project.com/config/database.rb")
        assert_match_in_file(/project_com/, "#{@apptmp}/project.com/config/database.rb")
      end

      it 'should properly generate mysql (default to mysql2)' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=sequel', '--adapter=mysql') }
        assert_match_in_file(/gem 'mysql2'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(%r{"mysql2://}, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
      end

      it 'should properly generate mysql2' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=sequel', '--adapter=mysql2') }
        assert_match_in_file(/gem 'mysql2'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(%r{"mysql2://}, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
      end

      it 'should properly generate mysql-gem' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=sequel', '--adapter=mysql-gem') }
        assert_match_in_file(/gem 'mysql'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(%r{"mysql://}, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
      end

      it 'should properly generate sqlite3' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=sequel', '--adapter=sqlite') }
        assert_match_in_file(/gem 'sqlite3'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(%r{sqlite://}, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
      end

      it 'should properly generate postgres' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=sequel', '--adapter=postgres') }
        assert_match_in_file(/gem 'pg'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(%r{"postgres://}, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
      end
    end

    describe 'for activerecord' do
      it 'should properly generate default' do
        out, = capture_io { generate(:project, 'project.com', "--root=#{@apptmp}", '--orm=activerecord', '--script=none') }
        assert_match(/applying.*?activerecord.*?orm/, out)
        assert_match_in_file(/gem 'activerecord', '>= 3.1', require: 'active_record'/, "#{@apptmp}/project.com/Gemfile")
        assert_match_in_file(/gem 'sqlite3'/, "#{@apptmp}/project.com/Gemfile")
        assert_match_in_file(/ActiveRecord::Base.establish_connection/, "#{@apptmp}/project.com/config/database.rb")
        assert_match_in_file(/project_com/, "#{@apptmp}/project.com/config/database.rb")
      end

      it 'should properly generate mysql (default to mysql2)' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=activerecord', '--adapter=mysql') }
        assert_match_in_file(/gem 'mysql2'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(/adapter:   'mysql2'/, "#{@apptmp}/sample_project/config/database.rb")
      end

      it 'should properly generate mysql2' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=activerecord', '--adapter=mysql2') }
        assert_match_in_file(/gem 'mysql2'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(/adapter:   'mysql2'/, "#{@apptmp}/sample_project/config/database.rb")
      end

      it 'should properly generate mysql-gem' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=activerecord', '--adapter=mysql-gem') }
        assert_match_in_file(/gem 'mysql', '~> 2.8.1'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(/adapter:   'mysql'/, "#{@apptmp}/sample_project/config/database.rb")
      end

      it 'should properly generate sqlite3' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=activerecord', '--adapter=sqlite') }
        assert_match_in_file(/gem 'sqlite3'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(/sample_project_development.db/, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(/adapter: 'sqlite3'/, "#{@apptmp}/sample_project/config/database.rb")
      end

      it 'should properly generate postgres' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=activerecord', '--adapter=postgres') }
        assert_match_in_file(/gem 'pg'$/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(/adapter:   'postgresql'/, "#{@apptmp}/sample_project/config/database.rb")
      end
    end

    it 'should properly generate for mongoid' do
      out, = capture_io { generate(:project, 'project.com', "--root=#{@apptmp}", '--orm=mongoid', '--script=none') }
      assert_match(/applying.*?mongoid.*?orm/, out)
      assert_match_in_file(/gem 'mongoid'/, "#{@apptmp}/project.com/Gemfile")
      assert_match_in_file(/Mongoid::Config.sessions =/, "#{@apptmp}/project.com/config/database.rb")
    end

    it 'should properly generate for ohm' do
      out, = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=ohm', '--script=none') }
      assert_match(/applying.*?ohm.*?orm/, out)
      assert_match_in_file(/gem 'ohm'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/Ohm.connect/, "#{@apptmp}/sample_project/config/database.rb")
    end

    it 'should properly generate for dynamoid' do
      out, = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=dynamoid', '--script=none') }
      assert_match(/applying.*?dynamoid.*?orm/, out)
      assert_match_in_file(/gem 'aws-sdk'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'dynamoid', '~>0.7.1'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/AWS.config/, "#{@apptmp}/sample_project/config/database.rb")
      assert_match_in_file(/Dynamoid.configure/, "#{@apptmp}/sample_project/config/database.rb")
    end
  end

  describe 'the generator for renderer component' do
    it 'should properly generate for erb' do
      out, = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--renderer=erb', '--script=none') }
      assert_match(/applying.*?erb.*?renderer/, out)
      assert_match_in_file(/gem 'erubi'/, "#{@apptmp}/sample_project/Gemfile")
    end

    it 'should properly generate for haml' do
      out, = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--renderer=haml', '--script=none') }
      assert_match(/applying.*?haml.*?renderer/, out)
      assert_match_in_file(/gem 'haml'/, "#{@apptmp}/sample_project/Gemfile")
    end

    it 'should properly generate for liquid' do
      out, = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--renderer=liquid', '--script=none') }
      assert_match(/applying.*?liquid.*?renderer/, out)
      assert_match_in_file(/gem 'liquid'/, "#{@apptmp}/sample_project/Gemfile")
    end

    it 'should properly generate for slim' do
      out, = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--renderer=slim', '--script=none') }
      assert_match(/applying.*?slim.*?renderer/, out)
      assert_match_in_file(/gem 'slim'/, "#{@apptmp}/sample_project/Gemfile")
    end
  end

  describe 'the generator for script component' do
    it 'should properly generate for jquery' do
      out, = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=jquery') }
      assert_match(/applying.*?jquery.*?script/, out)
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/jquery.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/jquery-ujs.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/application.js")
    end

    it 'should generate jquery with the -s alias' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-s', 'jquery') }
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/jquery.js")
      assert_no_match_in_file(/gem 'jquery'/, "#{@apptmp}/sample_project/Gemfile")
    end

    it 'should point -s with a server name at --server instead of prompting' do
      Padrino::Generators::Project.any_instance.stubs(:ask).raises('prompted for a script')
      error = assert_raises(RuntimeError) { generate(:project, 'sample_project', "--root=#{@apptmp}", '-s', 'puma') }
      assert_match(/--server=puma/, error.message)
      assert_no_dir_exists("#{@apptmp}/sample_project")
    end

    it 'should properly generate for mootools' do
      out, = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=mootools') }
      assert_match(/applying.*?mootools.*?script/, out)
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/mootools.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/mootools-ujs.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/application.js")
    end

    it 'should properly generate for prototype' do
      out, = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=prototype') }
      assert_match(/applying.*?prototype.*?script/, out)
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/protopak.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/lowpro.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/prototype-ujs.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/application.js")
    end

    it 'should properly generate for dojo' do
      out, = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=dojo') }
      assert_match(/applying.*?dojo.*?script/, out)
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/dojo.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/dojo-ujs.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/application.js")
    end

    it 'should properly generate for vite' do
      out, = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=vite') }
      assert_match(/applying.*?vite.*?script/, out)
      assert_match(/vite_javascript_tag 'application'/, out)
      assert_match(/Run `npm install`/, out)
      assert_match(/<%= vite_client_tag %>/, out)
      assert_match_in_file(/gem 'vite_padrino', '~> 3.0'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/^gem 'activesupport', '>= 3.1'$/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(%r{^Bundler\.require\(:default, RACK_ENV\)\nrequire 'active_support/core_ext/object/try'}, "#{@apptmp}/sample_project/config/boot.rb")
      assert_match_in_file(/register VitePadrino/, "#{@apptmp}/sample_project/app/app.rb")
      assert_match_in_file(/"publicOutputDir": "vite-dev"/, "#{@apptmp}/sample_project/config/vite.json")
      assert_match_in_file(/RubyPlugin\(\)/, "#{@apptmp}/sample_project/vite.config.ts")
      assert_match_in_file(/"vite-plugin-ruby"/, "#{@apptmp}/sample_project/package.json")
      assert_equal "web: bundle exec padrino start\nvite: bundle exec vite dev\n", File.read("#{@apptmp}/sample_project/Procfile.dev")
      assert_match_in_file(/ViteRuby.install_tasks/, "#{@apptmp}/sample_project/Rakefile")
      assert_match_in_file(%r{/public/vite\*}, "#{@apptmp}/sample_project/.gitignore")
      assert_file_exists("#{@apptmp}/sample_project/app/frontend/entrypoints/application.js")
    end
  end

  describe 'the generator for test component' do
    it 'should properly generate for bacon' do
      out, = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=bacon', '--script=none') }
      assert_match(/applying.*?bacon.*?test/, out)
      assert_match_in_file(/gem 'rack-test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(%r{require: 'rack/test'}, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/group: 'test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'bacon'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/Bacon::Context/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_match_in_file(/RACK_ENV = 'test' unless defined\?\(RACK_ENV\)/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_file_exists("#{@apptmp}/sample_project/test/test.rake")
      assert_match_in_file(/Rake::TestTask.new\("test:\#/, "#{@apptmp}/sample_project/test/test.rake")
      assert_match_in_file(/task 'test' => test_tasks/, "#{@apptmp}/sample_project/test/test.rake")
    end

    it 'should properly generate for rspec' do
      out, = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=rspec', '--script=none') }
      assert_match(/applying.*?rspec.*?test/, out)
      assert_match_in_file(/gem 'rack-test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(%r{require: 'rack/test'}, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/group: 'test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'rspec'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/RACK_ENV = 'test' unless defined\?\(RACK_ENV\)/, "#{@apptmp}/sample_project/spec/spec_helper.rb")
      assert_match_in_file(/RSpec.configure/, "#{@apptmp}/sample_project/spec/spec_helper.rb")
      assert_file_exists("#{@apptmp}/sample_project/spec/spec.rake")
      assert_match_in_file(/RSpec::Core::RakeTask\.new\("spec:\#/, "#{@apptmp}/sample_project/spec/spec.rake")
      assert_match_in_file(/task 'spec' => spec_tasks/, "#{@apptmp}/sample_project/spec/spec.rake")
    end

    it 'should properly generate for shoulda' do
      out, = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=shoulda', '--script=none') }
      assert_match(/applying.*?shoulda.*?test/, out)
      assert_match_in_file(/gem 'rack-test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(%r{require: 'rack/test'}, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/group: 'test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'shoulda'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/RACK_ENV = 'test' unless defined\?\(RACK_ENV\)/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_match_in_file(/Test::Unit::TestCase/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_file_exists("#{@apptmp}/sample_project/test/test.rake")
      assert_match_in_file(/Rake::TestTask\.new\("test:\#/, "#{@apptmp}/sample_project/test/test.rake")
      assert_match_in_file(/task 'test' => test_tasks/, "#{@apptmp}/sample_project/test/test.rake")
    end

    it 'should properly generate for minitest' do
      out, = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=minitest', '--script=none') }
      assert_match(/applying.*?minitest.*?test/, out)
      assert_match_in_file(/gem 'rack-test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(%r{require: 'rack/test'}, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/group: 'test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'minitest'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/include Rack::Test::Methods/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_match_in_file(/RACK_ENV = 'test' unless defined\?\(RACK_ENV\)/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_match_in_file(/Minitest::Spec/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_match_in_file(/SampleProject::App\.tap/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_file_exists("#{@apptmp}/sample_project/test/test.rake")
      assert_match_in_file(/Rake::TestTask\.new\("test:\#/, "#{@apptmp}/sample_project/test/test.rake")
      assert_match_in_file(/task 'test' => test_tasks/, "#{@apptmp}/sample_project/test/test.rake")
    end # minitest

    it 'should properly generate for cucumber' do
      out, = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=cucumber', '--script=none') }
      assert_match(/applying.*?cucumber.*?test/, out)
      assert_match_in_file(/gem 'rack-test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(%r{require: 'rack/test'}, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/group: 'test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'rspec'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'cucumber'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/RACK_ENV = 'test' unless defined\?\(RACK_ENV\)/, "#{@apptmp}/sample_project/spec/spec_helper.rb")
      assert_match_in_file(/RACK_ENV = 'test' unless defined\?\(RACK_ENV\)/, "#{@apptmp}/sample_project/features/support/env.rb")
      assert_match_in_file(/gem 'capybara'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/RSpec.configure/, "#{@apptmp}/sample_project/spec/spec_helper.rb")
      assert_match_in_file(/Capybara.app = /, "#{@apptmp}/sample_project/features/support/env.rb")
      assert_match_in_file(/World\(Cucumber::Web::URLs\)/, "#{@apptmp}/sample_project/features/support/url.rb")
      assert_file_exists("#{@apptmp}/sample_project/spec/spec.rake")
      assert_match_in_file(/RSpec::Core::RakeTask\.new\("spec:\#/, "#{@apptmp}/sample_project/spec/spec.rake")
      assert_match_in_file(/task 'spec' => spec_tasks/, "#{@apptmp}/sample_project/spec/spec.rake")
      assert_file_exists("#{@apptmp}/sample_project/features/support/env.rb")
      assert_file_exists("#{@apptmp}/sample_project/features/add.feature")
      assert_file_exists("#{@apptmp}/sample_project/features/step_definitions/add_steps.rb")
    end
  end

  describe 'the generator for stylesheet component' do
    it 'should properly generate for sass' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--renderer=haml', '--script=none', '--stylesheet=sass') }
      assert_match_in_file(/gem 'sass'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/module SassInitializer.*Sass::Plugin::Rack/m, "#{@apptmp}/sample_project/config/initializers/sass.rb")
      assert_match_in_file(/register SassInitializer/m, "#{@apptmp}/sample_project/app/app.rb")
      assert_dir_exists("#{@apptmp}/sample_project/app/stylesheets")
    end

    it 'should properly generate for less' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--renderer=haml', '--script=none', '--stylesheet=less') }
      assert_match_in_file(/gem 'rack-less'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/module LessInitializer.*Rack::Less/m, "#{@apptmp}/sample_project/config/initializers/less.rb")
      assert_match_in_file(/register LessInitializer/m, "#{@apptmp}/sample_project/app/app.rb")
      assert_dir_exists("#{@apptmp}/sample_project/app/stylesheets")
    end

    it 'should properly generate for scss' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--renderer=haml', '--script=none', '--stylesheet=scss') }
      assert_match_in_file(/gem 'haml'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/module ScssInitializer.*Sass::Plugin::Rack/m, "#{@apptmp}/sample_project/config/initializers/scss.rb")
      assert_match_in_file(/Sass::Plugin.options\[:syntax\] = :scss/m, "#{@apptmp}/sample_project/config/initializers/scss.rb")
      assert_match_in_file(/register ScssInitializer/m, "#{@apptmp}/sample_project/app/app.rb")
      assert_dir_exists("#{@apptmp}/sample_project/app/stylesheets")
    end

    it 'should properly generate for tailwind' do
      out, = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--renderer=haml', '--script=none', '--stylesheet=tailwind') }
      assert_match(/rake tailwind:build/, out)
      assert_match(%r{layouts/application\.haml\):\n\s*= stylesheet_link_tag 'application'$}, out)
      assert_match_in_file(/gem 'tailwindcss-ruby', '~> 4.0'$/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/@import "tailwindcss";/, "#{@apptmp}/sample_project/app/stylesheets/application.css")
      assert_match_in_file(/task :build.*task :watch/m, "#{@apptmp}/sample_project/tasks/tailwind.rake")
      assert_match_in_file(/namespace :assets do\n\s*task precompile: 'tailwind:build'$/, "#{@apptmp}/sample_project/tasks/tailwind.rake")
      assert_match_in_file(/^web: bundle exec padrino start\ncss: bundle exec rake tailwind:watch$/, "#{@apptmp}/sample_project/Procfile.dev")
      assert_match_in_file(%r{^public/stylesheets/application\.css$}, "#{@apptmp}/sample_project/.gitignore")
    end

    it 'should print an erb link tag for tailwind with erb' do
      out, = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--renderer=erb', '--stylesheet=tailwind') }
      assert_match(%r{layouts/application\.erb\):\n\s*<%= stylesheet_link_tag 'application' %>$}, out)
    end
  end

  describe 'tiny app skeleton generator for test component' do
    it 'should properly generate for rspec' do
      capture_io { generate(:project, 'sample_project', '--tiny', "--root=#{@apptmp}", '--test=rspec') }
      assert_dir_exists("#{@apptmp}/sample_project/spec/")
      assert_file_exists("#{@apptmp}/sample_project/spec/app/controllers/controllers_spec.rb")
      assert_file_exists("#{@apptmp}/sample_project/spec/app/helpers/helpers_spec.rb")
      assert_match_in_file(%r{Dir\[File\.expand_path\("#\{__dir__\}/\.\./app/helpers\.rb"\)\]\.each\(&method\(:require\)\)}, "#{@apptmp}/sample_project/spec/spec_helper.rb")
      assert_match_in_file(/RSpec\.describe "Controller" do/, "#{@apptmp}/sample_project/spec/app/controllers/controllers_spec.rb")
      assert_match_in_file(%r{get "/"}, "#{@apptmp}/sample_project/spec/app/controllers/controllers_spec.rb")
      assert_match_in_file(/RSpec.describe "SampleProject::App::Helper" do/, "#{@apptmp}/sample_project/spec/app/helpers/helpers_spec.rb")
    end

    it 'should properly generate for cucumber' do
      capture_io { generate(:project, 'sample_project', '--tiny', "--root=#{@apptmp}", '--test=cucumber') }
      assert_dir_exists("#{@apptmp}/sample_project/spec/")
      assert_file_exists("#{@apptmp}/sample_project/spec/app/controllers/controllers_spec.rb")
      assert_file_exists("#{@apptmp}/sample_project/spec/app/helpers/helpers_spec.rb")
      assert_match_in_file(%r{Dir\[File\.expand_path\("#\{__dir__\}/\.\./app/helpers\.rb"\)\]\.each\(&method\(:require\)\)}, "#{@apptmp}/sample_project/spec/spec_helper.rb")
      assert_match_in_file(/describe "Controller" do/, "#{@apptmp}/sample_project/spec/app/controllers/controllers_spec.rb")
      assert_match_in_file(/describe "SampleProject::App::Helper" do/, "#{@apptmp}/sample_project/spec/app/helpers/helpers_spec.rb")
    end

    it 'should properly generate for bacon' do
      capture_io { generate(:project, 'sample_project', '--tiny', "--root=#{@apptmp}", '--test=bacon') }
      assert_dir_exists("#{@apptmp}/sample_project/test/")
      assert_file_exists("#{@apptmp}/sample_project/test/app/controllers/controllers_test.rb")
      assert_file_exists("#{@apptmp}/sample_project/test/app/helpers/helpers_test.rb")
      assert_match_in_file(%r{Dir\[File\.expand_path\("#\{__dir__\}/\.\./app/helpers\.rb"\)\]\.each\(&method\(:require\)\)}, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_match_in_file(/describe "Controller" do/, "#{@apptmp}/sample_project/test/app/controllers/controllers_test.rb")
      assert_match_in_file(/describe "SampleProject::App::Helper"/, "#{@apptmp}/sample_project/test/app/helpers/helpers_test.rb")
    end

    it 'should properly generate for minitest' do
      capture_io { generate(:project, 'sample_project', '--tiny', "--root=#{@apptmp}", '--test=minitest') }
      assert_dir_exists("#{@apptmp}/sample_project/test/")
      assert_file_exists("#{@apptmp}/sample_project/test/app/controllers/controllers_test.rb")
      assert_file_exists("#{@apptmp}/sample_project/test/app/helpers/helpers_test.rb")
      assert_match_in_file(%r{Dir\[File\.expand_path\("#\{__dir__\}/\.\./app/helpers\.rb"\)\]\.each\(&method\(:require\)\)}, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_match_in_file(/describe "Controller" do/, "#{@apptmp}/sample_project/test/app/controllers/controllers_test.rb")
      assert_match_in_file(/describe "SampleProject::App::Helper"/, "#{@apptmp}/sample_project/test/app/helpers/helpers_test.rb")
    end

    it 'should properly generate for shoulda' do
      capture_io { generate(:project, 'sample_project', '--tiny', "--root=#{@apptmp}", '--test=shoulda') }
      assert_dir_exists("#{@apptmp}/sample_project/test/")
      assert_file_exists("#{@apptmp}/sample_project/test/app/controllers/controllers_test.rb")
      assert_file_exists("#{@apptmp}/sample_project/test/app/helpers/helpers_test.rb")
      assert_match_in_file(%r{Dir\[File\.expand_path\("#\{__dir__\}/\.\./app/helpers\.rb"\)\]\.each\(&method\(:require\)\)}, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_match_in_file(/class ControllerTest < Test::Unit::TestCase/, "#{@apptmp}/sample_project/test/app/controllers/controllers_test.rb")
      assert_match_in_file(/class SampleProject::App::HelperTest < Test::Unit::TestCase/, "#{@apptmp}/sample_project/test/app/helpers/helpers_test.rb")
    end

    it 'should properly generate for testunit' do
      out, = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=testunit', '--script=none', '--tiny') }
      assert_match(/applying.*?testunit.*?test/, out)
      assert_match_in_file(/gem 'rack-test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(%r{require: 'rack/test'}, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/group: 'test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'test-unit'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/RACK_ENV = 'test' unless defined\?\(RACK_ENV\)/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_file_exists("#{@apptmp}/sample_project/test/test.rake")
      assert_match_in_file(/task 'test' => test_tasks/, "#{@apptmp}/sample_project/test/test.rake")
      assert_match_in_file(%r{Dir\[File\.expand_path\("#\{__dir__\}/\.\./app/helpers\.rb"\)\]\.each\(&method\(:require\)\)}, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_match_in_file(/class ControllerTest < Test::Unit::TestCase/, "#{@apptmp}/sample_project/test/app/controllers/controllers_test.rb")
      assert_match_in_file(/class SampleProject::App::HelperTest < Test::Unit::TestCase/, "#{@apptmp}/sample_project/test/app/helpers/helpers_test.rb")
    end
  end
end
