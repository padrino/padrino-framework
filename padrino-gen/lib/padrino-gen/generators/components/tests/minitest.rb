MINITEST_SETUP = (<<-TEST).gsub(/^ {10}/, '') unless defined?(MINITEST_SETUP)
PADRINO_ENV = 'test' unless defined?(PADRINO_ENV)
require File.expand_path('../../config/boot', __FILE__)

class MiniTest::Unit::TestCase
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

MINITEST_RAKE = (<<-TEST).gsub(/^ {10}/, '') unless defined?(MINITEST_RAKE)
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

MINITEST_CONTROLLER_TEST = (<<-TEST).gsub(/^ {10}/, '') unless defined?(MINITEST_CONTROLLER_TEST)
require File.expand_path(File.dirname(__FILE__) + '/../../test_config.rb')

describe "!NAME!Controller" do
  before do
    get '/'
  end

  it "should return hello world text" do
    assert_equal "Hello World", last_response.body
  end
end
TEST

MINITEST_MODEL_TEST = (<<-TEST).gsub(/^ {10}/, '') unless defined?(MINITEST_MODEL_TEST)
require File.expand_path(File.dirname(__FILE__) + '!PATH!/test_config.rb')

describe "!NAME! Model" do
  it 'can construct a new instance' do
    @!DNAME! = !NAME!.new
    refute_nil @!DNAME!
  end
end
TEST

def setup_test
  require_dependencies 'rack-test', :require => 'rack/test', :group => 'test'
  require_dependencies 'minitest', :version => "~>2.6.0", :require => 'minitest/autorun', :group => 'test'
  insert_test_suite_setup MINITEST_SETUP
  create_file destination_root("test/test.rake"), MINITEST_RAKE
end

def generate_controller_test(name)
  minitest_contents = MINITEST_CONTROLLER_TEST.gsub(/!NAME!/, name.to_s.underscore.camelize)
  controller_test_path = File.join('test',options[:app],'controllers',"#{name.to_s.underscore}_controller_test.rb")
  create_file destination_root(controller_test_path), minitest_contents, :skip => true
end

def generate_model_test(name)
  minitest_contents = MINITEST_MODEL_TEST.gsub(/!NAME!/, name.to_s.underscore.camelize).gsub(/!DNAME!/, name.to_s.underscore)
  path = options[:app] == '.' ? '/..' : '/../..'
  minitest_contents.gsub!(/!PATH!/,path)
  model_test_path = File.join('test',options[:app],'models',"#{name.to_s.underscore}_test.rb")
  create_file destination_root(model_test_path), minitest_contents, :skip => true
end
