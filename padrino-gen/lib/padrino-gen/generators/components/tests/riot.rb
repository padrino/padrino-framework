RIOT_SETUP = (<<-TEST).gsub(/^ {10}/, '') unless defined?(RIOT_SETUP)
RACK_ENV = 'test' unless defined?(RACK_ENV)
require File.expand_path(File.dirname(__FILE__) + "/../config/boot")
Dir[File.expand_path("../../app/helpers/**/*.rb", __FILE__)].each(&method(:require))

# Specify your app using the #app helper inside a context.
# Takes either an app class or a block argument.
# app { Padrino.application }
# app { CLASS_NAME.tap { |app| } }

class Riot::Situation
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

class Riot::Context
end

TEST

RIOT_CONTROLLER_TEST = (<<-TEST).gsub(/^ {10}/, '') unless defined?(RIOT_CONTROLLER_TEST)
require File.expand_path(File.dirname(__FILE__) + '/../../test_config.rb')

context "!NAME!Controller" do
  context "description here" do
    setup do
      get "/"
    end

    asserts("the response body") { last_response.body }.equals "Hello World"
  end
end
TEST

RIOT_RAKE = (<<-TEST).gsub(/^ {10}/, '') unless defined?(RIOT_RAKE)
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
TEST

RIOT_MODEL_TEST = (<<-TEST).gsub(/^ {10}/, '') unless defined?(RIOT_MODEL_TEST)
require File.expand_path(File.dirname(__FILE__) + '!PATH!/test_config.rb')

context "!NAME! Model" do
  context 'can be created' do
    setup do
      !NAME!.new
    end

    asserts("that record is not nil") { !topic.nil? }
  end
end
TEST

RIOT_HELPER_TEST = (<<-TEST) unless defined?(RIOT_HELPER_TEST)
require File.expand_path(File.dirname(__FILE__) + '!PATH!/test_config.rb')

describe "!NAME!" do
  setup do
    helpers = Class.new
    helpers.extend !NAME!
    [helpers.foo]
  end

  asserts("#foo"){ topic.first }.nil
end
TEST

def setup_test
  require_dependencies 'rack-test', :require => 'rack/test', :group => 'test'
  require_dependencies 'riot', :group => 'test'
  insert_test_suite_setup RIOT_SETUP
  create_file destination_root("test/test.rake"), RIOT_RAKE
end

def generate_controller_test(name)
  riot_contents = RIOT_CONTROLLER_TEST.gsub(/!NAME!/, name.to_s.underscore.camelize)
  controller_test_path = File.join('test',options[:app],'controllers',"#{name.to_s.underscore}_controller_test.rb")
  create_file destination_root(controller_test_path), riot_contents, :skip => true
end

def generate_model_test(name)
  riot_contents = RIOT_MODEL_TEST.gsub(/!NAME!/, name.to_s.underscore.camelize)
  riot_contents.gsub!(/!PATH!/, recognize_path)
  model_test_path = File.join('test',options[:app],'models',"#{name.to_s.underscore}_test.rb")
  create_file destination_root(model_test_path), riot_contents, :skip => true
end

def generate_helper_test(name, project_name, app_name)
  riot_contents = RIOT_HELPER_TEST.gsub(/!NAME!/, "#{project_name}::#{app_name}::#{name}")
  riot_contents.gsub!(/!PATH!/, recognize_path)
  helper_spec_path = File.join('test', options[:app], 'helpers', "#{name.underscore}_test.rb")
  create_file destination_root(helper_spec_path), riot_contents, :skip => true
end
