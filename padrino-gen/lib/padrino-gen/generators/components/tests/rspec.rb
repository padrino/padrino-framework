RSPEC_SETUP = (<<-TEST).gsub(/^ {12}/, '') unless defined?(RSPEC_SETUP)
PADRINO_ENV = 'test' unless defined?(PADRINO_ENV)
require File.expand_path(File.dirname(__FILE__) + "/../config/boot")

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
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

RSPEC_CONTROLLER_TEST = (<<-TEST).gsub(/^ {12}/, '') unless defined?(RSPEC_CONTROLLER_TEST)
require 'spec_helper'

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
begin
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
rescue LoadError
  puts "RSpec is not part of this bundle, skip specs."
end
TEST

RSPEC_MODEL_TEST = (<<-TEST).gsub(/^ {12}/, '') unless defined?(RSPEC_MODEL_TEST)
require 'spec_helper'

describe !NAME! do
end
TEST

def setup_test
  require_dependencies 'rack-test', :require => 'rack/test', :group => 'test'
  require_dependencies 'rspec', :group => 'test'
  insert_test_suite_setup RSPEC_SETUP, :path => "spec/spec_helper.rb"
  create_file destination_root("spec/spec.rake"), RSPEC_RAKE
end

def generate_controller_test(name)
  rspec_contents = RSPEC_CONTROLLER_TEST.gsub(/!NAME!/, name.to_s.underscore.camelize)
  controller_spec_path = File.join('spec',options[:app],'controllers',"#{name.to_s.underscore}_controller_spec.rb")
  create_file destination_root(controller_spec_path), rspec_contents, :skip => true
end

def generate_model_test(name)
  rspec_contents = RSPEC_MODEL_TEST.gsub(/!NAME!/, name.to_s.underscore.camelize).gsub(/!DNAME!/, name.to_s.underscore)
  model_spec_path = File.join('spec',options[:app],'models',"#{name.to_s.underscore}_spec.rb")
  create_file destination_root(model_spec_path), rspec_contents, :skip => true
end
