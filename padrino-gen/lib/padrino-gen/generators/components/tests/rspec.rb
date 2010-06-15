RSPEC_SETUP = (<<-TEST).gsub(/^ {12}/, '') unless defined?(RSPEC_SETUP)
PADRINO_ENV = 'test' unless defined?(PADRINO_ENV)
require File.expand_path(File.dirname(__FILE__) + "/../config/boot")

Spec::Runner.configure do |conf|
  conf.include Rack::Test::Methods
end

def app
  ##
  # You can handle all padrino applications using instead:
  #   Padrino.application
  CLASS_NAME.tap { |app|  }
end
TEST

RSPEC_CONTROLLER_TEST = (<<-TEST).gsub(/^ {12}/, '') unless defined?(RSPEC_CONTROLLER_TEST)
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe "!NAME!Controller" do
  before do
    get "/"
  end

  it "returns hello world" do
    last_response.body.should == "Hello World"
  end
end
TEST

RSPEC_RAKE = (<<-TEST).gsub(/^ {12}/, '') unless defined?(RSPEC_RAKE)
require 'spec/rake/spectask'

Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_files = Dir['spec/**/*_spec.rb']
  t.spec_opts  = %w(-fs --color)
end
TEST

RSPEC_MODEL_TEST = (<<-TEST).gsub(/^ {12}/, '') unless defined?(RSPEC_MODEL_TEST)
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe "!NAME! Model" do
  it 'can be created' do
    @!DNAME! = !NAME!.new
    @!DNAME!.should_not be_nil
  end
end
TEST

def setup_test
  require_dependencies 'rack-test', :require => 'rack/test', :group => 'test'
  require_dependencies 'rspec', :require => 'spec', :group => 'test'
  insert_test_suite_setup RSPEC_SETUP, :path => "spec/spec_helper.rb"
  create_file destination_root("spec/spec.rake"), RSPEC_RAKE
end

# Generates a controller test given the controllers name
def generate_controller_test(name)
  rspec_contents = RSPEC_CONTROLLER_TEST.gsub(/!NAME!/, name.to_s.camelize)
  create_file destination_root("spec/controllers/#{name.to_s.underscore}_controller_spec.rb"), rspec_contents, :skip => true
end

def generate_model_test(name)
  rspec_contents = RSPEC_MODEL_TEST.gsub(/!NAME!/, name.to_s.camelize).gsub(/!DNAME!/, name.to_s.underscore)
  create_file destination_root("spec/models/#{name.to_s.underscore}_spec.rb"), rspec_contents, :skip => true
end