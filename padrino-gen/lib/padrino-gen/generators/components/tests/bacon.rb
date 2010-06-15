BACON_SETUP = (<<-TEST).gsub(/^ {10}/, '') unless defined?(BACON_SETUP)
PADRINO_ENV = 'test' unless defined?(PADRINO_ENV)
require File.expand_path(File.dirname(__FILE__) + "/../config/boot")

class Bacon::Context
  include Rack::Test::Methods
end

def app
  ##
  # You can handle all padrino applications using instead:
  #   Padrino.application
  CLASS_NAME.tap { |app|  }
end
TEST

BACON_CONTROLLER_TEST = (<<-TEST).gsub(/^ {10}/, '') unless defined?(BACON_CONTROLLER_TEST)
require File.expand_path(File.dirname(__FILE__) + '/../test_config.rb')

describe "!NAME!Controller" do
  it 'returns text at root' do
    get "/"
    last_response.body.should == "some text"
  end
end
TEST

BACON_RAKE = (<<-TEST).gsub(/^ {10}/, '') unless defined?(BACON_RAKE)
require 'rake/testtask'

Rake::TestTask.new(:test) do |test|
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end
TEST

BACON_MODEL_TEST = (<<-TEST).gsub(/^ {10}/, '') unless defined?(BACON_MODEL_TEST)
require File.expand_path(File.dirname(__FILE__) + '/../test_config.rb')

describe "!NAME! Model" do
  it 'can be created' do
    @!DNAME! = !NAME!.new
    @!DNAME!.should.not.be.nil
  end
end
TEST

# Setup the testing configuration helper and dependencies
def setup_test
  require_dependencies 'rack-test', :require => 'rack/test', :group => 'test'
  require_dependencies 'bacon', :group => 'test'
  insert_test_suite_setup BACON_SETUP, :path => 'test/test_config.rb'
  create_file destination_root("test/test.rake"), BACON_RAKE
end

# Generates a controller test given the controllers name
def generate_controller_test(name)
  bacon_contents = BACON_CONTROLLER_TEST.gsub(/!NAME!/, name.to_s.camelize)
  create_file destination_root("test/controllers/","#{name.to_s.underscore}_controller_test.rb"), bacon_contents, :skip => true
end

def generate_model_test(name)
  bacon_contents = BACON_MODEL_TEST.gsub(/!NAME!/, name.to_s.camelize).gsub(/!DNAME!/, name.to_s.underscore)
  create_file destination_root("test/models/#{name.to_s.underscore}_test.rb"), bacon_contents, :skip => true
end