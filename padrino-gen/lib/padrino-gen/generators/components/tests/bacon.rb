BACON_SETUP = (<<-TEST).gsub(/^ {10}/, '') unless defined?(BACON_SETUP)
RACK_ENV = 'test' unless defined?(RACK_ENV)
require File.expand_path(File.dirname(__FILE__) + "/../config/boot")
Dir[File.expand_path(File.dirname(__FILE__) + "/../app/helpers/**/*.rb")].each(&method(:require))

class Bacon::Context
  include Rack::Test::Methods
end

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
TEST

BACON_CONTROLLER_TEST = (<<-TEST).gsub(/^ {10}/, '') unless defined?(BACON_CONTROLLER_TEST)
require File.expand_path(File.dirname(__FILE__) + '/../../test_config.rb')

describe "!PATH!" do
  it 'returns text at root' do
    get "!EXPANDED_PATH!"
    last_response.body.should == "some text"
  end
end
TEST

BACON_RAKE = (<<-TEST).gsub(/^ {10}/, '') unless defined?(BACON_RAKE)
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

BACON_MODEL_TEST = (<<-TEST).gsub(/^ {10}/, '') unless defined?(BACON_MODEL_TEST)
require File.expand_path(File.dirname(__FILE__) + '!PATH!/test_config.rb')

describe "!NAME! Model" do
  it 'can be created' do
    @!DNAME! = !NAME!.new
    @!DNAME!.should.not.be.nil
  end
end
TEST

BACON_HELPER_TEST = <<-TEST unless defined?(BACON_HELPER_TEST)
require File.expand_path(File.dirname(__FILE__) + '!PATH!/test_config.rb')

describe "!NAME!" do
  before do
    @helpers = Class.new
    @helpers.extend !NAME!
  end

  it "should return nil" do
    @helpers.foo.should.equal nil
  end
end
TEST

def setup_test
  require_dependencies 'rack-test', :require => 'rack/test', :group => 'test'
  require_dependencies 'bacon', :group => 'test'
  insert_test_suite_setup BACON_SETUP, :path => 'test/test_config.rb'
  create_file destination_root("test/test.rake"), BACON_RAKE
end

def generate_controller_test(name, path)
  bacon_contents       = BACON_CONTROLLER_TEST.gsub(/!PATH!/, path).gsub(/!EXPANDED_PATH!/, path.gsub(/:\w+?_id/, "1"))
  controller_test_path = File.join('test',options[:app],'controllers',"#{name.to_s.underscore}_controller_test.rb")
  create_file destination_root(controller_test_path), bacon_contents, :skip => true
end

def generate_model_test(name)
  bacon_contents  = BACON_MODEL_TEST.gsub(/!NAME!/, name.to_s.underscore.camelize).gsub(/!DNAME!/, name.to_s.underscore)
  bacon_contents.gsub!(/!PATH!/, recognize_path)
  model_test_path = File.join('test',options[:app],'models',"#{name.to_s.underscore}_test.rb")
  create_file destination_root(model_test_path), bacon_contents, :skip => true
end

def generate_helper_test(name, project_name, app_name)
  bacon_contents = BACON_HELPER_TEST.gsub(/!NAME!/, "#{project_name}::#{app_name}::#{name}")
  bacon_contents.gsub!(/!PATH!/, recognize_path)
  helper_spec_path = File.join('test', options[:app], 'helpers', "#{name.underscore}_test.rb")
  create_file destination_root(helper_spec_path), bacon_contents, :skip => true
end
