RSPEC_SETUP = (<<-TEST).gsub(/^ {12}/, '') unless defined?(RSPEC_SETUP)
RACK_ENV = 'test' unless defined?(RACK_ENV)
require File.expand_path(File.dirname(__FILE__) + "/../config/boot")
Dir[File.expand_path(File.dirname(__FILE__) + "/../app/helpers/**/*.rb")].each(&method(:require))

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

RSpec.describe "!PATH!" do
  pending "add some examples to \#{__FILE__}" do
    before do
      get "!EXPANDED_PATH!"
    end

    it "returns hello world" do
      expect(last_response.body).to eq "Hello World"
    end
  end
end
TEST

RSPEC_MODEL_TEST = (<<-TEST).gsub(/^ {12}/, '') unless defined?(RSPEC_MODEL_TEST)
require 'spec_helper'

RSpec.describe !NAME! do
  pending "add some examples to (or delete) \#{__FILE__}"
end
TEST

RSPEC_HELPER_TEST = (<<-TEST) unless defined?(RSPEC_HELPER_TEST)
require 'spec_helper'

RSpec.describe "!NAME!" do
  pending "add some examples to (or delete) \#{__FILE__}" do
    let(:helpers){ Class.new }
    before { helpers.extend !NAME! }
    subject { helpers }

    it "should return nil" do
      expect(subject.foo).to be_nil
    end
  end
end
TEST

def setup_test
  require_dependencies 'rack-test', :require => 'rack/test', :group => 'test'
  require_dependencies 'rspec', :group => 'test'
  insert_test_suite_setup RSPEC_SETUP, :path => "spec/spec_helper.rb"
  inject_into_file(destination_root('Rakefile'), "PadrinoTasks.use(:spec)\n", :before => 'PadrinoTasks.init')
end

def generate_controller_test(name, path)
  rspec_contents = RSPEC_CONTROLLER_TEST.gsub(/!PATH!/, path).gsub(/!EXPANDED_PATH!/, path.gsub(/:\w+?_id/, "1"))
  controller_spec_path = File.join('spec',options[:app],'controllers',"#{name.to_s.underscore}_controller_spec.rb")
  create_file destination_root(controller_spec_path), rspec_contents, :skip => true
end

def generate_model_test(name)
  rspec_contents = RSPEC_MODEL_TEST.gsub(/!NAME!/, name.to_s.underscore.camelize).gsub(/!DNAME!/, name.to_s.underscore)
  model_spec_path = File.join('spec',options[:app],'models',"#{name.to_s.underscore}_spec.rb")
  create_file destination_root(model_spec_path), rspec_contents, :skip => true
end

def generate_helper_test(name, project_name, app_name)
  rspec_contents = RSPEC_HELPER_TEST.gsub(/!NAME!/, "#{project_name}::#{app_name}::#{name}")
  helper_spec_path = File.join('spec', options[:app], 'helpers', "#{name.underscore}_spec.rb")
  create_file destination_root(helper_spec_path), rspec_contents, :skip => true
end
