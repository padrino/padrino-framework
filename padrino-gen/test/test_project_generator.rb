require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestProjectGenerator < Test::Unit::TestCase
  def setup
    `rm -rf /tmp/sample_project`
    `rm -rf /tmp/project.com`
    `rm -rf /tmp/warepedia`
  end

  context 'the project generator' do
    should "allow simple generator to run and create base_app with no options" do
      assert_nothing_raised { silence_logger { generate(:project, 'sample_project', '--root=/tmp') } }
      assert_file_exists('/tmp/sample_project')
      assert_match_in_file(/class SampleProject < Padrino::Application/,'/tmp/sample_project/app/app.rb')
      assert_match_in_file(/Padrino.mount\("SampleProject"\).to\('\/'\)/,'/tmp/sample_project/config/apps.rb')
      assert_file_exists('/tmp/sample_project/config/boot.rb')
      assert_file_exists('/tmp/sample_project/public/favicon.ico')
    end

    should "generate a valid name" do
      silence_logger { generate(:project, 'project.com', '--root=/tmp') }
      assert_file_exists('/tmp/project.com')
      assert_match_in_file(/class ProjectCom < Padrino::Application/,'/tmp/project.com/app/app.rb')
      assert_match_in_file(/Padrino.mount\("ProjectCom"\).to\('\/'\)/,'/tmp/project.com/config/apps.rb')
    end

    should "allow specifying alternate application name" do
      assert_nothing_raised { silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--app=base_app') } }
      assert_file_exists('/tmp/sample_project')
      assert_match_in_file(/class BaseApp < Padrino::Application/,'/tmp/sample_project/app/app.rb')
      assert_match_in_file(/Padrino.mount\("BaseApp"\).to\('\/'\)/,'/tmp/sample_project/config/apps.rb')
      assert_file_exists('/tmp/sample_project/config/boot.rb')
      assert_file_exists('/tmp/sample_project/public/favicon.ico')
    end

    should "generate tiny skeleton" do
      assert_nothing_raised { silence_logger { generate(:project,'sample_project', '--tiny','--root=/tmp') } }
      assert_file_exists('/tmp/sample_project')
      assert_file_exists('/tmp/sample_project/app')
      assert_file_exists('/tmp/sample_project/app/controllers.rb')
      assert_file_exists('/tmp/sample_project/app/helpers.rb')
      assert_file_exists('/tmp/sample_project/app/mailers.rb')
      assert_dir_exists('/tmp/sample_project/app/views/mailers')
      assert_match_in_file(/:notifier/,'/tmp/sample_project/app/mailers.rb')
      assert_no_file_exists('/tmp/sample_project/demo/helpers')
      assert_no_file_exists('/tmp/sample_project/demo/controllers')
    end

    should "not create models folder if no orm is chosen" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '--orm=none') }
      assert_no_dir_exists('/tmp/sample_project/app/models')
    end

    should "not create tests folder if no test framework is chosen" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none', '--test=none') }
      assert_no_dir_exists('/tmp/sample_project/test')
    end

    should "place app specific names into correct files" do
      silence_logger { generate(:project, 'warepedia', '--root=/tmp', '--script=none') }
      assert_match_in_file(/class Warepedia < Padrino::Application/m, '/tmp/warepedia/app/app.rb')
      assert_match_in_file(/Padrino.mount\("Warepedia"\).to\('\/'\)/m, '/tmp/warepedia/config/apps.rb')
    end

    should "create components file containing options chosen with defaults" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp') }
      components_chosen = YAML.load_file('/tmp/sample_project/.components')
      assert_equal 'none', components_chosen[:orm]
      assert_equal 'none', components_chosen[:test]
      assert_equal 'none', components_chosen[:mock]
      assert_equal 'none', components_chosen[:script]
      assert_equal 'haml', components_chosen[:renderer]
    end

    should "create components file containing options chosen" do
      component_options = ['--orm=datamapper', '--test=riot', '--mock=mocha', '--script=prototype', '--renderer=erb', '--stylesheet=less']
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', *component_options) }
      components_chosen = YAML.load_file('/tmp/sample_project/.components')
      assert_equal 'datamapper', components_chosen[:orm]
      assert_equal 'riot',  components_chosen[:test]
      assert_equal 'mocha',     components_chosen[:mock]
      assert_equal 'prototype', components_chosen[:script]
      assert_equal 'erb',   components_chosen[:renderer]
      assert_equal 'less',  components_chosen[:stylesheet]
    end

    should "output to log components being applied" do
      component_options = ['--orm=datamapper', '--test=riot', '--mock=mocha', '--script=prototype', '--renderer=erb','--stylesheet=less']
      buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', *component_options) }
      assert_match(/Applying.*?datamapper.*?orm/, buffer)
      assert_match(/Applying.*?riot.*?test/, buffer)
      assert_match(/Applying.*?mocha.*?mock/, buffer)
      assert_match(/Applying.*?prototype.*?script/, buffer)
      assert_match(/Applying.*?erb.*?renderer/, buffer)
      assert_match(/Applying.*?less.*?stylesheet/, buffer)
    end

    should "output gem files for base app" do
      silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=none') }
      assert_match_in_file(/gem 'padrino'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/gem 'rack-flash'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/gem 'thin'/, '/tmp/sample_project/Gemfile')
    end
  end

  context "a generator for mock component" do
    should "properly generate for rr and riot" do
      buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--mock=rr', '--test=riot', '--script=none') }
      assert_match(/Applying.*?rr.*?mock/, buffer)
      assert_match_in_file(/gem 'rr'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/require 'riot\/rr'/, '/tmp/sample_project/test/test_config.rb')
    end

    should "properly generater for rr and bacon" do
      buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--mock=rr', '--test=bacon', '--script=none') }
      assert_match(/Applying.*?rr.*?mock/, buffer)
      assert_match_in_file(/gem 'rr'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/RR::Adapters::RRMethods/m, '/tmp/sample_project/test/test_config.rb')
    end

    should "properly generate for mocha and rspec" do
      buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp','--test=rspec', '--mock=mocha', '--script=none') }
      assert_match(/Applying.*?mocha.*?mock/, buffer)
      assert_match_in_file(/gem 'mocha'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/conf.mock_with :mocha/m, '/tmp/sample_project/spec/spec_helper.rb')
    end

    should "properly generate for rr and rspec" do
      buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--test=rspec', '--mock=rr', '--script=none') }
      assert_match(/Applying.*?rr.*?mock/, buffer)
      assert_match_in_file(/gem 'rr'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/conf.mock_with :rr/m, '/tmp/sample_project/spec/spec_helper.rb')
    end

  end

  context "the generator for orm components" do

    context "for sequel" do
      should "properly generate default" do
        @app.instance_eval("undef setup_orm if respond_to?('setup_orm')")
        buffer = silence_logger { generate(:project, 'project.com', '--root=/tmp', '--orm=sequel', '--script=none') }
        assert_match(/Applying.*?sequel.*?orm/, buffer)
        assert_match_in_file(/gem 'sequel'/, '/tmp/project.com/Gemfile')
        assert_match_in_file(/gem 'sqlite3-ruby'/, '/tmp/project.com/Gemfile')
        assert_match_in_file(/Sequel.connect/, '/tmp/project.com/config/database.rb')
        assert_match_in_file(%r{sqlite://}, '/tmp/project.com/config/database.rb')
        assert_match_in_file(%r{project_com}, '/tmp/project.com/config/database.rb')
        assert_dir_exists('/tmp/project.com/app/models')
      end

      should "properly generate mysql" do
        buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--orm=sequel', '--adapter=mysql') }
        assert_match_in_file(/gem 'mysql'/, '/tmp/sample_project/Gemfile')
        assert_match_in_file(%r{"mysql://}, '/tmp/sample_project/config/database.rb')
        assert_match_in_file(/sample_project_development/, '/tmp/sample_project/config/database.rb')
      end

      should "properly generate sqlite3" do
        buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--orm=sequel', '--adapter=sqlite') }
        assert_match_in_file(/gem 'sqlite3-ruby'/, '/tmp/sample_project/Gemfile')
        assert_match_in_file(%r{sqlite://}, '/tmp/sample_project/config/database.rb')
        assert_match_in_file(/sample_project_development/, '/tmp/sample_project/config/database.rb')
      end

      should "properly generate postgres" do
        buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--orm=sequel', '--adapter=postgres') }
        assert_match_in_file(/gem 'pg'/, '/tmp/sample_project/Gemfile')
        assert_match_in_file(%r{"postgres://}, '/tmp/sample_project/config/database.rb')
        assert_match_in_file(/sample_project_development/, '/tmp/sample_project/config/database.rb')
      end
    end

    context "for activerecord" do
      should "properly generate default" do
        buffer = silence_logger { generate(:project, 'project.com', '--root=/tmp', '--orm=activerecord', '--script=none') }
        assert_match(/Applying.*?activerecord.*?orm/, buffer)
        assert_match_in_file(/gem 'activerecord', :require => "active_record"/, '/tmp/project.com/Gemfile')
        assert_match_in_file(/gem 'sqlite3-ruby', :require => "sqlite3"/, '/tmp/project.com/Gemfile')
        assert_match_in_file(/ActiveRecord::Base.establish_connection/, '/tmp/project.com/config/database.rb')
        assert_match_in_file(/project_com/, '/tmp/project.com/config/database.rb')
        assert_dir_exists('/tmp/project.com/app/models')
      end

      should "properly generate mysql" do
        buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--orm=activerecord','--adapter=mysql') }
        assert_match_in_file(/gem 'mysql'/, '/tmp/sample_project/Gemfile')
        assert_match_in_file(/sample_project_development/, '/tmp/sample_project/config/database.rb')
        assert_match_in_file(%r{:adapter   => 'mysql'}, '/tmp/sample_project/config/database.rb')
      end

      should "properly generate sqlite3" do
        buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--orm=activerecord', '--adapter=sqlite3') }
        assert_match_in_file(/gem 'sqlite3-ruby', :require => "sqlite3"/, '/tmp/sample_project/Gemfile')
        assert_match_in_file(/sample_project_development.db/, '/tmp/sample_project/config/database.rb')
        assert_match_in_file(%r{:adapter => 'sqlite3'}, '/tmp/sample_project/config/database.rb')
      end

      should "properly generate postgres" do
        buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--orm=activerecord', '--adapter=postgres') }
        assert_match_in_file(/gem 'pg', :require => "postgres"/, '/tmp/sample_project/Gemfile')
        assert_match_in_file(/sample_project_development/, '/tmp/sample_project/config/database.rb')
        assert_match_in_file(%r{:adapter   => 'postgresql'}, '/tmp/sample_project/config/database.rb')
      end
    end

    context "for datamapper" do
      should "properly generate default" do
        buffer = silence_logger { generate(:project, 'project.com', '--root=/tmp', '--orm=datamapper', '--script=none') }
        assert_match(/Applying.*?datamapper.*?orm/, buffer)
        assert_match_in_file(/gem 'data_mapper'/, '/tmp/project.com/Gemfile')
        assert_match_in_file(/gem 'dm-sqlite-adapter'/, '/tmp/project.com/Gemfile')
        assert_match_in_file(/DataMapper.setup/, '/tmp/project.com/config/database.rb')
        assert_match_in_file(/project_com/, '/tmp/project.com/config/database.rb')
        assert_dir_exists('/tmp/project.com/app/models')
      end

      should "properly generate for mysql" do
        buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--orm=datamapper', '--adapter=mysql') }
        assert_match_in_file(/gem 'dm-mysql-adapter'/, '/tmp/sample_project/Gemfile')
        assert_match_in_file(%r{"mysql://}, '/tmp/sample_project/config/database.rb')
        assert_match_in_file(/sample_project_development/, '/tmp/sample_project/config/database.rb')
      end

      should "properly generate for sqlite" do
        buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--orm=datamapper', '--adapter=sqlite') }
        assert_match_in_file(/gem 'dm-sqlite-adapter'/, '/tmp/sample_project/Gemfile')
        assert_match_in_file(/sample_project_development/, '/tmp/sample_project/config/database.rb')
      end

      should "properly generate for postgres" do
        buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--orm=datamapper', '--adapter=postgres') }
        assert_match_in_file(/gem 'dm-postgres-adapter'/, '/tmp/sample_project/Gemfile')
        assert_match_in_file(%r{"postgres://}, '/tmp/sample_project/config/database.rb')
        assert_match_in_file(/sample_project_development/, '/tmp/sample_project/config/database.rb')
      end
    end

    should "properly generate for mongomapper" do
      buffer = silence_logger { generate(:project, 'project.com', '--root=/tmp', '--orm=mongomapper', '--script=none') }
      assert_match(/Applying.*?mongomapper.*?orm/, buffer)
      assert_match_in_file(/gem 'mongo_mapper'/, '/tmp/project.com/Gemfile')
      assert_match_in_file(/gem 'bson_ext'/, '/tmp/project.com/Gemfile')
      assert_match_in_file(/MongoMapper.database/, '/tmp/project.com/config/database.rb')
      assert_match_in_file(/project_com/, '/tmp/project.com/config/database.rb')
      assert_dir_exists('/tmp/project.com/app/models')
    end

    should "properly generate for mongoid" do
      buffer = silence_logger { generate(:project, 'project.com', '--root=/tmp', '--orm=mongoid', '--script=none') }
      assert_match(/Applying.*?mongoid.*?orm/, buffer)
      assert_match_in_file(/gem 'mongoid'/, '/tmp/project.com/Gemfile')
      assert_match_in_file(/gem 'bson_ext'/, '/tmp/project.com/Gemfile')
      assert_match_in_file(/Mongoid.database/, '/tmp/project.com/config/database.rb')
      assert_match_in_file(/project_com/, '/tmp/project.com/config/database.rb')
      assert_dir_exists('/tmp/project.com/app/models')
    end


    should "properly generate for couchrest" do
      buffer = silence_logger { generate(:project, 'project.com', '--root=/tmp', '--orm=couchrest', '--script=none') }
      assert_match(/Applying.*?couchrest.*?orm/, buffer)
      assert_match_in_file(/gem 'couchrest'/, '/tmp/project.com/Gemfile')
      assert_match_in_file(/CouchRest.database!/, '/tmp/project.com/config/database.rb')
      assert_match_in_file(/project_com/, '/tmp/project.com/config/database.rb')
      assert_dir_exists('/tmp/project.com/app/models')
    end

    should "properly generate for ohm" do
      buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--orm=ohm', '--script=none') }
      assert_match /Applying.*?ohm.*?orm/, buffer
      assert_match_in_file(/gem 'json'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/gem 'ohm'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/gem 'ohm-contrib', :require => "ohm\/contrib"/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/Ohm.connect/, '/tmp/sample_project/config/database.rb')
      assert_dir_exists('/tmp/sample_project/app/models')
    end

    should "properly generate for mongomatic" do
      buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--orm=mongomatic', '--script=none') }
      assert_match /Applying.*?mongomatic.*?orm/, buffer
      assert_match_in_file(/gem 'bson_ext'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/gem 'mongomatic'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/Mongomatic.db = Mongo::Connection.new.db/, '/tmp/sample_project/config/database.rb')
      assert_dir_exists('/tmp/sample_project/app/models')
    end
  end


  context "the generator for renderer component" do
    should "properly generate for erb" do
      buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--renderer=erb', '--script=none') }
      assert_match(/Applying.*?erb.*?renderer/, buffer)
    end

    should "properly generate for haml" do
      buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--renderer=haml','--script=none') }
      assert_match(/Applying.*?haml.*?renderer/, buffer)
      assert_match_in_file(/gem 'haml'/, '/tmp/sample_project/Gemfile')
    end
    
    should "properly generate for erubis" do 
      buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--renderer=erubis','--script=none') }
      assert_match(/Applying.*?erubis.*?renderer/,buffer)
      assert_match_in_file(/gem 'erubis'/, '/tmp/sample_project/Gemfile')
    end

    should "properly generate for liquid" do 
      buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--renderer=liquid','--script=none') }
      assert_match(/Applying.*?erubis.*?renderer/,buffer)
      assert_match_in_file(/gem 'liquid'/, '/tmp/sample_project/Gemfile')
    end

  end

  context "the generator for script component" do
    should "properly generate for jquery" do
      buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=jquery') }
      assert_match(/Applying.*?jquery.*?script/, buffer)
      assert_file_exists('/tmp/sample_project/public/javascripts/jquery.js')
      assert_file_exists('/tmp/sample_project/public/javascripts/application.js')
    end

    should "properly generate for mootools" do
      buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=mootools') }
      assert_match(/Applying.*?mootools.*?script/, buffer)
      assert_file_exists('/tmp/sample_project/public/javascripts/mootools-core.js')
      assert_file_exists('/tmp/sample_project/public/javascripts/application.js')
    end

    should "properly generate for prototype" do
      buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=prototype') }
      assert_match(/Applying.*?prototype.*?script/, buffer)
      assert_file_exists('/tmp/sample_project/public/javascripts/protopak.js')
      assert_file_exists('/tmp/sample_project/public/javascripts/lowpro.js')
      assert_file_exists('/tmp/sample_project/public/javascripts/application.js')
    end

    should "properly generate for rightjs" do
      buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=rightjs') }
      assert_match(/Applying.*?rightjs.*?script/, buffer)
      assert_file_exists('/tmp/sample_project/public/javascripts/right.js')
      assert_file_exists('/tmp/sample_project/public/javascripts/application.js')
    end

    should "properly generate for ext-core" do
      buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=extcore') }
      assert_match(/Applying.*?extcore.*?script/, buffer)
      assert_file_exists('/tmp/sample_project/public/javascripts/ext-core.js')
      assert_file_exists('/tmp/sample_project/public/javascripts/application.js')
    end

    should "properly generate for dojo" do
      buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--script=dojo') }
      assert_match(/Applying.*?dojo.*?script/, buffer)
      assert_file_exists('/tmp/sample_project/public/javascripts/dojo.js')
      assert_file_exists('/tmp/sample_project/public/javascripts/application.js')
    end
  end

  context "the generator for test component" do
    should "properly generate for bacon" do
      buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--test=bacon', '--script=none') }
      assert_match(/Applying.*?bacon.*?test/, buffer)
      assert_match_in_file(/gem 'rack-test'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/:require => "rack\/test"/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/:group => "test"/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/gem 'bacon'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, '/tmp/sample_project/test/test_config.rb')
      assert_match_in_file(/Bacon::Context/, '/tmp/sample_project/test/test_config.rb')
      assert_file_exists('/tmp/sample_project/test/test.rake')
    end

    should "properly generate for riot" do
      buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--test=riot', '--script=none') }
      assert_match(/Applying.*?riot.*?test/, buffer)
      assert_match_in_file(/gem 'rack-test'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/:require => "rack\/test"/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/:group => "test"/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/gem 'riot'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/include Rack::Test::Methods/, '/tmp/sample_project/test/test_config.rb')
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, '/tmp/sample_project/test/test_config.rb')
      assert_match_in_file(/Riot::Situation/, '/tmp/sample_project/test/test_config.rb')
      assert_match_in_file(/Riot::Context/, '/tmp/sample_project/test/test_config.rb')
      assert_match_in_file(/SampleProject\.tap/, '/tmp/sample_project/test/test_config.rb')
      assert_file_exists('/tmp/sample_project/test/test.rake')
    end

    should "properly generate for rspec" do
      buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--test=rspec', '--script=none') }
      assert_match(/Applying.*?rspec.*?test/, buffer)
      assert_match_in_file(/gem 'rack-test'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/:require => "rack\/test"/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/:group => "test"/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/gem 'rspec'.*?:require => "spec"/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, '/tmp/sample_project/spec/spec_helper.rb')
      assert_match_in_file(/Spec::Runner/, '/tmp/sample_project/spec/spec_helper.rb')
      assert_file_exists('/tmp/sample_project/spec/spec.rake')
    end

    should "properly generate for shoulda" do
      buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--test=shoulda', '--script=none') }
      assert_match(/Applying.*?shoulda.*?test/, buffer)
      assert_match_in_file(/gem 'rack-test'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/:require => "rack\/test"/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/:group => "test"/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/gem 'shoulda'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, '/tmp/sample_project/test/test_config.rb')
      assert_match_in_file(/Test::Unit::TestCase/, '/tmp/sample_project/test/test_config.rb')
      assert_file_exists('/tmp/sample_project/test/test.rake')
    end

    should "properly generate for testspec" do
      buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--test=testspec', '--script=none') }
      assert_match(/Applying.*?testspec.*?test/, buffer)
      assert_match_in_file(/gem 'rack-test'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/:require => "rack\/test"/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/:group => "test"/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/gem 'test-spec'.*?:require => "test\/spec"/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, '/tmp/sample_project/test/test_config.rb')
      assert_match_in_file(/Test::Unit::TestCase/, '/tmp/sample_project/test/test_config.rb')
      assert_file_exists('/tmp/sample_project/test/test.rake')
    end

    should "properly generate for cucumber" do
      buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--test=cucumber', '--script=none') }
      assert_match(/Applying.*?cucumber.*?test/, buffer)
      assert_match_in_file(/gem 'rack-test'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/:require => "rack\/test"/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/:group => "test"/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/gem 'rspec'.*?:require => "spec"/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/gem 'cucumber'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/gem 'capybara'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, '/tmp/sample_project/spec/spec_helper.rb')
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, '/tmp/sample_project/features/support/env.rb')
      assert_match_in_file(/Spec::Runner/, '/tmp/sample_project/spec/spec_helper.rb')
      assert_match_in_file(/Capybara.app = /, '/tmp/sample_project/features/support/env.rb')
      assert_match_in_file(/World\(Cucumber::Web::URLs\)/, '/tmp/sample_project/features/support/url.rb')
      assert_file_exists('/tmp/sample_project/spec/spec.rake')
      assert_file_exists('/tmp/sample_project/features/support/env.rb')
      assert_file_exists('/tmp/sample_project/features/add.feature')
      assert_file_exists('/tmp/sample_project/features/step_definitions/add_steps.rb')
    end
  end

  context "the generator for stylesheet component" do
    should "properly generate for sass" do
      buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--renderer=haml','--script=none','--stylesheet=sass') }
      assert_match_in_file(/gem 'haml'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/module SassInitializer.*Sass::Plugin::Rack/m, '/tmp/sample_project/lib/sass_init.rb')
      assert_match_in_file(/register SassInitializer/m, '/tmp/sample_project/app/app.rb')
      assert_dir_exists('/tmp/sample_project/app/stylesheets')
    end

    should "properly generate for less" do
      buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--renderer=haml','--script=none','--stylesheet=less') }
      assert_match_in_file(/gem 'less'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/gem 'rack-less'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/module LessInitializer.*Rack::Less/m, '/tmp/sample_project/lib/less_init.rb')
      assert_match_in_file(/register LessInitializer/m, '/tmp/sample_project/app/app.rb')
      assert_dir_exists('/tmp/sample_project/app/stylesheets')
    end

    should "properly generate for compass" do
      buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--renderer=haml','--script=none','--stylesheet=compass') }
      assert_match_in_file(/gem 'compass'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/Compass.configure_sass_plugin\!/, '/tmp/sample_project/lib/compass_plugin.rb')
      assert_match_in_file(/module CompassInitializer.*Sass::Plugin::Rack/m, '/tmp/sample_project/lib/compass_plugin.rb')
      assert_match_in_file(/register CompassInitializer/m, '/tmp/sample_project/app/app.rb')

      assert_file_exists('/tmp/sample_project/app/stylesheets/application.scss')
      assert_file_exists('/tmp/sample_project/app/stylesheets/partials/_base.scss')
    end

    should "properly generate for scss" do
      buffer = silence_logger { generate(:project, 'sample_project', '--root=/tmp', '--renderer=haml','--script=none','--stylesheet=scss') }
      assert_match_in_file(/gem 'haml'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/module ScssInitializer.*Sass::Plugin::Rack/m, '/tmp/sample_project/lib/scss_init.rb')
      assert_match_in_file(/Sass::Plugin.options\[:syntax\] = :scss/m, '/tmp/sample_project/lib/scss_init.rb')
      assert_match_in_file(/register ScssInitializer/m, '/tmp/sample_project/app/app.rb')
      assert_dir_exists('/tmp/sample_project/app/stylesheets')
    end
    
  end
end
