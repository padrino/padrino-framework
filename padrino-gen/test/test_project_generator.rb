require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "ProjectGenerator" do
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{UUID.new.generate}"
    `mkdir -p #{@apptmp}`
  end

  def teardown
    `rm -rf #{@apptmp}`
    `rm -rf /tmp/project`
  end

  context 'the project generator' do
    should "allow simple generator to run and create base_app with no options" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      assert_file_exists("#{@apptmp}/sample_project")
      assert_match_in_file(/module SampleProject/,"#{@apptmp}/sample_project/app/app.rb")
      assert_match_in_file(/class App < Padrino::Application/,"#{@apptmp}/sample_project/app/app.rb")
      assert_match_in_file("Padrino.mount('SampleProject::App', :app_file => Padrino.root('app/app.rb')).to('/')", "#{@apptmp}/sample_project/config/apps.rb")
      assert_file_exists("#{@apptmp}/sample_project/config/boot.rb")
      assert_file_exists("#{@apptmp}/sample_project/Rakefile")
      assert_file_exists("#{@apptmp}/sample_project/public/favicon.ico")
      assert_dir_exists("#{@apptmp}/sample_project/public/images")
      assert_dir_exists("#{@apptmp}/sample_project/public/javascripts")
      assert_dir_exists("#{@apptmp}/sample_project/public/stylesheets")
      assert_dir_exists("#{@apptmp}/sample_project/app/views")
      assert_dir_exists("#{@apptmp}/sample_project/app/views/layouts")
    end

    should "generate a valid name" do
      capture_io { generate(:project, 'project.com', "--root=#{@apptmp}") }
      assert_file_exists("#{@apptmp}/project.com")
      assert_match_in_file(/module ProjectCom/,  "#{@apptmp}/project.com/app/app.rb")
      assert_match_in_file(/class App < Padrino::Application/,  "#{@apptmp}/project.com/app/app.rb")
      assert_match_in_file("Padrino.mount('ProjectCom::App', :app_file => Padrino.root('app/app.rb')).to('/')", "#{@apptmp}/project.com/config/apps.rb")
      capture_io { generate(:app, 'ws-dci-2011', "--root=#{@apptmp}/project.com") }
      assert_file_exists("#{@apptmp}/project.com/ws_dci_2011")
      assert_match_in_file(/module ProjectCom/,  "#{@apptmp}/project.com/ws_dci_2011/app.rb")
      assert_match_in_file(/class WsDci2011 < Padrino::Application/,  "#{@apptmp}/project.com/ws_dci_2011/app.rb")
      assert_match_in_file("Padrino.mount('ProjectCom::WsDci2011', :app_file => Padrino.root('ws_dci_2011/app.rb')).to('/ws_dci_2011')", "#{@apptmp}/project.com/config/apps.rb")
    end

    should "generate nested path with dashes in name" do
      capture_io { generate(:project, 'sample-project', "--root=#{@apptmp}") }
      assert_file_exists("#{@apptmp}/sample-project")
      assert_match_in_file(/module SampleProject/,  "#{@apptmp}/sample-project/app/app.rb")
      assert_match_in_file(/class App < Padrino::Application/,  "#{@apptmp}/sample-project/app/app.rb")
      assert_match_in_file("Padrino.mount('SampleProject::App', :app_file => Padrino.root('app/app.rb')).to('/')", "#{@apptmp}/sample-project/config/apps.rb")
      capture_io { generate(:app, 'ws-dci-2011', "--root=#{@apptmp}/sample-project") }
      assert_file_exists("#{@apptmp}/sample-project/ws_dci_2011")
      assert_match_in_file(/module SampleProject/,  "#{@apptmp}/sample-project/ws_dci_2011/app.rb")
      assert_match_in_file(/class WsDci2011 < Padrino::Application/,  "#{@apptmp}/sample-project/ws_dci_2011/app.rb")
      assert_match_in_file("Padrino.mount('SampleProject::WsDci2011', :app_file => Padrino.root('ws_dci_2011/app.rb')).to('/ws_dci_2011')", "#{@apptmp}/sample-project/config/apps.rb")
    end

    should "raise an Error when given invalid constant names" do
      assert_raises(::NameError) { capture_io { generate(:project, "123asdf", "--root=#{@apptmp}") } }
      assert_raises(::NameError) { capture_io { generate(:project, "./sample_project", "--root=#{@apptmp}") } }
    end

    should "display the right path" do
      out, err = capture_io { generate(:project, 'project', "--root=/tmp") }
      assert_file_exists("/tmp/project")
      assert_match(/cd \/tmp\/project/, out)
    end

    should "allow specifying alternate application name" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--app=base_app') }
      assert_file_exists("#{@apptmp}/sample_project")
      assert_match_in_file(/module SampleProject/,"#{@apptmp}/sample_project/app/app.rb")
      assert_match_in_file(/class BaseApp < Padrino::Application/,"#{@apptmp}/sample_project/app/app.rb")
      assert_match_in_file("Padrino.mount('SampleProject::BaseApp', :app_file => Padrino.root('app/app.rb')).to('/')", "#{@apptmp}/sample_project/config/apps.rb")
      assert_file_exists("#{@apptmp}/sample_project/config/boot.rb")
      assert_file_exists("#{@apptmp}/sample_project/public/favicon.ico")
    end

    should "add database's tasks to Rakefile if an ORM is defined" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--app=base_app', '--orm=activerecord') }
      assert_match_in_file('PadrinoTasks.use(:database)',"#{@apptmp}/sample_project/Rakefile")
    end

    should "avoid add database's tasks on Rakefile if no ORM is specified" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--app=base_app') }
      assert_no_match_in_file('PadrinoTasks.use(:database)',"#{@apptmp}/sample_project/Rakefile")
    end

    should "generate tiny skeleton" do
      capture_io { generate(:project,'sample_project', '--tiny',"--root=#{@apptmp}") }
      assert_file_exists("#{@apptmp}/sample_project")
      assert_file_exists("#{@apptmp}/sample_project/app")
      assert_file_exists("#{@apptmp}/sample_project/app/controllers.rb")
      assert_file_exists("#{@apptmp}/sample_project/app/helpers.rb")
      assert_file_exists("#{@apptmp}/sample_project/app/mailers.rb")
      assert_dir_exists("#{@apptmp}/sample_project/public/images")
      assert_dir_exists("#{@apptmp}/sample_project/public/javascripts")
      assert_dir_exists("#{@apptmp}/sample_project/public/stylesheets")
      assert_match_in_file(/:notifier/,"#{@apptmp}/sample_project/app/mailers.rb")
      assert_no_file_exists("#{@apptmp}/sample_project/demo/helpers")
      assert_no_file_exists("#{@apptmp}/sample_project/demo/controllers")
    end

    should "generate gemspec and special files if gem is expected" do
      capture_io { generate(:project,'sample_gem', '--gem', "--root=#{@apptmp}") }
      assert_file_exists("#{@apptmp}/sample_gem/sample_gem.gemspec")
      assert_match_in_file(/^gemspec/,"#{@apptmp}/sample_gem/Gemfile")
      assert_match_in_file(/^module SampleGem/,"#{@apptmp}/sample_gem/app/app.rb")
      assert_match_in_file(/class App/,"#{@apptmp}/sample_gem/app/app.rb")
      assert_file_exists("#{@apptmp}/sample_gem/README.md")
    end

    should "generate gemspec and special files with dashes in name" do
      capture_io { generate(:project,'sample-gem', '--gem', "--root=#{@apptmp}") }
      assert_file_exists("#{@apptmp}/sample-gem/sample-gem.gemspec")
      assert_file_exists("#{@apptmp}/sample-gem/README.md")
      assert_match_in_file(/\/lib\/sample-gem\/version/,"#{@apptmp}/sample-gem/sample-gem.gemspec")
      assert_match_in_file(/"sample-gem"/,"#{@apptmp}/sample-gem/sample-gem.gemspec")
      assert_match_in_file(/SampleGem::VERSION/,"#{@apptmp}/sample-gem/sample-gem.gemspec")
      assert_match_in_file(/^# SampleGem/,"#{@apptmp}/sample-gem/README.md")
      assert_match_in_file(/SampleGem::App/,"#{@apptmp}/sample-gem/README.md")
      assert_match_in_file(/^module SampleGem/,"#{@apptmp}/sample-gem/lib/sample-gem.rb")
      assert_match_in_file(/gem! "sample-gem"/,"#{@apptmp}/sample-gem/lib/sample-gem.rb")
      assert_match_in_file(/^module SampleGem/,"#{@apptmp}/sample-gem/lib/sample-gem/version.rb")
      assert_match_in_file(/^module SampleGem/,"#{@apptmp}/sample-gem/app/app.rb")
      assert_match_in_file(/class App/,"#{@apptmp}/sample-gem/app/app.rb")
    end

    should "not create models folder if no orm is chosen" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '--orm=none') }
      assert_no_dir_exists("#{@apptmp}/sample_project/models")
    end

    should "not create tests folder if no test framework is chosen" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '--test=none') }
      assert_no_dir_exists("#{@apptmp}/sample_project/test")
    end

    should "place app specific names into correct files" do
      capture_io { generate(:project, 'warepedia', "--root=#{@apptmp}", '--script=none') }
      assert_match_in_file(/module Warepedia/m, "#{@apptmp}/warepedia/app/app.rb")
      assert_match_in_file(/class App < Padrino::Application/m, "#{@apptmp}/warepedia/app/app.rb")
      assert_match_in_file("Padrino.mount('Warepedia::App', :app_file => Padrino.root('app/app.rb')).to('/')", "#{@apptmp}/warepedia/config/apps.rb")
    end

    should "store and apply session_secret" do
      capture_io { generate(:project,'sample_project', '--tiny',"--root=#{@apptmp}") }
      assert_match_in_file(/set :session_secret, '[0-9A-z]*'/, "#{@apptmp}/sample_project/config/apps.rb")
    end

    should "create components file containing options chosen with defaults" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
      assert_equal 'none', components_chosen[:orm]
      assert_equal 'none', components_chosen[:test]
      assert_equal 'none', components_chosen[:mock]
      assert_equal 'none', components_chosen[:script]
      assert_equal 'slim', components_chosen[:renderer]
    end

    should "create components file containing options chosen" do
      component_options = ['--orm=datamapper', '--test=riot', '--mock=mocha', '--script=prototype', '--renderer=erb', '--stylesheet=less']
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", *component_options) }
      components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
      assert_equal 'datamapper', components_chosen[:orm]
      assert_equal 'riot',       components_chosen[:test]
      assert_equal 'mocha',      components_chosen[:mock]
      assert_equal 'prototype',  components_chosen[:script]
      assert_equal 'erb',        components_chosen[:renderer]
      assert_equal 'less',       components_chosen[:stylesheet]
    end

    should "output to log components being applied" do
      component_options = ['--orm=datamapper', '--test=riot', '--mock=mocha', '--script=prototype', '--renderer=erb','--stylesheet=less']
      out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", *component_options) }
      assert_match(/applying.*?datamapper.*?orm/, out)
      assert_match(/applying.*?riot.*?test/, out)
      assert_match(/applying.*?mocha.*?mock/, out)
      assert_match(/applying.*?prototype.*?script/, out)
      assert_match(/applying.*?erb.*?renderer/, out)
      assert_match(/applying.*?less.*?stylesheet/, out)
    end

    should "output gem files for base app" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none') }
      assert_match_in_file(/gem 'padrino'/, "#{@apptmp}/sample_project/Gemfile")
    end
  end

  context "a generator for mock component" do
    should "properly generate for rr and riot" do
      out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--mock=rr', '--test=riot', '--script=none') }
      assert_match(/applying.*?rr.*?mock/, out)
      assert_match_in_file(/gem 'rr'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/require 'riot\/rr'/, "#{@apptmp}/sample_project/test/test_config.rb")
    end

    should "properly generate for rr and minitest" do
      out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--mock=rr', '--test=minitest', '--script=none') }
      assert_match(/applying.*?rr.*?mock/, out)
      assert_match_in_file(/gem 'rr'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/include RR::Adapters::MiniTest/, "#{@apptmp}/sample_project/test/test_config.rb")
    end

    should "properly generater for rr and bacon" do
      out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--mock=rr', '--test=bacon', '--script=none') }
      assert_match(/applying.*?rr.*?mock/, out)
      assert_match_in_file(/gem 'rr'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/include RR::Adapters::TestUnit/m, "#{@apptmp}/sample_project/test/test_config.rb")
    end

    should "properly generate for rr and rspec" do
      out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=rspec', '--mock=rr', '--script=none') }
      assert_match(/applying.*?rr.*?mock/, out)
      assert_match_in_file(/gem 'rr'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/conf.mock_with :rr/m, "#{@apptmp}/sample_project/spec/spec_helper.rb")
    end

    should "properly generate for mocha and rspec" do
      out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}",'--test=rspec', '--mock=mocha', '--script=none') }
      assert_match(/applying.*?mocha.*?mock/, out)
      assert_match_in_file(/gem 'mocha'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/conf.mock_with :mocha/m, "#{@apptmp}/sample_project/spec/spec_helper.rb")
    end
  end

  context "the generator for orm components" do

    context "for sequel" do
      should "properly generate default" do
        @app.instance_eval("undef setup_orm if respond_to?('setup_orm')")
        out, err = capture_io { generate(:project, 'project.com', "--root=#{@apptmp}", '--orm=sequel', '--script=none') }
        assert_match(/applying.*?sequel.*?orm/, out)
        assert_match_in_file(/gem 'sequel'/, "#{@apptmp}/project.com/Gemfile")
        assert_match_in_file(/gem 'sqlite3'/, "#{@apptmp}/project.com/Gemfile")
        assert_match_in_file(/Sequel.connect/, "#{@apptmp}/project.com/config/database.rb")
        assert_match_in_file(%r{sqlite://}, "#{@apptmp}/project.com/config/database.rb")
        assert_match_in_file(%r{project_com}, "#{@apptmp}/project.com/config/database.rb")
      end

      should "properly generate mysql (default to mysql2)" do
        out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=sequel', '--adapter=mysql') }
        assert_match_in_file(/gem 'mysql2'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(%r{"mysql2://}, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
      end

      should "properly generate mysql2" do
        out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=sequel', '--adapter=mysql2') }
        assert_match_in_file(/gem 'mysql2'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(%r{"mysql2://}, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
      end

      should "properly generate mysql-gem" do
        out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=sequel', '--adapter=mysql-gem') }
        assert_match_in_file(/gem 'mysql'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(%r{"mysql://}, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
      end

      should "properly generate sqlite3" do
        out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=sequel', '--adapter=sqlite') }
        assert_match_in_file(/gem 'sqlite3'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(%r{sqlite://}, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
      end

      should "properly generate postgres" do
        out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=sequel', '--adapter=postgres') }
        assert_match_in_file(/gem 'pg'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(%r{"postgres://}, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
      end
    end

    context "for activerecord" do
      should "properly generate default" do
        out, err = capture_io { generate(:project, 'project.com', "--root=#{@apptmp}", '--orm=activerecord', '--script=none') }
        assert_match(/applying.*?activerecord.*?orm/, out)
        assert_match_in_file(/gem 'activerecord', '>= 3.1', :require => 'active_record'/, "#{@apptmp}/project.com/Gemfile")
        assert_match_in_file(/gem 'sqlite3'/, "#{@apptmp}/project.com/Gemfile")
        assert_match_in_file(/ActiveRecord::Base.establish_connection/, "#{@apptmp}/project.com/config/database.rb")
        assert_match_in_file(/project_com/, "#{@apptmp}/project.com/config/database.rb")
      end

      should "properly generate mysql (default to mysql2)" do
        out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=activerecord','--adapter=mysql') }
        assert_match_in_file(/gem 'mysql2'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(%r{:adapter   => 'mysql2'}, "#{@apptmp}/sample_project/config/database.rb")
      end

      should "properly generate mysql2" do
        out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=activerecord','--adapter=mysql2') }
        assert_match_in_file(/gem 'mysql2'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(%r{:adapter   => 'mysql2'}, "#{@apptmp}/sample_project/config/database.rb")
      end

      should "properly generate mysql-gem" do
        out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=activerecord','--adapter=mysql-gem') }
        assert_match_in_file(/gem 'mysql', '~> 2.8.1'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(%r{:adapter   => 'mysql'}, "#{@apptmp}/sample_project/config/database.rb")
      end

      should "properly generate sqlite3" do
        out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=activerecord', '--adapter=sqlite3') }
        assert_match_in_file(/gem 'sqlite3'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(/sample_project_development.db/, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(%r{:adapter => 'sqlite3'}, "#{@apptmp}/sample_project/config/database.rb")
      end

      should "properly generate postgres" do
        out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=activerecord', '--adapter=postgres') }
        assert_match_in_file(/gem 'pg'$/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(%r{:adapter   => 'postgresql'}, "#{@apptmp}/sample_project/config/database.rb")
      end
    end

    context "for datamapper" do
      should "properly generate default" do
        out, err = capture_io { generate(:project, 'project.com', "--root=#{@apptmp}", '--orm=datamapper', '--script=none') }
        assert_match(/applying.*?datamapper.*?orm/, out)
        assert_match_in_file(/gem 'dm-core'/, "#{@apptmp}/project.com/Gemfile")
        assert_match_in_file(/gem 'dm-sqlite-adapter'/, "#{@apptmp}/project.com/Gemfile")
        assert_match_in_file(/DataMapper.setup/, "#{@apptmp}/project.com/config/database.rb")
        assert_match_in_file(/project_com/, "#{@apptmp}/project.com/config/database.rb")
      end

      should "properly generate for mysql" do
        out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=datamapper', '--adapter=mysql') }
        assert_match_in_file(/gem 'dm-mysql-adapter'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(%r{"mysql://}, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
      end

      # DataMapper has do_mysql that is the version of MySQL driver.
      should "properly generate for mysql2" do
        out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=datamapper', '--adapter=mysql2') }
        assert_match_in_file(/gem 'dm-mysql-adapter'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(%r{"mysql://}, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
      end

      should "properly generate for sqlite" do
        out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=datamapper', '--adapter=sqlite') }
        assert_match_in_file(/gem 'dm-sqlite-adapter'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
      end

      should "properly generate for postgres" do
        out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=datamapper', '--adapter=postgres') }
        assert_match_in_file(/gem 'dm-postgres-adapter'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(%r{"postgres://}, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
      end
    end

    should "properly generate for mongomapper" do
      out, err = capture_io { generate(:project, 'project.com', "--root=#{@apptmp}", '--orm=mongomapper', '--script=none') }
      assert_match(/applying.*?mongomapper.*?orm/, out)
      assert_match_in_file(/gem 'mongo_mapper'/, "#{@apptmp}/project.com/Gemfile")
      assert_match_in_file(/gem 'bson_ext'/, "#{@apptmp}/project.com/Gemfile")
      assert_match_in_file(/MongoMapper.database/, "#{@apptmp}/project.com/config/database.rb")
      assert_match_in_file(/project_com/, "#{@apptmp}/project.com/config/database.rb")
    end

    should "properly generate for mongoid" do
      out, err = capture_io { generate(:project, 'project.com', "--root=#{@apptmp}", '--orm=mongoid', '--script=none') }
      assert_match(/applying.*?mongoid.*?orm/, out)
      if RUBY_VERSION >= '1.9'
        assert_match_in_file(/gem 'mongoid', '~>3.0.0'/, "#{@apptmp}/project.com/Gemfile")
        assert_match_in_file(/Mongoid::Config.sessions =/, "#{@apptmp}/project.com/config/database.rb")
      else
        assert_match_in_file(/gem 'mongoid', '~>2.0'/, "#{@apptmp}/project.com/Gemfile")
        assert_match_in_file(/Mongoid.database/, "#{@apptmp}/project.com/config/database.rb")
      end
    end


    should "properly generate for couchrest" do
      out, err = capture_io { generate(:project, 'project.com', "--root=#{@apptmp}", '--orm=couchrest', '--script=none') }
      assert_match(/applying.*?couchrest.*?orm/, out)
      assert_match_in_file(/gem 'couchrest_model'/, "#{@apptmp}/project.com/Gemfile")
      assert_match_in_file(/CouchRest.database!/, "#{@apptmp}/project.com/config/database.rb")
      assert_match_in_file(/project_com/, "#{@apptmp}/project.com/config/database.rb")
    end

    should "properly generate for ohm" do
      out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=ohm', '--script=none') }
      assert_match(/applying.*?ohm.*?orm/, out)
      assert_match_in_file(/gem 'ohm'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/Ohm.connect/, "#{@apptmp}/sample_project/config/database.rb")
    end

    should "properly generate for mongomatic" do
      out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=mongomatic', '--script=none') }
      assert_match(/applying.*?mongomatic.*?orm/, out)
      assert_match_in_file(/gem 'bson_ext'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'mongomatic'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/Mongomatic.db = Mongo::Connection.new.db/, "#{@apptmp}/sample_project/config/database.rb")
    end

    should "properly generate for ripple" do
      out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=ripple', '--script=none') }
      assert_match(/applying.*?ripple.*?orm/, out)
      assert_match_in_file(/gem 'ripple'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/Ripple.load_configuration/, "#{@apptmp}/sample_project/config/database.rb")
      assert_match_in_file(/http_port: 8098/, "#{@apptmp}/sample_project/config/riak.yml")
    end
  end


  context "the generator for renderer component" do
    should "properly generate for erb" do
      out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--renderer=erb', '--script=none') }
      assert_match(/applying.*?erb.*?renderer/, out)
      assert_match_in_file(/gem 'erubis'/, "#{@apptmp}/sample_project/Gemfile")
    end

    should "properly generate for haml" do
      out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--renderer=haml','--script=none') }
      assert_match(/applying.*?haml.*?renderer/, out)
      assert_match_in_file(/gem 'haml'/, "#{@apptmp}/sample_project/Gemfile")
    end

    should "properly generate for liquid" do
      out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--renderer=liquid','--script=none') }
      assert_match(/applying.*?liquid.*?renderer/, out)
      assert_match_in_file(/gem 'liquid'/, "#{@apptmp}/sample_project/Gemfile")
    end

    should "properly generate for slim" do
      out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--renderer=slim','--script=none') }
      assert_match(/applying.*?slim.*?renderer/, out)
      assert_match_in_file(/gem 'slim'/, "#{@apptmp}/sample_project/Gemfile")
    end
  end

  context "the generator for script component" do
    should "properly generate for jquery" do
      out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=jquery') }
      assert_match(/applying.*?jquery.*?script/, out)
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/jquery.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/jquery-ujs.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/application.js")
    end

    should "properly generate for mootools" do
      out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=mootools') }
      assert_match(/applying.*?mootools.*?script/, out)
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/mootools.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/mootools-ujs.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/application.js")
    end

    should "properly generate for prototype" do
      out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=prototype') }
      assert_match(/applying.*?prototype.*?script/, out)
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/protopak.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/lowpro.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/prototype-ujs.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/application.js")
    end

    should "properly generate for rightjs" do
      out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=rightjs') }
      assert_match(/applying.*?rightjs.*?script/, out)
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/right.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/right-ujs.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/application.js")
    end

    should "properly generate for ext-core" do
      out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=extcore') }
      assert_match(/applying.*?extcore.*?script/, out)
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/ext.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/ext-ujs.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/application.js")
    end

    should "properly generate for dojo" do
      out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=dojo') }
      assert_match(/applying.*?dojo.*?script/, out)
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/dojo.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/dojo-ujs.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/application.js")
    end
  end

  context "the generator for test component" do
    should "properly generate for bacon" do
      out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=bacon', '--script=none') }
      assert_match(/applying.*?bacon.*?test/, out)
      assert_match_in_file(/gem 'rack-test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/:require => 'rack\/test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/:group => 'test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'bacon'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/Bacon::Context/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_file_exists("#{@apptmp}/sample_project/test/test.rake")
      assert_match_in_file(/Rake::TestTask.new\("test:\#/,"#{@apptmp}/sample_project/test/test.rake")
      assert_match_in_file(/task 'test' => test_tasks/,"#{@apptmp}/sample_project/test/test.rake")
    end

    should "properly generate for riot" do
      out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=riot', '--script=none') }
      assert_match(/applying.*?riot.*?test/, out)
      assert_match_in_file(/gem 'rack-test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/:require => 'rack\/test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/:group => 'test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'riot'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/include Rack::Test::Methods/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_match_in_file(/Riot::Situation/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_match_in_file(/Riot::Context/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_match_in_file(/SampleProject::App\.tap/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_file_exists("#{@apptmp}/sample_project/test/test.rake")
      assert_match_in_file(/Rake::TestTask\.new\("test:\#/,"#{@apptmp}/sample_project/test/test.rake")
      assert_match_in_file(/task 'test' => test_tasks/,"#{@apptmp}/sample_project/test/test.rake")
    end

    should "properly generate for rspec" do
      out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=rspec', '--script=none') }
      assert_match(/applying.*?rspec.*?test/, out)
      assert_match_in_file(/gem 'rack-test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/:require => 'rack\/test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/:group => 'test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'rspec'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, "#{@apptmp}/sample_project/spec/spec_helper.rb")
      assert_match_in_file(/RSpec.configure/, "#{@apptmp}/sample_project/spec/spec_helper.rb")
      assert_file_exists("#{@apptmp}/sample_project/spec/spec.rake")
      assert_match_in_file(/RSpec::Core::RakeTask\.new\("spec:\#/,"#{@apptmp}/sample_project/spec/spec.rake")
      assert_match_in_file(/task 'spec' => spec_tasks/,"#{@apptmp}/sample_project/spec/spec.rake")
    end

    should "properly generate for shoulda" do
      out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=shoulda', '--script=none') }
      assert_match(/applying.*?shoulda.*?test/, out)
      assert_match_in_file(/gem 'rack-test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/:require => 'rack\/test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/:group => 'test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'shoulda'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_match_in_file(/Test::Unit::TestCase/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_file_exists("#{@apptmp}/sample_project/test/test.rake")
      assert_match_in_file(/Rake::TestTask\.new\("test:\#/,"#{@apptmp}/sample_project/test/test.rake")
      assert_match_in_file(/task 'test' => test_tasks/,"#{@apptmp}/sample_project/test/test.rake")
    end

    should "properly generate for minitest" do
      out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=minitest', '--script=none') }
      assert_match(/applying.*?minitest.*?test/, out)
      assert_match_in_file(/gem 'rack-test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/:require => 'rack\/test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/:group => 'test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'minitest'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/include Rack::Test::Methods/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_match_in_file(/MiniTest::Unit::TestCase/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_match_in_file(/SampleProject::App\.tap/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_file_exists("#{@apptmp}/sample_project/test/test.rake")
      assert_match_in_file(/Rake::TestTask\.new\("test:\#/,"#{@apptmp}/sample_project/test/test.rake")
      assert_match_in_file(/task 'test' => test_tasks/,"#{@apptmp}/sample_project/test/test.rake")
    end # minitest

    should "properly generate for testspec" do
      out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=testspec', '--script=none') }
      assert_match(/applying.*?testspec.*?test/, out)
      assert_match_in_file(/gem 'rack-test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/:require => 'rack\/test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/:group => 'test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'test-spec'.*?:require => 'test\/spec'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_match_in_file(/Test::Unit::TestCase/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_match_in_file(/gem 'test-spec'.*?:require => 'test\/spec'/, "#{@apptmp}/sample_project/Gemfile")
      assert_file_exists("#{@apptmp}/sample_project/test/test.rake")
      assert_match_in_file(/Rake::TestTask\.new\("test:\#/,"#{@apptmp}/sample_project/test/test.rake")
      assert_match_in_file(/task 'test' => test_tasks/,"#{@apptmp}/sample_project/test/test.rake")
    end

    should "properly generate for cucumber" do
      out, err = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=cucumber', '--script=none') }
      assert_match(/applying.*?cucumber.*?test/, out)
      assert_match_in_file(/gem 'rack-test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/:require => 'rack\/test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/:group => 'test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'rspec'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'cucumber'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, "#{@apptmp}/sample_project/spec/spec_helper.rb")
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, "#{@apptmp}/sample_project/features/support/env.rb")
      assert_match_in_file(/gem 'capybara'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/RSpec.configure/, "#{@apptmp}/sample_project/spec/spec_helper.rb")
      assert_match_in_file(/Capybara.app = /, "#{@apptmp}/sample_project/features/support/env.rb")
      assert_match_in_file(/World\(Cucumber::Web::URLs\)/, "#{@apptmp}/sample_project/features/support/url.rb")
      assert_file_exists("#{@apptmp}/sample_project/spec/spec.rake")
      assert_match_in_file(/RSpec::Core::RakeTask\.new\("spec:\#/,"#{@apptmp}/sample_project/spec/spec.rake")
      assert_match_in_file(/task 'spec' => spec_tasks/,"#{@apptmp}/sample_project/spec/spec.rake")
      assert_file_exists("#{@apptmp}/sample_project/features/support/env.rb")
      assert_file_exists("#{@apptmp}/sample_project/features/add.feature")
      assert_file_exists("#{@apptmp}/sample_project/features/step_definitions/add_steps.rb")
    end
  end

  context "the generator for stylesheet component" do
    should "properly generate for sass" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--renderer=haml','--script=none','--stylesheet=sass') }
      assert_match_in_file(/gem 'sass'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/module SassInitializer.*Sass::Plugin::Rack/m, "#{@apptmp}/sample_project/lib/sass_init.rb")
      assert_match_in_file(/register SassInitializer/m, "#{@apptmp}/sample_project/app/app.rb")
      assert_dir_exists("#{@apptmp}/sample_project/app/stylesheets")
    end

    should "properly generate for less" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--renderer=haml','--script=none','--stylesheet=less') }
      assert_match_in_file(/gem 'rack-less'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/module LessInitializer.*Rack::Less/m, "#{@apptmp}/sample_project/lib/less_init.rb")
      assert_match_in_file(/register LessInitializer/m, "#{@apptmp}/sample_project/app/app.rb")
      assert_dir_exists("#{@apptmp}/sample_project/app/stylesheets")
    end

    should "properly generate for compass" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--renderer=haml','--script=none','--stylesheet=compass') }
      assert_match_in_file(/gem 'compass'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/Compass.configure_sass_plugin\!/, "#{@apptmp}/sample_project/lib/compass_plugin.rb")
      assert_match_in_file(/module CompassInitializer.*Sass::Plugin::Rack/m, "#{@apptmp}/sample_project/lib/compass_plugin.rb")
      assert_match_in_file(/register CompassInitializer/m, "#{@apptmp}/sample_project/app/app.rb")

      assert_file_exists("#{@apptmp}/sample_project/app/stylesheets/application.scss")
      assert_file_exists("#{@apptmp}/sample_project/app/stylesheets/partials/_base.scss")
    end

    should "properly generate for scss" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--renderer=haml','--script=none','--stylesheet=scss') }
      assert_match_in_file(/gem 'haml'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/module ScssInitializer.*Sass::Plugin::Rack/m, "#{@apptmp}/sample_project/lib/scss_init.rb")
      assert_match_in_file(/Sass::Plugin.options\[:syntax\] = :scss/m, "#{@apptmp}/sample_project/lib/scss_init.rb")
      assert_match_in_file(/register ScssInitializer/m, "#{@apptmp}/sample_project/app/app.rb")
      assert_dir_exists("#{@apptmp}/sample_project/app/stylesheets")
    end
  end
end
