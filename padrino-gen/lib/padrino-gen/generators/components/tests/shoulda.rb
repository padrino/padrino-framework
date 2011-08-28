SHOULDA_SETUP = (<<-TEST).gsub(/^ {10}/, '') unless defined?(SHOULDA_SETUP)
PADRINO_ENV = 'test' unless defined?(PADRINO_ENV)
require File.expand_path(File.dirname(__FILE__) + "/../config/boot")

class Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    ##
    # You can handle all padrino applications using instead:
    #   Padrino.application
    CLASS_NAME.tap { |app|  }
  end
end
TEST

SHOULDA_CONTROLLER_TEST = (<<-TEST).gsub(/^ {10}/, '') unless defined?(SHOULDA_CONTROLLER_TEST)
require File.expand_path(File.dirname(__FILE__) + '/../../test_config.rb')

class !NAME!ControllerTest < Test::Unit::TestCase
  context "!NAME!Controller" do
    setup do
      get '/'
    end

    should "return hello world text" do
      assert_equal "Hello World", last_response.body
    end
  end
end
TEST

SHOULDA_RAKE = (<<-TEST).gsub(/^ {10}/, '') unless defined?(SHOULDA_RAKE)
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

SHOULDA_MODEL_TEST = (<<-TEST).gsub(/^ {10}/, '') unless defined?(SHOULDA_MODEL_TEST)
require File.expand_path(File.dirname(__FILE__) + '!PATH!/test_config.rb')

class !NAME!Test < Test::Unit::TestCase
  context "!NAME! Model" do
    should 'construct new instance' do
      @!DNAME! = !NAME!.new
      assert_not_nil @!DNAME!
    end
  end
end
TEST

def setup_test
  require_dependencies 'rack-test', :require => 'rack/test', :group => 'test'
  require_dependencies 'shoulda', :group => 'test'
  insert_test_suite_setup SHOULDA_SETUP
  if options[:orm] == "activerecord"
    inject_into_file destination_root("test/test_config.rb"), "require 'shoulda/active_record'\n\n", :before => /class.*?\n/
  end
  create_file destination_root("test/test.rake"), SHOULDA_RAKE
end

# Generates a controller test given the controllers name
def generate_controller_test(name)
  shoulda_contents = SHOULDA_CONTROLLER_TEST.gsub(/!NAME!/, name.to_s.camelize)
  controller_test_path = File.join('test',options[:app],'controllers',"#{name.to_s.underscore}_controller_test.rb")
  create_file destination_root(controller_test_path), shoulda_contents, :skip => true
end

def generate_model_test(name)
  shoulda_contents = SHOULDA_MODEL_TEST.gsub(/!NAME!/, name.to_s.camelize).gsub(/!DNAME!/, name.to_s.underscore)
  path = options[:app] == '.' ? '/..' : '/../..'
  shoulda_contents.gsub!(/!PATH!/,path)
  model_test_path = File.join('test',options[:app],'models',"#{name.to_s.underscore}_test.rb")
  create_file destination_root(model_test_path), shoulda_contents, :skip => true
end
