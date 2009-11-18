require File.dirname(__FILE__) + '/helper'
require 'thor'

class TestSkeletonGenerator < Test::Unit::TestCase
  def setup
    `rm -rf /tmp/sample_app`
  end

  context 'the skeleton generator' do
    should "allow simple generator to run and create base_app with no options" do
      assert_nothing_raised { silence_logger { Padrino::Generators::Skeleton.start(['sample_app', '/tmp', '--script=none']) } }
      assert File.exist?('/tmp/sample_app')
      assert File.exist?('/tmp/sample_app/app')
      assert File.exist?('/tmp/sample_app/config/boot.rb')
      assert File.exist?('/tmp/sample_app/test/test_config.rb')
    end
    should "place app specific names into correct files" do
      silence_logger { Padrino::Generators::Skeleton.start(['sample_app', '/tmp', '--script=none']) }
      assert_match_in_file(/class SampleApp < Padrino::Application/m, '/tmp/sample_app/app.rb')
      assert_match_in_file(/Padrino.mount_core\(:app_class => "SampleApp"\)/m, '/tmp/sample_app/config/apps.rb')
      assert_match_in_file(/SampleApp::urls do/m, '/tmp/sample_app/config/urls.rb')
    end
    should "create components file containing options chosen with defaults" do
      silence_logger { Padrino::Generators::Skeleton.start(['sample_app', '/tmp']) }
      components_chosen = YAML.load_file('/tmp/sample_app/.components')
      assert_equal 'datamapper', components_chosen[:orm]
      assert_equal 'bacon', components_chosen[:test]
      assert_equal 'mocha', components_chosen[:mock]
      assert_equal 'jquery', components_chosen[:script]
      assert_equal 'erb', components_chosen[:renderer]
    end
    should "create components file containing options chosen" do
      component_options = ['--orm=datamapper', '--test=riot', '--mock=mocha', '--script=prototype', '--renderer=erb']
      silence_logger { Padrino::Generators::Skeleton.start(['sample_app', '/tmp', *component_options]) }
      components_chosen = YAML.load_file('/tmp/sample_app/.components')
      assert_equal 'datamapper', components_chosen[:orm]
      assert_equal 'riot',  components_chosen[:test]
      assert_equal 'mocha',     components_chosen[:mock]
      assert_equal 'prototype', components_chosen[:script]
      assert_equal 'erb',   components_chosen[:renderer]
    end
    should "output to log components being applied" do
      component_options = ['--orm=datamapper', '--test=riot', '--mock=mocha', '--script=prototype', '--renderer=erb']
      buffer = silence_logger { Padrino::Generators::Skeleton.start(['sample_app', '/tmp', *component_options]) }
      assert_match /Applying.*?datamapper.*?orm/, buffer
      assert_match /Applying.*?riot.*?test/, buffer
      assert_match /Applying.*?mocha.*?mock/, buffer
      assert_match /Applying.*?prototype.*?script/, buffer
      assert_match /Applying.*?erb.*?renderer/, buffer
    end
    should "output gem files for base app" do
      silence_logger { Padrino::Generators::Skeleton.start(['sample_app', '/tmp', '--script=none']) }
      assert_match_in_file(/gem 'sinatra'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/gem 'padrino'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/gem 'rack-flash'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/gem 'rack-test'/, '/tmp/sample_app/Gemfile')
    end
  end

  context "a generator for mock component" do
    should "properly generate for rr" do
      buffer = silence_logger { Padrino::Generators::Skeleton.start(['sample_app', '/tmp', '--mock=rr', '--script=none']) }
      assert_match /Applying.*?rr.*?mock/, buffer
      assert_match_in_file(/gem 'rr'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/include RR::Adapters::RRMethods/m, '/tmp/sample_app/test/test_config.rb')
    end

    should "properly generate default for mocha" do
      buffer = silence_logger { Padrino::Generators::Skeleton.start(['sample_app', '/tmp', '--mock=mocha', '--script=none']) }
      assert_match /Applying.*?mocha.*?mock/, buffer
      assert_match_in_file(/gem 'mocha'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/include Mocha::API/m, '/tmp/sample_app/test/test_config.rb')
    end
  end

  context "the generator for orm components" do
    should "properly generate for sequel" do
      Padrino::Generators::Skeleton.instance_eval("undef setup_orm if respond_to?('setup_orm')")
      buffer = silence_logger { Padrino::Generators::Skeleton.start(['sample_app', '/tmp', '--orm=sequel', '--script=none']) }
      assert_match /Applying.*?sequel.*?orm/, buffer
      assert_match_in_file(/gem 'sequel'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/Sequel.connect/, '/tmp/sample_app/config/database.rb')
    end

    should "properly generate for activerecord" do
      buffer = silence_logger { Padrino::Generators::Skeleton.start(['sample_app', '/tmp', '--orm=activerecord', '--script=none']) }
      assert_match /Applying.*?activerecord.*?orm/, buffer
      assert_match_in_file(/gem 'activerecord'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/Migrate the database/, '/tmp/sample_app/Rakefile')
      assert_match_in_file(/ActiveRecord::Base.establish_connection/, '/tmp/sample_app/config/database.rb')
    end

    should "properly generate default for datamapper" do
      buffer = silence_logger { Padrino::Generators::Skeleton.start(['sample_app', '/tmp', '--orm=datamapper', '--script=none']) }
      assert_match /Applying.*?datamapper.*?orm/, buffer
      assert_match_in_file(/gem 'dm-core'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/DataMapper.setup/, '/tmp/sample_app/config/database.rb')
    end

    should "properly generate for mongomapper" do
      buffer = silence_logger { Padrino::Generators::Skeleton.start(['sample_app', '/tmp', '--orm=mongomapper', '--script=none']) }
      assert_match /Applying.*?mongomapper.*?orm/, buffer
      assert_match_in_file(/gem 'mongo_mapper'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/MongoMapper.database/, '/tmp/sample_app/config/database.rb')
    end

    should "properly generate for couchrest" do
      buffer = silence_logger { Padrino::Generators::Skeleton.start(['sample_app', '/tmp', '--orm=couchrest', '--script=none']) }
      assert_match /Applying.*?couchrest.*?orm/, buffer
      assert_match_in_file(/gem 'couchrest'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/CouchRest.database!/, '/tmp/sample_app/config/database.rb')    
    end
  end

  context "the generator for renderer component" do
    should "properly generate default for erb" do
      buffer = silence_logger { Padrino::Generators::Skeleton.start(['sample_app', '/tmp', '--renderer=erb', '--script=none']) }
      assert_match /Applying.*?erb.*?renderer/, buffer
      assert_match_in_file(/gem 'erubis'/, '/tmp/sample_app/Gemfile')
    end

    should "properly generate for haml" do
      buffer = silence_logger { Padrino::Generators::Skeleton.start(['sample_app', '/tmp', '--renderer=haml','--script=none']) }
      assert_match /Applying.*?haml.*?renderer/, buffer
      assert_match_in_file(/gem 'haml'/, '/tmp/sample_app/Gemfile')
    end
  end

  context "the generator for script component" do
    should "properly generate for jquery" do
      buffer = silence_logger { Padrino::Generators::Skeleton.start(['sample_app', '/tmp', '--script=jquery']) }
      assert_match /Applying.*?jquery.*?script/, buffer
      assert File.exist?('/tmp/sample_app/public/javascripts/jquery.min.js')
    end

    should "properly generate for prototype" do
      buffer = silence_logger { Padrino::Generators::Skeleton.start(['sample_app', '/tmp', '--script=prototype']) }
      assert_match /Applying.*?prototype.*?script/, buffer
      assert File.exist?('/tmp/sample_app/public/javascripts/prototype.js')
      assert File.exist?('/tmp/sample_app/public/javascripts/lowpro.js')
    end

    should "properly generate for rightjs" do
      buffer = silence_logger { Padrino::Generators::Skeleton.start(['sample_app', '/tmp', '--script=rightjs']) }
      assert_match /Applying.*?rightjs.*?script/, buffer
      assert File.exist?('/tmp/sample_app/public/javascripts/right-min.js')
    end
  end

  context "the generator for test component" do
    should "properly default generate for bacon" do
      buffer = silence_logger { Padrino::Generators::Skeleton.start(['sample_app', '/tmp', '--test=bacon', '--script=none']) }
      assert_match /Applying.*?bacon.*?test/, buffer
      assert_match_in_file(/gem 'bacon'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/Bacon::Context/, '/tmp/sample_app/test/test_config.rb')
    end

    should "properly generate for riot" do
      buffer = silence_logger { Padrino::Generators::Skeleton.start(['sample_app', '/tmp', '--test=riot', '--script=none']) }
      assert_match /Applying.*?riot.*?test/, buffer
      assert_match_in_file(/gem 'riot'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/Riot::Situation/, '/tmp/sample_app/test/test_config.rb')
    end

    should "properly generate for rspec" do
      buffer = silence_logger { Padrino::Generators::Skeleton.start(['sample_app', '/tmp', '--test=rspec', '--script=none']) }
      assert_match /Applying.*?rspec.*?test/, buffer
      assert_match_in_file(/gem 'spec'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/Spec::Runner/, '/tmp/sample_app/test/test_config.rb')
    end

    should "properly generate for shoulda" do
      buffer = silence_logger { Padrino::Generators::Skeleton.start(['sample_app', '/tmp', '--test=shoulda', '--script=none']) }
      assert_match /Applying.*?shoulda.*?test/, buffer
      assert_match_in_file(/gem 'shoulda'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/Test::Unit::TestCase/, '/tmp/sample_app/test/test_config.rb')
    end

    should "properly generate for testspec" do
      buffer = silence_logger { Padrino::Generators::Skeleton.start(['sample_app', '/tmp', '--test=testspec', '--script=none']) }
      assert_match /Applying.*?testspec.*?test/, buffer
      assert_match_in_file(/gem 'test\/spec'/, '/tmp/sample_app/Gemfile')
      assert_match_in_file(/Test::Unit::TestCase/, '/tmp/sample_app/test/test_config.rb')
    end
  end
end
