ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/pride'
require 'mocha/setup'
require 'rack/test'
require 'webrat'
require 'padrino-helpers'
require 'active_support/time'
require 'builder'

class MiniTest::Spec
  include Padrino::Helpers::OutputHelpers
  include Padrino::Helpers::TagHelpers
  include Padrino::Helpers::AssetTagHelpers
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

  # assert_has_tag(:h1, :content => "yellow") { "<h1>yellow</h1>" }
  # In this case, block is the html to evaluate
  def assert_has_tag(name, attributes = {})
    html = yield if block_given?
    fail "Please specify a block" if html.blank?
    assert html.html_safe?, 'output in not #html_safe?'
    matcher = HaveSelector.new(name, attributes)
    assert matcher.matches?(html), matcher.failure_message
  end

  # assert_has_no_tag(:h1, :content => "yellow") { "<h1>green</h1>" }
  # In this case, block is the html to evaluate
  def assert_has_no_tag(name, attributes = {}, &block)
    assert_has_tag(name, attributes.merge(:count => 0), &block)
  end

  # Asserts that a file matches the pattern
  def assert_match_in_file(pattern, file)
    assert File.file?(file), "File '#{file}' does not exist"
    assert_match pattern, File.read(file)
  end

  # mock_model("Business", :new_record? => true) => <Business>
  def mock_model(klazz, options={})
    options.reverse_merge!(:class => klazz, :new_record? => false, :id => 20, :errors => {})
    record = stub(options)
    record.stubs(:to_ary => [record])
    record
  end

  def create_template(name, content, options={})
    FileUtils.mkdir_p(File.dirname(__FILE__) + "/views")
    FileUtils.mkdir_p(File.dirname(__FILE__) + "/views/layouts")
    path  = "/views/#{name}"
    path += ".#{options.delete(:locale)}" if options[:locale].present?
    path += ".#{options[:format]}" if options[:format].present?
    path += ".erb" unless options[:format].to_s =~ /erb|slim|haml|rss|atom|builder|liquid/
    path += ".builder" if options[:format].to_s =~ /rss|atom/
    file  = File.dirname(__FILE__) + path
    File.open(file, 'w') { |io| io.write content }
    file
  end
  alias :create_view   :create_template
  alias :create_layout :create_template

  def remove_views
    FileUtils.rm_rf(File.dirname(__FILE__) + "/views")
  end

  def with_template(name, content, options={})
    template = create_template(name, content, options)
    yield
  ensure
    File.unlink(template) rescue nil
    remove_views
  end
  alias :with_view   :with_template
  alias :with_layout :with_template

  def mock_app(base=Padrino::Application, &block)
    @app = Sinatra.new base do
      register Padrino::Helpers
      instance_eval &block
    end
  end

  def app
    Rack::Lint.new(@app)
  end

  # Delegate some methods to the last response
  alias_method :response, :last_response

  [:status, :headers, :body, :content_type, :ok?, :forbidden?].each do |method_name|
    define_method method_name do
      last_response.send(method_name)
    end
  end
end

module Webrat
  module Logging
    def logger # @private
      @logger = nil
    end
  end
end
