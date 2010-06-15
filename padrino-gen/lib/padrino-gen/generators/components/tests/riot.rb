RIOT_SETUP = (<<-TEST).gsub(/^ {10}/, '') unless defined?(RIOT_SETUP)
PADRINO_ENV = 'test' unless defined?(PADRINO_ENV)
require File.expand_path(File.dirname(__FILE__) + "/../config/boot")

# Specify your app using the #app helper inside a context.
# If you don't specify one, Riot::Rack will recursively look for a config.ru file.
# Takes either an app class or a block argument.
# app { Padrino.application }
# app { CLASS_NAME.tap { |app| } }

class Riot::Situation
  include Rack::Test::Methods

  # The Rack app under test.
  def app
    defined?(@app) ? @app : build_app
  end

  private

  def build_app
    config_file = File.read(find_config_file)
    Rack::Builder.new { instance_eval(config_file) }.to_app
  end

  def find_config_file
    if Dir.glob("config.ru").length > 0
      File.join(Dir.pwd,"config.ru")
    elsif Dir.pwd != "/"
      Dir.chdir("..") { find_config_file }
    else
      raise "Cannot find config.ru"
    end
  end
end

class Riot::Context
  # Set the Rack app which is to be tested.
  #
  #   context "MyApp" do
  #     app { [200, {}, "Hello!"] }
  #     setup { get '/' }
  #     asserts(:status).equals(200)
  #   end
  def app(app=nil, &block)
    setup { @app = (app || block) }
  end
end

TEST

RIOT_CONTROLLER_TEST = (<<-TEST).gsub(/^ {10}/, '') unless defined?(RIOT_CONTROLLER_TEST)
require File.expand_path(File.dirname(__FILE__) + '/../test_config.rb')

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

Rake::TestTask.new(:test) do |test|
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end
TEST

RIOT_MODEL_TEST = (<<-TEST).gsub(/^ {10}/, '') unless defined?(RIOT_MODEL_TEST)
require File.expand_path(File.dirname(__FILE__) + '/../test_config.rb')

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

# Generates a controller test given the controllers name
def generate_controller_test(name)
  riot_contents = RIOT_CONTROLLER_TEST.gsub(/!NAME!/, name.to_s.camelize)
  create_file destination_root("test/controllers/#{name.to_s.underscore}_controller_test.rb"), riot_contents, :skip => true
end

def generate_model_test(name)
  riot_contents = RIOT_MODEL_TEST.gsub(/!NAME!/, name.to_s.camelize)
  create_file destination_root("test/models/#{name.to_s.underscore}_test.rb"), riot_contents, :skip => true
end
