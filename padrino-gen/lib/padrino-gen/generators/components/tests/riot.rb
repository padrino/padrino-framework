RIOT_SETUP = (<<-TEST).gsub(/^ {10}/, '') unless defined?(RIOT_SETUP)
PADRINO_ENV = 'test' unless defined?(PADRINO_ENV)
require File.expand_path(File.dirname(__FILE__) + "/../config/boot")

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
  path = options[:app] == '.' ? '/..' : '/../..'
  riot_contents.gsub!(/!PATH!/,path)
  model_test_path = File.join('test',options[:app],'models',"#{name.to_s.underscore}_test.rb")
  create_file destination_root(model_test_path), riot_contents, :skip => true
end
