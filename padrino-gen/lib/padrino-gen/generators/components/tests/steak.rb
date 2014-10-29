STEAK_SETUP = (<<-TEST).gsub(/^ {12}/, '') unless defined?(STEAK_SETUP)
RACK_ENV = 'test' unless defined?(RACK_ENV)
require File.expand_path(File.dirname(__FILE__) + "/../config/boot")
Dir[File.expand_path(File.dirname(__FILE__) + "/../app/helpers/**/*.rb")].each(&method(:require))

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
  conf.include Capybara
end

def app
  ##
  # You can handle all padrino applications using instead:
  #   Padrino.application
  CLASS_NAME.tap { |app|  }
end

Capybara.app = app
TEST

STEAK_CONTROLLER_TEST = (<<-TEST).gsub(/^ {12}/, '') unless defined?(STEAK_CONTROLLER_TEST)
require 'spec_helper'

describe "!PATH!" do
  before do
    get "!EXPANDED_PATH!"
  end

  it "returns hello world" do
    last_response.body.should == "Hello World"
  end
end
TEST

STEAK_CONTROLLER_ACCEPTANCE_TEST = (<<-TEST).gsub(/^ {12}/, '') unless defined?(STEAK_CONTROLLER_ACCEPTANCE_TEST)
require 'spec_helper'

feature "!PATH!" do
  background do
    visit "!EXPANDED_PATH!"
  end

  scenario "returns hello world" do
    page.should.have_content == "Hello World"
  end
end
TEST

STEAK_RAKE = (<<-TEST).gsub(/^ {12}/, '') unless defined?(STEAK_RAKE)
require 'rspec/core/rake_task'

spec_tasks = Dir['spec/*/'].map { |d| File.basename(d) }

spec_tasks.each do |folder|
  RSpec::Core::RakeTask.new("spec:\#{folder}") do |t|
    t.pattern = "./spec/\#{folder}/**/*_spec.rb"
    t.rspec_opts = %w(-fs --color)
  end
end

desc "Run complete application spec suite"
task 'spec' => spec_tasks.map { |f| "spec:\#{f}" }
TEST

STEAK_MODEL_TEST = (<<-TEST).gsub(/^ {12}/, '') unless defined?(STEAK_MODEL_TEST)
require 'spec_helper'

describe !NAME! do
end
TEST

STEAK_HELPER_TEST = <<-TEST unless defined?(STEAK_HELPER_TEST)
require 'spec_helper'

describe "!NAME!" do
  let(:helpers){ Class.new }
  before { helpers.extend !NAME! }
  subject { helpers }

  it "should return nil" do
    expect(subject.foo).to be_nil
  end
end
TEST

def setup_test
  require_dependencies 'rack-test', :require => 'rack/test', :group => 'test'
  require_dependencies 'steak', :group => 'test'
  insert_test_suite_setup STEAK_SETUP, :path => "spec/spec_helper.rb"
  create_file destination_root("spec/spec.rake"), STEAK_RAKE
end

# Generates a controller test given the controllers name
def generate_controller_test(name, path)
  spec_contents = STEAK_CONTROLLER_TEST.gsub(/!PATH!/, path).gsub(/!EXPANDED_PATH!/, path.gsub(/:\w+?_id/, "1"))
  controller_spec_path = File.join('spec',options[:app],'controllers',"#{name.to_s.underscore}_controller_spec.rb")
  create_file destination_root(controller_spec_path), spec_contents, :skip => true

  acceptance_contents = STEAK_CONTROLLER_ACCEPTANCE_TEST.gsub(/!PATH!/, path).gsub(/!EXPANDED_PATH!/, path.gsub(/:\w+?_id/, "1"))
  controller_acceptance_path = File.join('spec',options[:app],'acceptance','controllers',"#{name.to_s.underscore}_controller_spec.rb")
  create_file destination_root(controller_acceptance_path), acceptance_contents, :skip => true
end

def generate_model_test(name)
  rspec_contents = STEAK_MODEL_TEST.gsub(/!NAME!/, name.to_s.underscore.camelize).gsub(/!DNAME!/, name.to_s.underscore)
  model_spec_path = File.join('spec',options[:app],'models',"#{name.to_s.underscore}_spec.rb")
  create_file destination_root(model_spec_path), rspec_contents, :skip => true
end

def generate_helper_test(name, project_name, app_name)
  rspec_contents = STEAK_HELPER_TEST.gsub(/!NAME!/, "#{project_name}::#{app_name}::#{name}")
  helper_spec_path = File.join('spec', options[:app], 'helpers', "#{name.underscore}_spec.rb")
  create_file destination_root(helper_spec_path), rspec_contents, :skip => true
end
