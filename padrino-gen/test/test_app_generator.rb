require File.dirname(__FILE__) + '/helper'
require 'thor/group'
require 'fakeweb'

class TestAppGenerator < Test::Unit::TestCase
  def setup
    Padrino::Generators.lockup!
    FakeWeb.allow_net_connect = false
    `rm -rf /tmp/sample_app`
    @app = Padrino::Generators::App.dup
  end

  context 'the App generator' do
    should "allow simple generator to run and create base_app with no options" do
      assert_nothing_raised { silence_logger { @app.start(['sample_app', '--root=/tmp', '--script=none']) } }
      assert_file_exists('/tmp/sample_app')
      assert_file_exists('/tmp/sample_app/app')
      assert_file_exists('/tmp/sample_app/config/boot.rb')
      assert_dir_exists('/tmp/sample_app/app/models')
      assert_file_exists('/tmp/sample_app/test/test_config.rb')
    end

    should "not create models folder if no orm is chosen" do
      silence_logger { @app.start(['sample_app', '--root=/tmp', '--script=none', '--orm=none']) }
      assert_no_dir_exists('/tmp/sample_app/app/models')
    end

    should "not create tests folder if no test framework is chosen" do
      silence_logger { @app.start(['sample_app', '--root=/tmp', '--script=none', '--test=none']) }
      assert_no_dir_exists('/tmp/sample_app/test')
    end

    should "place app specific names into correct files" do
      silence_logger { @app.start(['sample_app', '--root=/tmp', '--script=none']) }
      assert_match_in_file(/class SampleApp < Padrino::Application/m, '/tmp/sample_app/app/app.rb')
      assert_match_in_file(/Padrino.mount_core\("SampleApp"\)/m, '/tmp/sample_app/config/apps.rb')
    end

    should "create components file containing options chosen with defaults" do
      silence_logger { @app.start(['sample_app', '--root=/tmp']) }
      components_chosen = YAML.load_file('/tmp/sample_app/.components')
      assert_equal 'datamapper', components_chosen[:orm]
      assert_equal 'bacon', components_chosen[:test]
      assert_equal 'mocha', components_chosen[:mock]
      assert_equal 'jquery', components_chosen[:script]
      assert_equal 'erb', components_chosen[:renderer]
    end

    should "create components file containing options chosen" do
      component_options = ['--orm=datamapper', '--test=riot', '--mock=mocha', '--script=prototype', '--renderer=erb']
      silence_logger { @app.start(['sample_app', '--root=/tmp', *component_options]) }
      components_chosen = YAML.load_file('/tmp/sample_app/.components')
      assert_equal 'datamapper', components_chosen[:orm]
      assert_equal 'riot',  components_chosen[:test]
      assert_equal 'mocha',     components_chosen[:mock]
      assert_equal 'prototype', components_chosen[:script]
      assert_equal 'erb',   components_chosen[:renderer]
    end

    should "output to log components being applied" do
      component_options = ['--orm=datamapper', '--test=riot', '--mock=mocha', '--script=prototype', '--renderer=erb']
      buffer = silence_logger { @app.start(['sample_app', '--root=/tmp', *component_options]) }
      assert_match /Applying.*?datamapper.*?orm/, buffer
      assert_match /Applying.*?riot.*?test/, buffer
      assert_match /Applying.*?mocha.*?mock/, buffer
      assert_match /Applying.*?prototype.*?script/, buffer
      assert_match /Applying.*?erb.*?renderer/, buffer
    end

    should "output gem files for base app" do
      silence_logger { @app.start(['sample_app', '--root=/tmp', '--script=none']) }
      assert_match_in_file(/gem 'sinatra'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/gem 'padrino'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/gem 'rack-flash'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/gem 'rack-test'/, '/tmp/sample_app/Gemfile')
    end
  end

  context "a generator for mock component" do
    should "properly generate for rr" do
      buffer = silence_logger { @app.start(['sample_app', '--root=/tmp', '--mock=rr', '--test=riot', '--script=none']) }
      assert_match /Applying.*?rr.*?mock/, buffer
      assert_match_in_file(/gem 'rr'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/Riot.rr/m, '/tmp/sample_app/test/test_config.rb')
    end

    should "properly generate default for mocha" do
      buffer = silence_logger { @app.start(['sample_app', '--root=/tmp', '--mock=mocha', '--script=none']) }
      assert_match /Applying.*?mocha.*?mock/, buffer
      assert_match_in_file(/gem 'mocha'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/include Mocha::API/m, '/tmp/sample_app/test/test_config.rb')
    end
  end

  context "the generator for orm components" do
    should "properly generate for sequel" do
      @app.instance_eval("undef setup_orm if respond_to?('setup_orm')")
      buffer = silence_logger { @app.start(['sample_app', '--root=/tmp', '--orm=sequel', '--script=none']) }
      assert_match /Applying.*?sequel.*?orm/, buffer
      assert_match_in_file(/gem 'sequel'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/Sequel.connect/, '/tmp/sample_app/config/database.rb')
      assert_dir_exists('/tmp/sample_app/app/models')
    end

    should "properly generate for activerecord" do
      buffer = silence_logger { @app.start(['sample_app', '--root=/tmp', '--orm=activerecord', '--script=none']) }
      assert_match /Applying.*?activerecord.*?orm/, buffer
      assert_match_in_file(/gem 'activerecord', :require => "active_record"/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/ActiveRecord::Base.establish_connection/, '/tmp/sample_app/config/database.rb')
      assert_dir_exists('/tmp/sample_app/app/models')
    end

    should "properly generate default for datamapper" do
      buffer = silence_logger { @app.start(['sample_app', '--root=/tmp', '--orm=datamapper', '--script=none']) }
      assert_match /Applying.*?datamapper.*?orm/, buffer
      assert_match_in_file(/gem 'dm-core'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/DataMapper.setup/, '/tmp/sample_app/config/database.rb')
      assert_dir_exists('/tmp/sample_app/app/models')
    end

    should "properly generate for mongomapper" do
      buffer = silence_logger { @app.start(['sample_app', '--root=/tmp', '--orm=mongomapper', '--script=none']) }
      assert_match /Applying.*?mongomapper.*?orm/, buffer
      assert_match_in_file(/gem 'mongo_mapper'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/MongoMapper.database/, '/tmp/sample_app/config/database.rb')
      assert_dir_exists('/tmp/sample_app/app/models')
    end

    should "properly generate for couchrest" do
      buffer = silence_logger { @app.start(['sample_app', '--root=/tmp', '--orm=couchrest', '--script=none']) }
      assert_match /Applying.*?couchrest.*?orm/, buffer
      assert_match_in_file(/gem 'couchrest'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/CouchRest.database!/, '/tmp/sample_app/config/database.rb')
      assert_dir_exists('/tmp/sample_app/app/models')
    end
  end

  context "the generator for renderer component" do
    should "properly generate default for erb" do
      buffer = silence_logger { @app.start(['sample_app', '--root=/tmp', '--renderer=erb', '--script=none']) }
      assert_match /Applying.*?erb.*?renderer/, buffer
      assert_match_in_file(/gem 'erubis'/, '/tmp/sample_app/Gemfile')
    end

    should "properly generate for haml" do
      buffer = silence_logger { @app.start(['sample_app', '--root=/tmp', '--renderer=haml','--script=none']) }
      assert_match /Applying.*?haml.*?renderer/, buffer
      assert_match_in_file(/gem 'haml'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/module SassInitializer.*Sass::Plugin::Rack/m, '/tmp/sample_app/config/initializers/sass.rb')
    end
  end

  context "the generator for script component" do
    should "properly generate for jquery" do
      buffer = silence_logger { @app.start(['sample_app', '--root=/tmp', '--script=jquery']) }
      assert_match /Applying.*?jquery.*?script/, buffer
      assert_file_exists('/tmp/sample_app/public/javascripts/jquery.js')
      assert_file_exists('/tmp/sample_app/public/javascripts/application.js')
    end

    should "properly generate for prototype" do
      buffer = silence_logger { @app.start(['sample_app', '--root=/tmp', '--script=prototype']) }
      assert_match /Applying.*?prototype.*?script/, buffer
      assert_file_exists('/tmp/sample_app/public/javascripts/protopak.js')
      assert_file_exists('/tmp/sample_app/public/javascripts/lowpro.js')
      assert_file_exists('/tmp/sample_app/public/javascripts/application.js')
    end

    should "properly generate for rightjs" do
      buffer = silence_logger { @app.start(['sample_app', '--root=/tmp', '--script=rightjs']) }
      assert_match /Applying.*?rightjs.*?script/, buffer
      assert_file_exists('/tmp/sample_app/public/javascripts/right.js')
      assert_file_exists('/tmp/sample_app/public/javascripts/application.js')
    end
  end

  context "the generator for test component" do
    should "properly default generate for bacon" do
      buffer = silence_logger { @app.start(['sample_app', '--root=/tmp', '--test=bacon', '--script=none']) }
      assert_match /Applying.*?bacon.*?test/, buffer
      assert_match_in_file(/gem 'bacon'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, '/tmp/sample_app/test/test_config.rb')
      assert_match_in_file(/Bacon::Context/, '/tmp/sample_app/test/test_config.rb')
    end

    should "properly generate for riot" do
      buffer = silence_logger { @app.start(['sample_app', '--root=/tmp', '--test=riot', '--script=none']) }
      assert_match /Applying.*?riot.*?test/, buffer
      assert_match_in_file(/gem 'riot'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, '/tmp/sample_app/test/test_config.rb')
      assert_match_in_file(/Riot::Situation/, '/tmp/sample_app/test/test_config.rb')
    end

    should "properly generate for rspec" do
      buffer = silence_logger { @app.start(['sample_app', '--root=/tmp', '--test=rspec', '--script=none']) }
      assert_match /Applying.*?rspec.*?test/, buffer
      assert_match_in_file(/gem 'rspec'.*?:require => "spec"/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, '/tmp/sample_app/test/test_config.rb')
      assert_match_in_file(/Spec::Runner/, '/tmp/sample_app/test/test_config.rb')
    end

    should "properly generate for shoulda" do
      buffer = silence_logger { @app.start(['sample_app', '--root=/tmp', '--test=shoulda', '--script=none']) }
      assert_match /Applying.*?shoulda.*?test/, buffer
      assert_match_in_file(/gem 'shoulda'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, '/tmp/sample_app/test/test_config.rb')
      assert_match_in_file(/Test::Unit::TestCase/, '/tmp/sample_app/test/test_config.rb')
    end

    should "properly generate for testspec" do
      buffer = silence_logger { @app.start(['sample_app', '--root=/tmp', '--test=testspec', '--script=none']) }
      assert_match /Applying.*?testspec.*?test/, buffer
      assert_match_in_file(/gem 'test\/spec'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/PADRINO_ENV = 'test' unless defined\?\(PADRINO_ENV\)/, '/tmp/sample_app/test/test_config.rb')
      assert_match_in_file(/Test::Unit::TestCase/, '/tmp/sample_app/test/test_config.rb')
    end
  end
end
