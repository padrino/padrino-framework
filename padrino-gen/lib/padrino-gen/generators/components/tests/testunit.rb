TESTUNIT_SETUP = (<<-TEST).gsub(/^ {10}/, '') unless defined?(TESTUNIT_SETUP)
RACK_ENV = 'test' unless defined?(RACK_ENV)
require File.expand_path(File.dirname(__FILE__) + "/../config/boot")
Dir[File.expand_path(File.dirname(__FILE__) + "/../app/helpers/**/*.rb")].each(&method(:require))

class Test::Unit::TestCase
  include Rack::Test::Methods

  # You can use this method to custom specify a Rack app
  # you want rack-test to invoke:
  #
  #   app CLASS_NAME
  #   app CLASS_NAME.tap { |a| }
  #   app(CLASS_NAME) do
  #     set :foo, :bar
  #   end
  #
  def app(app = nil, &blk)
    @app ||= block_given? ? app.instance_eval(&blk) : app
    @app ||= Padrino.application
  end
end
TEST

TESTUNIT_RAKE = (<<-TEST).gsub(/^ {10}/, '') unless defined?(TESTUNIT_RAKE)
require 'rake/testtask'

test_tasks = Dir['test/*/'].map { |d| File.basename(d) }

test_tasks.each do |folder|
  Rake::TestTask.new("test:\#{folder}") do |test|
    test.pattern = "test/\#{folder}/**/*_test.rb"
    test.verbose = true
  end
end

desc "Run application test suite"
task 'test' => test_tasks.map { |f| "test:\#{f}" }

task :default => :test
TEST

TESTUNIT_CONTROLLER_TEST = (<<-TEST).gsub(/^ {10}/, '') unless defined?(TESTUNIT_CONTROLLER_TEST)
require File.expand_path(File.dirname(__FILE__) + '/../../test_config.rb')

class !NAME!ControllerTest < Test::Unit::TestCase
  def setup
    get "/"
  end

  def test_returns_hello_world_text
    assert_equal "Hello World", last_response.body
  end
end
TEST

TESTUNIT_MODEL_TEST = (<<-TEST).gsub(/^ {10}/, '') unless defined?(TESTUNIT_MODEL_TEST)
require File.expand_path(File.dirname(__FILE__) + '!PATH!/test_config.rb')

class !NAME!Test < Test::Unit::TestCase
  def test_constructs_a_new_instance
    @!DNAME! = !NAME!.new
    refute_nil @!DNAME!
  end
end
TEST

TESTUNIT_HELPER_TEST = (<<-TEST) unless defined?(TESTUNIT_HELPER_TEST)
require File.expand_path(File.dirname(__FILE__) + '!PATH!/test_config.rb')

class !NAME!Test < Test::Unit::TestCase
  def self.setup
    @helpers = Class.new
    @helpers.extend !CONSTANT_NAME!
  end

  def helpers
    @helpers
  end

  def test_foo_helper
    assert_equal nil, helpers.foo
  end
end
TEST

def setup_test
  require_dependencies 'rack-test', :require => 'rack/test', :group => 'test'
  require_dependencies 'test-unit', :require => 'test/unit', :group => 'test'
  insert_test_suite_setup TESTUNIT_SETUP
  create_file destination_root("test/test.rake"), TESTUNIT_RAKE
end

def generate_controller_test(name, path)
  test_unit_contents = TESTUNIT_CONTROLLER_TEST.gsub(/!NAME!/, name.to_s.underscore.camelize)
  controller_test_path = File.join('test',options[:app],'controllers',"#{name.to_s.underscore}_controller_test.rb")
  create_file destination_root(controller_test_path), test_unit_contents, :skip => true
end

def generate_model_test(name)
  test_unit_contents = TESTUNIT_MODEL_TEST.gsub(/!NAME!/, name.to_s.underscore.camelize).gsub(/!DNAME!/, name.to_s.underscore)
  test_unit_contents.gsub!(/!PATH!/, recognize_path)
  model_test_path = File.join('test',options[:app],'models',"#{name.to_s.underscore}_test.rb")
  create_file destination_root(model_test_path), test_unit_contents, :skip => true
end

def generate_helper_test(name, project_name, app_name)
  test_unit_contents = TESTUNIT_HELPER_TEST.gsub(/!NAME!/, name).gsub(/!CONSTANT_NAME!/, "#{project_name}::#{app_name}::#{name}")
  test_unit_contents.gsub!(/!PATH!/, recognize_path)
  helper_spec_path = File.join('test', options[:app], 'helpers', "#{name.underscore}_test.rb")
  create_file destination_root(helper_spec_path), test_unit_contents, :skip => true
end
