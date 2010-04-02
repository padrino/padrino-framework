require File.expand_path(File.dirname(__FILE__) + '/helper')
require 'thor/group'
require 'fakeweb'

class TestProjectGenerator < Test::Unit::TestCase
  def setup
    FakeWeb.allow_net_connect = false
    `rm -rf /tmp/sample_project`
    @project = Padrino::Generators::Project.dup
  end

  context 'the project generator' do
    should "allow simple generator to run and create base_app with no options" do
      assert_nothing_raised { silence_logger { @project.start(['sample_project', '--root=/tmp', '--script=none']) } }
      assert_file_exists('/tmp/sample_project')
      assert_file_exists('/tmp/sample_project/app')
      assert_file_exists('/tmp/sample_project/config/boot.rb')
      assert_file_exists('/tmp/sample_project/spec/spec_helper.rb')
      assert_file_exists('/tmp/sample_project/public/favicon.ico')
    end

    should "not create models folder if no orm is chosen" do
      silence_logger { @project.start(['sample_project', '--root=/tmp', '--script=none', '--orm=none']) }
      assert_no_dir_exists('/tmp/sample_project/app/models')
    end

    should "not create tests folder if no test framework is chosen" do
      silence_logger { @project.start(['sample_project', '--root=/tmp', '--script=none', '--test=none']) }
      assert_no_dir_exists('/tmp/sample_project/test')
    end

    should "place app specific names into correct files" do
      silence_logger { @project.start(['sample_project', '--root=/tmp', '--script=none']) }
      assert_match_in_file(/class SampleProject < Padrino::Application/m, '/tmp/sample_project/app/app.rb')
      assert_match_in_file(/Padrino.mount_core\("SampleProject"\)/m, '/tmp/sample_project/config/apps.rb')
    end

    should "create components file containing options chosen with defaults" do
      silence_logger { @project.start(['sample_project', '--root=/tmp']) }
      components_chosen = YAML.load_file('/tmp/sample_project/.components')
      assert_equal 'none', components_chosen[:orm]
      assert_equal 'rspec', components_chosen[:test]
      assert_equal 'none', components_chosen[:mock]
      assert_equal 'none', components_chosen[:script]
      assert_equal 'haml', components_chosen[:renderer]
    end

    should "create components file containing options chosen" do
      component_options = ['--orm=datamapper', '--test=riot', '--mock=mocha', '--script=prototype', '--renderer=erb', '--stylesheet=less']
      silence_logger { @project.start(['sample_project', '--root=/tmp', *component_options]) }
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
      buffer = silence_logger { @project.start(['sample_project', '--root=/tmp', *component_options]) }
      assert_match /Applying.*?datamapper.*?orm/, buffer
      assert_match /Applying.*?riot.*?test/, buffer
      assert_match /Applying.*?mocha.*?mock/, buffer
      assert_match /Applying.*?prototype.*?script/, buffer
      assert_match /Applying.*?erb.*?renderer/, buffer
      assert_match /Applying.*?less.*?stylesheet/, buffer
    end

    should "output gem files for base app" do
      silence_logger { @project.start(['sample_project', '--root=/tmp', '--script=none']) }
      assert_match_in_file(/gem 'padrino'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/gem 'rack-flash'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/gem 'rack-test'/, '/tmp/sample_project/Gemfile')
    end
  end

  context "a generator for mock component" do
    should "properly generate for rr and riot" do
      buffer = silence_logger { @project.start(['sample_project', '--root=/tmp', '--mock=rr', '--test=riot', '--script=none']) }
      assert_match /Applying.*?rr.*?mock/, buffer
      assert_match_in_file(/gem 'rr'/, '/tmp/sample_project/Gemfile')
    end

    should "properly generater for rr and bacon" do
      buffer = silence_logger { @project.start(['sample_project', '--root=/tmp', '--mock=rr', '--test=bacon', '--script=none']) }
      assert_match /Applying.*?rr.*?mock/, buffer
      assert_match_in_file(/gem 'rr'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/RR::Adapters::RRMethods/m, '/tmp/sample_project/test/test_config.rb')
    end

    should "properly generate for mocha and rspec" do
      buffer = silence_logger { @project.start(['sample_project', '--root=/tmp', '--mock=mocha', '--script=none']) }
      assert_match /Applying.*?mocha.*?mock/, buffer
      assert_match_in_file(/gem 'mocha'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/conf.mock_with :mocha/m, '/tmp/sample_project/spec/spec_helper.rb')
    end

    should "properly generate for rr and rspec" do
      buffer = silence_logger { @project.start(['sample_project', '--root=/tmp', '--mock=rr', '--script=none']) }
      assert_match /Applying.*?rr.*?mock/, buffer
      assert_match_in_file(/gem 'rr'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/conf.mock_with :rr/m, '/tmp/sample_project/spec/spec_helper.rb')
    end

  end

  context "the generator for orm components" do
    should "properly generate for sequel" do
      @app.instance_eval("undef setup_orm if respond_to?('setup_orm')")
      buffer = silence_logger { @project.start(['sample_project', '--root=/tmp', '--orm=sequel', '--script=none']) }
      assert_match /Applying.*?sequel.*?orm/, buffer
      assert_match_in_file(/gem 'sequel'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/gem 'sqlite3'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/Sequel.connect/, '/tmp/sample_project/config/database.rb')
      assert_match_in_file(%r{sqlite://}, '/tmp/sample_project/config/database.rb')
      assert_dir_exists('/tmp/sample_project/app/models')
    end

    should "properly generate for activerecord" do
      buffer = silence_logger { @project.start(['sample_project', '--root=/tmp', '--orm=activerecord', '--script=none']) }
      assert_match /Applying.*?activerecord.*?orm/, buffer
      assert_match_in_file(/gem 'activerecord', :require => "active_record"/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/ActiveRecord::Base.establish_connection/, '/tmp/sample_project/config/database.rb')
      assert_dir_exists('/tmp/sample_project/app/models')
    end

    should "properly generate default for datamapper" do
      buffer = silence_logger { @project.start(['sample_project', '--root=/tmp', '--orm=datamapper', '--script=none']) }
      assert_match /Applying.*?datamapper.*?orm/, buffer
      assert_match_in_file(/gem 'data_objects'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/gem 'datamapper'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/DataMapper.setup/, '/tmp/sample_project/config/database.rb')
      assert_dir_exists('/tmp/sample_project/app/models')
    end

    should "properly generate for mongomapper" do
      buffer = silence_logger { @project.start(['sample_project', '--root=/tmp', '--orm=mongomapper', '--script=none']) }
      assert_match /Applying.*?mongomapper.*?orm/, buffer
      assert_match_in_file(/gem 'mongo_mapper'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/MongoMapper.database/, '/tmp/sample_project/config/database.rb')
      assert_dir_exists('/tmp/sample_project/app/models')
    end

    should "properly generate for couchrest" do
      buffer = silence_logger { @project.start(['sample_project', '--root=/tmp', '--orm=couchrest', '--script=none']) }
      assert_match /Applying.*?couchrest.*?orm/, buffer
      assert_match_in_file(/gem 'couchrest'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/CouchRest.database!/, '/tmp/sample_project/config/database.rb')
      assert_dir_exists('/tmp/sample_project/app/models')
    end
  end

  context "the generator for renderer component" do
    should "properly generate default for erb" do
      buffer = silence_logger { @project.start(['sample_project', '--root=/tmp', '--renderer=erb', '--script=none']) }
      assert_match /Applying.*?erb.*?renderer/, buffer
    end

    should "properly generate for haml" do
      buffer = silence_logger { @project.start(['sample_project', '--root=/tmp', '--renderer=haml','--script=none']) }
      assert_match /Applying.*?haml.*?renderer/, buffer
      assert_match_in_file(/gem 'haml'/, '/tmp/sample_project/Gemfile')
    end
  end

  context "the generator for script component" do
    should "properly generate for jquery" do
      buffer = silence_logger { @project.start(['sample_project', '--root=/tmp', '--script=jquery']) }
      assert_match /Applying.*?jquery.*?script/, buffer
      assert_file_exists('/tmp/sample_project/public/javascripts/jquery.js')
      assert_file_exists('/tmp/sample_project/public/javascripts/application.js')
    end

    should "properly generate for mootools" do
      buffer = silence_logger { @project.start(['sample_project', '--root=/tmp', '--script=mootools']) }
      assert_match /Applying.*?mootools.*?script/, buffer
      assert_file_exists('/tmp/sample_project/public/javascripts/mootools-core.js')
      assert_file_exists('/tmp/sample_project/public/javascripts/application.js')
    end

    should "properly generate for prototype" do
      buffer = silence_logger { @project.start(['sample_project', '--root=/tmp', '--script=prototype']) }
      assert_match /Applying.*?prototype.*?script/, buffer
      assert_file_exists('/tmp/sample_project/public/javascripts/protopak.js')
      assert_file_exists('/tmp/sample_project/public/javascripts/lowpro.js')
      assert_file_exists('/tmp/sample_project/public/javascripts/application.js')
    end

    should "properly generate for rightjs" do
      buffer = silence_logger { @project.start(['sample_project', '--root=/tmp', '--script=rightjs']) }
      assert_match /Applying.*?rightjs.*?script/, buffer
      assert_file_exists('/tmp/sample_project/public/javascripts/right.js')
      assert_file_exists('/tmp/sample_project/public/javascripts/application.js')
    end
  end

  context "the generator for test component" do
    should "properly default generate for bacon" do
      buffer = silence_logger { @project.start(['sample_project', '--root=/tmp', '--test=bacon', '--script=none']) }
      assert_match /Applying.*?bacon.*?test/, buffer
      assert_match_in_file(/gem 'bacon'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, '/tmp/sample_project/test/test_config.rb')
      assert_match_in_file(/Bacon::Context/, '/tmp/sample_project/test/test_config.rb')
      assert_file_exists('/tmp/sample_project/test/test.rake')
    end

    should "properly generate for riot" do
      buffer = silence_logger { @project.start(['sample_project', '--root=/tmp', '--test=riot', '--script=none']) }
      assert_match /Applying.*?riot.*?test/, buffer
      assert_match_in_file(/gem 'riot'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, '/tmp/sample_project/test/test_config.rb')
      assert_match_in_file(/Riot::Situation/, '/tmp/sample_project/test/test_config.rb')
      assert_file_exists('/tmp/sample_project/test/test.rake')
    end

    should "properly generate for rspec" do
      buffer = silence_logger { @project.start(['sample_project', '--root=/tmp', '--test=rspec', '--script=none']) }
      assert_match /Applying.*?rspec.*?test/, buffer
      assert_match_in_file(/gem 'rspec'.*?:require => "spec"/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, '/tmp/sample_project/spec/spec_helper.rb')
      assert_match_in_file(/Spec::Runner/, '/tmp/sample_project/spec/spec_helper.rb')
      assert_file_exists('/tmp/sample_project/spec/spec.rake')
    end

    should "properly generate for shoulda" do
      buffer = silence_logger { @project.start(['sample_project', '--root=/tmp', '--test=shoulda', '--script=none']) }
      assert_match /Applying.*?shoulda.*?test/, buffer
      assert_match_in_file(/gem 'shoulda'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, '/tmp/sample_project/test/test_config.rb')
      assert_match_in_file(/Test::Unit::TestCase/, '/tmp/sample_project/test/test_config.rb')
      assert_file_exists('/tmp/sample_project/test/test.rake')
    end

    should "properly generate for testspec" do
      buffer = silence_logger { @project.start(['sample_project', '--root=/tmp', '--test=testspec', '--script=none']) }
      assert_match /Applying.*?testspec.*?test/, buffer
      assert_match_in_file(/gem 'test-spec'.*?:require => "test\/spec"/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, '/tmp/sample_project/test/test_config.rb')
      assert_match_in_file(/Test::Unit::TestCase/, '/tmp/sample_project/test/test_config.rb')
      assert_file_exists('/tmp/sample_project/test/test.rake')
    end

    should "properly generate for cucumber" do
      buffer = silence_logger { @project.start(['sample_project', '--root=/tmp', '--test=cucumber', '--script=none']) }
      assert_match /Applying.*?cucumber.*?test/, buffer
      assert_match_in_file(/gem 'rspec'.*?:require => "spec"/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/gem 'cucumber'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/gem 'capybara'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, '/tmp/sample_project/spec/spec_helper.rb')
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, '/tmp/sample_project/features/support/env.rb')
      assert_match_in_file(/Spec::Runner/, '/tmp/sample_project/spec/spec_helper.rb')
      assert_match_in_file(/Capybara.app = /, '/tmp/sample_project/features/support/env.rb')
      assert_file_exists('/tmp/sample_project/spec/spec.rake')
      assert_file_exists('/tmp/sample_project/features/support/env.rb')
      assert_file_exists('/tmp/sample_project/features/add.feature')
      assert_file_exists('/tmp/sample_project/features/step_definitions/add_steps.rb')
    end
  end

  context "the generator for stylesheet component" do
    should "properly generate for sass" do
      buffer = silence_logger { @project.start(['sample_project', '--root=/tmp', '--renderer=haml','--script=none','--stylesheet=sass']) }
      assert_match_in_file(/gem 'haml'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/module SassInitializer.*Sass::Plugin::Rack/m, '/tmp/sample_project/lib/sass.rb')
      assert_match_in_file(/register SassInitializer/m, '/tmp/sample_project/app/app.rb')
      assert_dir_exists('/tmp/sample_project/app/stylesheets')
    end

    should "properly generate for less" do
      buffer = silence_logger { @project.start(['sample_project', '--root=/tmp', '--renderer=haml','--script=none','--stylesheet=less']) }
      assert_match_in_file(/gem 'less'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/gem 'rack-less'/, '/tmp/sample_project/Gemfile')
      assert_match_in_file(/module LessInitializer.*Rack::Less/m, '/tmp/sample_project/lib/less.rb')
      assert_match_in_file(/register LessInitializer/m, '/tmp/sample_project/app/app.rb')
      assert_dir_exists('/tmp/sample_project/app/stylesheets')
    end
  end

end
