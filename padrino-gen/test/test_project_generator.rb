require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestProjectGenerator < Test::Unit::TestCase
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
      assert_nothing_raised { silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}") } }
      assert_file_exists("#{@apptmp}/sample_project")
      assert_match_in_file(/class SampleProject < Padrino::Application/,"#{@apptmp}/sample_project/app/app.rb")
      assert_match_in_file(/Padrino.mount\("SampleProject"\).to\('\/'\)/,"#{@apptmp}/sample_project/config/apps.rb")
      assert_file_exists("#{@apptmp}/sample_project/config/boot.rb")
      assert_file_exists("#{@apptmp}/sample_project/public/favicon.ico")
      assert_dir_exists("#{@apptmp}/sample_project/public/images")
      assert_dir_exists("#{@apptmp}/sample_project/public/javascripts")
      assert_dir_exists("#{@apptmp}/sample_project/public/stylesheets")
      assert_dir_exists("#{@apptmp}/sample_project/app/views")
      assert_dir_exists("#{@apptmp}/sample_project/app/views/layouts")
    end

    should "generate a valid name" do
      silence_logger { generate(:project, 'project.com', "--root=#{@apptmp}") }
      assert_file_exists("#{@apptmp}/project.com")
      assert_match_in_file(/class ProjectCom < Padrino::Application/,  "#{@apptmp}/project.com/app/app.rb")
      assert_match_in_file(/Padrino.mount\("ProjectCom"\).to\('\/'\)/, "#{@apptmp}/project.com/config/apps.rb")
      silence_logger { generate(:app, 'ws-dci-2011', "--root=#{@apptmp}/project.com") }
      assert_file_exists("#{@apptmp}/project.com/wsdci2011")
      assert_match_in_file(/class WsDci2011 < Padrino::Application/,  "#{@apptmp}/project.com/wsdci2011/app.rb")
      assert_match_in_file(/Padrino.mount\("WsDci2011"\).to\("\/wsdci2011"\)/, "#{@apptmp}/project.com/config/apps.rb")
    end

    should "raise an Error when given invalid constant names" do
      assert_raise(::NameError) { silence_logger { generate(:project, "123asdf", "--root=#{@apptmp}") } }
      assert_raise(::NameError) { silence_logger { generate(:project, "./sample_project", "--root=#{@apptmp}") } }
    end

    should "display the right path" do
      buffer = silence_logger { generate(:project, 'project', "--root=/tmp") }
      assert_file_exists("/tmp/project")
      assert_match(/cd \/tmp\/project/, buffer)
    end

    should "allow specifying alternate application name" do
      assert_nothing_raised { silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--app=base_app') } }
      assert_file_exists("#{@apptmp}/sample_project")
      assert_match_in_file(/class BaseApp < Padrino::Application/,"#{@apptmp}/sample_project/app/app.rb")
      assert_match_in_file(/Padrino.mount\("BaseApp"\).to\('\/'\)/,"#{@apptmp}/sample_project/config/apps.rb")
      assert_file_exists("#{@apptmp}/sample_project/config/boot.rb")
      assert_file_exists("#{@apptmp}/sample_project/public/favicon.ico")
    end

    should "generate tiny skeleton" do
      assert_nothing_raised { silence_logger { generate(:project,'sample_project', '--tiny',"--root=#{@apptmp}") } }
      assert_file_exists("#{@apptmp}/sample_project")
      assert_file_exists("#{@apptmp}/sample_project/app")
      assert_file_exists("#{@apptmp}/sample_project/app/controllers.rb")
      assert_file_exists("#{@apptmp}/sample_project/app/helpers.rb")
      assert_file_exists("#{@apptmp}/sample_project/app/mailers.rb")
      assert_dir_exists("#{@apptmp}/sample_project/public/images")
      assert_dir_exists("#{@apptmp}/sample_project/public/javascripts")
      assert_dir_exists("#{@apptmp}/sample_project/public/stylesheets")
      assert_dir_exists("#{@apptmp}/sample_project/app/views/mailers")
      assert_dir_exists("#{@apptmp}/sample_project/app/views/layouts")
      assert_match_in_file(/:notifier/,"#{@apptmp}/sample_project/app/mailers.rb")
      assert_no_file_exists("#{@apptmp}/sample_project/demo/helpers")
      assert_no_file_exists("#{@apptmp}/sample_project/demo/controllers")
    end

    should "not create models folder if no orm is chosen" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '--orm=none') }
      assert_no_dir_exists("#{@apptmp}/sample_project/app/models")
    end

    should "not create tests folder if no test framework is chosen" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '--test=none') }
      assert_no_dir_exists("#{@apptmp}/sample_project/test")
    end

    should "place app specific names into correct files" do
      silence_logger { generate(:project, 'warepedia', "--root=#{@apptmp}", '--script=none') }
      assert_match_in_file(/class Warepedia < Padrino::Application/m, "#{@apptmp}/warepedia/app/app.rb")
      assert_match_in_file(/Padrino.mount\("Warepedia"\).to\('\/'\)/m, "#{@apptmp}/warepedia/config/apps.rb")
    end

    should "store and apply session_secret" do
      silence_logger { generate(:project,'sample_project', '--tiny',"--root=#{@apptmp}") }
      assert_match_in_file(/set :session_secret, '[0-9A-z]*'/, "#{@apptmp}/sample_project/config/apps.rb")
    end

    should "create components file containing options chosen with defaults" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
      assert_equal 'none', components_chosen[:orm]
      assert_equal 'none', components_chosen[:test]
      assert_equal 'none', components_chosen[:mock]
      assert_equal 'none', components_chosen[:script]
      assert_equal 'haml', components_chosen[:renderer]
    end

    should "create components file containing options chosen" do
      component_options = ['--orm=datamapper', '--test=riot', '--mock=mocha', '--script=prototype', '--renderer=erb', '--stylesheet=less']
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", *component_options) }
      components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
      assert_equal 'datamapper', components_chosen[:orm]
      assert_equal 'riot',  components_chosen[:test]
      assert_equal 'mocha',     components_chosen[:mock]
      assert_equal 'prototype', components_chosen[:script]
      assert_equal 'erb',   components_chosen[:renderer]
      assert_equal 'less',  components_chosen[:stylesheet]
    end

    should "output to log components being applied" do
      component_options = ['--orm=datamapper', '--test=riot', '--mock=mocha', '--script=prototype', '--renderer=erb','--stylesheet=less']
      buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", *component_options) }
      assert_match(/Applying.*?datamapper.*?orm/, buffer)
      assert_match(/Applying.*?riot.*?test/, buffer)
      assert_match(/Applying.*?mocha.*?mock/, buffer)
      assert_match(/Applying.*?prototype.*?script/, buffer)
      assert_match(/Applying.*?erb.*?renderer/, buffer)
      assert_match(/Applying.*?less.*?stylesheet/, buffer)
    end

    should "output gem files for base app" do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none') }
      assert_match_in_file(/gem 'padrino'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'rack-flash'/, "#{@apptmp}/sample_project/Gemfile")
    end
  end

  context "a generator for mock component" do
    should "properly generate for rr and riot" do
      buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--mock=rr', '--test=riot', '--script=none') }
      assert_match(/Applying.*?rr.*?mock/, buffer)
      assert_match_in_file(/gem 'rr'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/require 'riot\/rr'/, "#{@apptmp}/sample_project/test/test_config.rb")
    end

    should "properly generater for rr and bacon" do
      buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--mock=rr', '--test=bacon', '--script=none') }
      assert_match(/Applying.*?rr.*?mock/, buffer)
      assert_match_in_file(/gem 'rr'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/RR::Adapters::RRMethods/m, "#{@apptmp}/sample_project/test/test_config.rb")
    end

    should "properly generate for mocha and rspec" do
      buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}",'--test=rspec', '--mock=mocha', '--script=none') }
      assert_match(/Applying.*?mocha.*?mock/, buffer)
      assert_match_in_file(/gem 'mocha'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/conf.mock_with :mocha/m, "#{@apptmp}/sample_project/spec/spec_helper.rb")
    end

    should "properly generate for rr and rspec" do
      buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=rspec', '--mock=rr', '--script=none') }
      assert_match(/Applying.*?rr.*?mock/, buffer)
      assert_match_in_file(/gem 'rr'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/conf.mock_with :rr/m, "#{@apptmp}/sample_project/spec/spec_helper.rb")
    end
  end

  context "the generator for orm components" do

    context "for sequel" do
      should "properly generate default" do
        @app.instance_eval("undef setup_orm if respond_to?('setup_orm')")
        buffer = silence_logger { generate(:project, 'project.com', "--root=#{@apptmp}", '--orm=sequel', '--script=none') }
        assert_match(/Applying.*?sequel.*?orm/, buffer)
        assert_match_in_file(/gem 'sequel'/, "#{@apptmp}/project.com/Gemfile")
        assert_match_in_file(/gem 'sqlite3'/, "#{@apptmp}/project.com/Gemfile")
        assert_match_in_file(/Sequel.connect/, "#{@apptmp}/project.com/config/database.rb")
        assert_match_in_file(%r{sqlite://}, "#{@apptmp}/project.com/config/database.rb")
        assert_match_in_file(%r{project_com}, "#{@apptmp}/project.com/config/database.rb")
        assert_dir_exists("#{@apptmp}/project.com/app/models")
      end

      should "properly generate mysql" do
        buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=sequel', '--adapter=mysql') }
        assert_match_in_file(/gem 'mysql'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(%r{"mysql://}, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
      end

      should "properly generate sqlite3" do
        buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=sequel', '--adapter=sqlite') }
        assert_match_in_file(/gem 'sqlite3'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(%r{sqlite://}, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
      end

      should "properly generate postgres" do
        buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=sequel', '--adapter=postgres') }
        assert_match_in_file(/gem 'pg'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(%r{"postgres://}, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
      end
    end

    context "for activerecord" do
      should "properly generate default" do
        buffer = silence_logger { generate(:project, 'project.com', "--root=#{@apptmp}", '--orm=activerecord', '--script=none') }
        assert_match(/Applying.*?activerecord.*?orm/, buffer)
        assert_match_in_file(/gem 'activerecord', :require => "active_record"/, "#{@apptmp}/project.com/Gemfile")
        assert_match_in_file(/gem 'sqlite3'/, "#{@apptmp}/project.com/Gemfile")
        assert_match_in_file(/ActiveRecord::Base.establish_connection/, "#{@apptmp}/project.com/config/database.rb")
        assert_match_in_file(/project_com/, "#{@apptmp}/project.com/config/database.rb")
        assert_dir_exists("#{@apptmp}/project.com/app/models")
      end

      should "properly generate mysql" do
        buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=activerecord','--adapter=mysql') }
        assert_match_in_file(/gem 'mysql'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(%r{:adapter   => 'mysql'}, "#{@apptmp}/sample_project/config/database.rb")
      end

      should "properly generate mysql2" do
        buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=activerecord','--adapter=mysql2') }
        assert_match_in_file(/gem 'mysql2'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(%r{:adapter   => 'mysql2'}, "#{@apptmp}/sample_project/config/database.rb")
      end

      should "properly generate sqlite3" do
        buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=activerecord', '--adapter=sqlite3') }
        assert_match_in_file(/gem 'sqlite3'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(/sample_project_development.db/, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(%r{:adapter => 'sqlite3'}, "#{@apptmp}/sample_project/config/database.rb")
      end

      should "properly generate postgres" do
        buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=activerecord', '--adapter=postgres') }
        assert_match_in_file(/gem 'pg', :require => "postgres"/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(%r{:adapter   => 'postgresql'}, "#{@apptmp}/sample_project/config/database.rb")
      end
    end

    context "for datamapper" do
      should "properly generate default" do
        buffer = silence_logger { generate(:project, 'project.com', "--root=#{@apptmp}", '--orm=datamapper', '--script=none') }
        assert_match(/Applying.*?datamapper.*?orm/, buffer)
        assert_match_in_file(/gem 'data_mapper'/, "#{@apptmp}/project.com/Gemfile")
        assert_match_in_file(/gem 'dm-sqlite-adapter'/, "#{@apptmp}/project.com/Gemfile")
        assert_match_in_file(/DataMapper.setup/, "#{@apptmp}/project.com/config/database.rb")
        assert_match_in_file(/project_com/, "#{@apptmp}/project.com/config/database.rb")
        assert_dir_exists("#{@apptmp}/project.com/app/models")
      end

      should "properly generate for mysql" do
        buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=datamapper', '--adapter=mysql') }
        assert_match_in_file(/gem 'dm-mysql-adapter'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(%r{"mysql://}, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
      end

      should "properly generate for sqlite" do
        buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=datamapper', '--adapter=sqlite') }
        assert_match_in_file(/gem 'dm-sqlite-adapter'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
      end

      should "properly generate for postgres" do
        buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=datamapper', '--adapter=postgres') }
        assert_match_in_file(/gem 'dm-postgres-adapter'/, "#{@apptmp}/sample_project/Gemfile")
        assert_match_in_file(%r{"postgres://}, "#{@apptmp}/sample_project/config/database.rb")
        assert_match_in_file(/sample_project_development/, "#{@apptmp}/sample_project/config/database.rb")
      end
    end

    should "properly generate for mongomapper" do
      buffer = silence_logger { generate(:project, 'project.com', "--root=#{@apptmp}", '--orm=mongomapper', '--script=none') }
      assert_match(/Applying.*?mongomapper.*?orm/, buffer)
      assert_match_in_file(/gem 'mongo_mapper'/, "#{@apptmp}/project.com/Gemfile")
      assert_match_in_file(/gem 'bson_ext'/, "#{@apptmp}/project.com/Gemfile")
      assert_match_in_file(/MongoMapper.database/, "#{@apptmp}/project.com/config/database.rb")
      assert_match_in_file(/project_com/, "#{@apptmp}/project.com/config/database.rb")
      assert_dir_exists("#{@apptmp}/project.com/app/models")
    end

    should "properly generate for mongoid" do
      buffer = silence_logger { generate(:project, 'project.com', "--root=#{@apptmp}", '--orm=mongoid', '--script=none') }
      assert_match(/Applying.*?mongoid.*?orm/, buffer)
      assert_match_in_file(/gem 'mongoid'/, "#{@apptmp}/project.com/Gemfile")
      assert_match_in_file(/gem 'bson_ext'/, "#{@apptmp}/project.com/Gemfile")
      assert_match_in_file(/Mongoid.database/, "#{@apptmp}/project.com/config/database.rb")
      assert_match_in_file(/project_com/, "#{@apptmp}/project.com/config/database.rb")
      assert_dir_exists("#{@apptmp}/project.com/app/models")
    end


    should "properly generate for couchrest" do
      buffer = silence_logger { generate(:project, 'project.com', "--root=#{@apptmp}", '--orm=couchrest', '--script=none') }
      assert_match(/Applying.*?couchrest.*?orm/, buffer)
      assert_match_in_file(/gem 'couchrest_model'/, "#{@apptmp}/project.com/Gemfile")
      assert_match_in_file(/CouchRest.database!/, "#{@apptmp}/project.com/config/database.rb")
      assert_match_in_file(/project_com/, "#{@apptmp}/project.com/config/database.rb")
      assert_dir_exists("#{@apptmp}/project.com/app/models")
    end

    should "properly generate for ohm" do
      buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=ohm', '--script=none') }
      assert_match(/Applying.*?ohm.*?orm/, buffer)
      assert_match_in_file(/gem 'json'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'ohm'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'ohm-contrib', :require => "ohm\/contrib"/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/Ohm.connect/, "#{@apptmp}/sample_project/config/database.rb")
      assert_dir_exists("#{@apptmp}/sample_project/app/models")
    end

    should "properly generate for mongomatic" do
      buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=mongomatic', '--script=none') }
      assert_match(/Applying.*?mongomatic.*?orm/, buffer)
      assert_match_in_file(/gem 'bson_ext'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'mongomatic'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/Mongomatic.db = Mongo::Connection.new.db/, "#{@apptmp}/sample_project/config/database.rb")
      assert_dir_exists("#{@apptmp}/sample_project/app/models")
    end

    should "properly generate for ripple" do
      buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=ripple', '--script=none') }
      assert_match(/Applying.*?ripple.*?orm/, buffer)
      assert_match_in_file(/gem 'ripple'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/Ripple.load_configuration/, "#{@apptmp}/sample_project/config/database.rb")
      assert_match_in_file(/http_port: 8098/, "#{@apptmp}/sample_project/config/riak.yml")
      assert_dir_exists("#{@apptmp}/sample_project/app/models")
    end
  end


  context "the generator for renderer component" do
    should "properly generate for erb" do
      buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--renderer=erb', '--script=none') }
      assert_match(/Applying.*?erb.*?renderer/, buffer)
      assert_match_in_file(/gem 'erubis'/, "#{@apptmp}/sample_project/Gemfile")
    end

    should "properly generate for haml" do
      buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--renderer=haml','--script=none') }
      assert_match(/Applying.*?haml.*?renderer/, buffer)
      assert_match_in_file(/gem 'haml'/, "#{@apptmp}/sample_project/Gemfile")
    end

    should "properly generate for liquid" do
      buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--renderer=liquid','--script=none') }
      assert_match(/Applying.*?liquid.*?renderer/,buffer)
      assert_match_in_file(/gem 'liquid'/, "#{@apptmp}/sample_project/Gemfile")
    end

    should "properly generate for slim" do
      buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--renderer=slim','--script=none') }
      assert_match(/Applying.*?slim.*?renderer/,buffer)
      assert_match_in_file(/gem 'slim'/, "#{@apptmp}/sample_project/Gemfile")
    end
  end

  context "the generator for script component" do
    should "properly generate for jquery" do
      buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=jquery') }
      assert_match(/Applying.*?jquery.*?script/, buffer)
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/jquery.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/jquery-ujs.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/application.js")
    end

    should "properly generate for mootools" do
      buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=mootools') }
      assert_match(/Applying.*?mootools.*?script/, buffer)
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/mootools.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/mootools-ujs.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/application.js")
    end

    should "properly generate for prototype" do
      buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=prototype') }
      assert_match(/Applying.*?prototype.*?script/, buffer)
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/protopak.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/lowpro.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/prototype-ujs.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/application.js")
    end

    should "properly generate for rightjs" do
      buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=rightjs') }
      assert_match(/Applying.*?rightjs.*?script/, buffer)
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/right.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/right-ujs.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/application.js")
    end

    should "properly generate for ext-core" do
      buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=extcore') }
      assert_match(/Applying.*?extcore.*?script/, buffer)
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/ext.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/ext-ujs.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/application.js")
    end

    should "properly generate for dojo" do
      buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=dojo') }
      assert_match(/Applying.*?dojo.*?script/, buffer)
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/dojo.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/dojo-ujs.js")
      assert_file_exists("#{@apptmp}/sample_project/public/javascripts/application.js")
    end
  end

  context "the generator for test component" do
    should "properly generate for bacon" do
      buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=bacon', '--script=none') }
      assert_match(/Applying.*?bacon.*?test/, buffer)
      assert_match_in_file(/gem 'rack-test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/:require => "rack\/test"/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/:group => "test"/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'bacon'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/Bacon::Context/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_file_exists("#{@apptmp}/sample_project/test/test.rake")
      assert_match_in_file(/Rake::TestTask.new\("test:\#/,"#{@apptmp}/sample_project/test/test.rake")
      assert_match_in_file(/task 'test' => test_tasks/,"#{@apptmp}/sample_project/test/test.rake")
    end

    should "properly generate for riot" do
      buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=riot', '--script=none') }
      assert_match(/Applying.*?riot.*?test/, buffer)
      assert_match_in_file(/gem 'rack-test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/:require => "rack\/test"/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/:group => "test"/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'riot'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/include Rack::Test::Methods/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_match_in_file(/Riot::Situation/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_match_in_file(/Riot::Context/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_match_in_file(/SampleProject\.tap/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_file_exists("#{@apptmp}/sample_project/test/test.rake")
      assert_match_in_file(/Rake::TestTask\.new\("test:\#/,"#{@apptmp}/sample_project/test/test.rake")
      assert_match_in_file(/task 'test' => test_tasks/,"#{@apptmp}/sample_project/test/test.rake")
    end

    should "properly generate for rspec" do
      buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=rspec', '--script=none') }
      assert_match(/Applying.*?rspec.*?test/, buffer)
      assert_match_in_file(/gem 'rack-test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/:require => "rack\/test"/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/:group => "test"/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'rspec'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, "#{@apptmp}/sample_project/spec/spec_helper.rb")
      assert_match_in_file(/RSpec.configure/, "#{@apptmp}/sample_project/spec/spec_helper.rb")
      assert_file_exists("#{@apptmp}/sample_project/spec/spec.rake")
      assert_match_in_file(/RSpec::Core::RakeTask\.new\("spec:\#/,"#{@apptmp}/sample_project/spec/spec.rake")
      assert_match_in_file(/task 'spec' => spec_tasks/,"#{@apptmp}/sample_project/spec/spec.rake")
    end

    should "properly generate for shoulda" do
      buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=shoulda', '--script=none') }
      assert_match(/Applying.*?shoulda.*?test/, buffer)
      assert_match_in_file(/gem 'rack-test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/:require => "rack\/test"/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/:group => "test"/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'shoulda'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_match_in_file(/Test::Unit::TestCase/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_file_exists("#{@apptmp}/sample_project/test/test.rake")
      assert_match_in_file(/Rake::TestTask\.new\("test:\#/,"#{@apptmp}/sample_project/test/test.rake")
      assert_match_in_file(/task 'test' => test_tasks/,"#{@apptmp}/sample_project/test/test.rake")
    end

    should "properly generate for testspec" do
      buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=testspec', '--script=none') }
      assert_match(/Applying.*?testspec.*?test/, buffer)
      assert_match_in_file(/gem 'rack-test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/:require => "rack\/test"/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/:group => "test"/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'test-spec'.*?:require => "test\/spec"/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_match_in_file(/Test::Unit::TestCase/, "#{@apptmp}/sample_project/test/test_config.rb")
      assert_match_in_file(/gem 'test-spec'.*?:require => "test\/spec"/, "#{@apptmp}/sample_project/Gemfile")
      assert_file_exists("#{@apptmp}/sample_project/test/test.rake")
      assert_match_in_file(/Rake::TestTask\.new\("test:\#/,"#{@apptmp}/sample_project/test/test.rake")
      assert_match_in_file(/task 'test' => test_tasks/,"#{@apptmp}/sample_project/test/test.rake")
    end

    should "properly generate for cucumber" do
      buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=cucumber', '--script=none') }
      assert_match(/Applying.*?cucumber.*?test/, buffer)
      assert_match_in_file(/gem 'rack-test'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/:require => "rack\/test"/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/:group => "test"/, "#{@apptmp}/sample_project/Gemfile")
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
      buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--renderer=haml','--script=none','--stylesheet=sass') }
      assert_match_in_file(/gem 'sass'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/module SassInitializer.*Sass::Plugin::Rack/m, "#{@apptmp}/sample_project/lib/sass_init.rb")
      assert_match_in_file(/register SassInitializer/m, "#{@apptmp}/sample_project/app/app.rb")
      assert_dir_exists("#{@apptmp}/sample_project/app/stylesheets")
    end

    should "properly generate for less" do
      buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--renderer=haml','--script=none','--stylesheet=less') }
      assert_match_in_file(/gem 'less'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'rack-less'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/module LessInitializer.*Rack::Less/m, "#{@apptmp}/sample_project/lib/less_init.rb")
      assert_match_in_file(/register LessInitializer/m, "#{@apptmp}/sample_project/app/app.rb")
      assert_dir_exists("#{@apptmp}/sample_project/app/stylesheets")
    end

    should "properly generate for compass" do
      buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--renderer=haml','--script=none','--stylesheet=compass') }
      assert_match_in_file(/gem 'compass'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/Compass.configure_sass_plugin\!/, "#{@apptmp}/sample_project/lib/compass_plugin.rb")
      assert_match_in_file(/module CompassInitializer.*Sass::Plugin::Rack/m, "#{@apptmp}/sample_project/lib/compass_plugin.rb")
      assert_match_in_file(/register CompassInitializer/m, "#{@apptmp}/sample_project/app/app.rb")

      assert_file_exists("#{@apptmp}/sample_project/app/stylesheets/application.scss")
      assert_file_exists("#{@apptmp}/sample_project/app/stylesheets/partials/_base.scss")
    end

    should "properly generate for scss" do
      buffer = silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '--renderer=haml','--script=none','--stylesheet=scss') }
      assert_match_in_file(/gem 'haml'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/module ScssInitializer.*Sass::Plugin::Rack/m, "#{@apptmp}/sample_project/lib/scss_init.rb")
      assert_match_in_file(/Sass::Plugin.options\[:syntax\] = :scss/m, "#{@apptmp}/sample_project/lib/scss_init.rb")
      assert_match_in_file(/register ScssInitializer/m, "#{@apptmp}/sample_project/app/app.rb")
      assert_dir_exists("#{@apptmp}/sample_project/app/stylesheets")
    end
  end
end
