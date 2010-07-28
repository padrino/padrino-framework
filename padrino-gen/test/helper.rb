require File.expand_path('../../../load_paths', __FILE__)
require 'test/unit'
require 'rack/test'
require 'rack'
require 'shoulda'
require 'mocha'
require 'webrat'
require 'git'
require 'thor/group'
require 'fakeweb'
require 'padrino-gen'
require 'padrino-core/support_lite' unless defined?(SupportLite)

Padrino::Generators.load_components!

class Test::Unit::TestCase
  include Rack::Test::Methods
  include Webrat::Methods
  include Webrat::Matchers

  Webrat.configure do |config|
    config.mode = :rack
  end

  def stop_time_for_test
    time = Time.now
    Time.stubs(:now).returns(time)
    return time
  end

  # generate(:controller, 'DemoItems', '-r=/tmp/sample_project')
  def generate(name, *params)
    "Padrino::Generators::#{name.to_s.camelize}".constantize.start(params)
  end

  # assert_has_tag(:h1, :content => "yellow") { "<h1>yellow</h1>" }
  # In this case, block is the html to evaluate
  def assert_has_tag(name, attributes = {}, &block)
    html = block && block.call
    matcher = HaveSelector.new(name, attributes)
    raise "Please specify a block!" if html.blank?
    assert matcher.matches?(html), matcher.failure_message
  end

  # assert_has_no_tag, tag(:h1, :content => "yellow") { "<h1>green</h1>" }
  # In this case, block is the html to evaluate
  def assert_has_no_tag(name, attributes = {}, &block)
    html = block && block.call
    attributes.merge!(:count => 0)
    matcher = HaveSelector.new(name, attributes)
    raise "Please specify a block!" if html.blank?
    assert matcher.matches?(html), matcher.failure_message
  end
  
  # assert_file_exists('/tmp/app')
  def assert_file_exists(file_path)
    assert File.exist?(file_path), "File at path '#{file_path}' does not exist!"
  end
  alias :assert_dir_exists :assert_file_exists

  # assert_no_file_exists('/tmp/app')
  def assert_no_file_exists(file_path)
    assert !File.exist?(file_path), "File should not exist at path '#{file_path}' but was found!"
  end
  alias :assert_no_dir_exists :assert_no_file_exists

  # Asserts that a file matches the pattern
  def assert_match_in_file(pattern, file)
    File.exist?(file) ? assert_match(pattern, File.read(file)) : assert_file_exists(file)
  end

  def assert_no_match_in_file(pattern, file)
    File.exists?(file) ? assert_no_match(pattern, File.read(file)) : assert_file_exists(file)
  end

  # expects_generated :model, "post title:string body:text"
  def expects_generated(generator, params="")
    Padrino.expects(:bin_gen).with(generator,*params.split(' ')).returns(true)
  end

  # expects_created_project :test => :shoulda, :orm => :activerecord, :dev => true
  def expects_generated_project(options={})
    settings = options.slice!(:name, :root)
    options.reverse_merge!(:name => 'sample_project', :root => '/tmp')
    components = settings.ordered_collect { |component,value| "--#{component}=#{value}" }
    params = [options[:name], *components].push("-r=#{options[:root]}")
    Padrino.expects(:bin_gen).with(*params.unshift('project')).returns(true)
  end

  # expects_dependencies 'nokogiri'
  def expects_dependencies(name)
    instance = mock
    instance.expects(:invoke!).once
    include_text = "gem '#{name}'\n"
    Thor::Actions::InjectIntoFile.expects(:new).with(anything,'Gemfile', include_text, anything).returns(instance)
  end

  # expects_initializer :test, "# Example"
  def expects_initializer(name, body,options={})
    options.reverse_merge!(:root => "/tmp/sample_project")
    path = File.join(options[:root],'lib',"#{name}_init.rb")
    instance = mock
    instance.expects(:invoke!).at_least_once
    include_text = "  register #{name.to_s.camelize}Initializer\n"
    Thor::Actions::InjectIntoFile.expects(:new).with(anything,anything, include_text, anything).returns(instance)
    Thor::Actions::CreateFile.expects(:new).with(anything, path, kind_of(Proc), anything).returns(instance)
  end

  def expects
    
  end

  # expects_rake "custom"
  def expects_rake(command,options={})
    options.reverse_merge!(:root => '/tmp')
    Padrino.expects(:bin).with("rake", command, "-c=#{options[:root]}").returns(true)
  end

  # expects_git :commit, "hello world"
  def expects_git(command,options={})
    options.reverse_merge!(:root => '/tmp')
    FileUtils.mkdir_p(options[:root])
      if command.to_s == 'init'
        args = options[:arguments] || options[:root]
        ::Git.expects(:init).with(args).returns(true)
      else
        base = ::Git::Base.new
        # base.expects(command.to_sym).with(options[:arguments]).returns(true)
        ::Git.stubs(:open).with(options[:root]).returns(base)
        ::Git::Base.any_instance.expects(command.to_sym).with(options[:arguments]).returns(true)
      end
  end

end

class Object
  # Silences the output by redirecting to stringIO
  # silence_logger { ...commands... } => "...output..."
  def silence_logger(&block)
    orig_stdout = $stdout
    $stdout = log_buffer = StringIO.new
    block.call
    $stdout = orig_stdout
    log_buffer.rewind && log_buffer.read
  end
end

module Webrat
  module Logging
    def logger # :nodoc:
      @logger = nil
    end
  end
end
