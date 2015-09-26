require 'minitest/autorun'
require 'minitest/pride'
require 'mocha/setup'
require 'rack/test'
require 'webrat'
require 'fakeweb'
require 'thor/group'
require 'padrino-gen'
require 'padrino-core'
require 'padrino-mailer'
require 'padrino-helpers'

require 'ext/minitest-spec'

Padrino::Generators.load_components!

class MiniTest::Spec
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

  # generate_with_parts(:app, "demo", "--root=/tmp/sample_project", :apps => "subapp")
  # This method is intended to reproduce the real environment.
  def generate_with_parts(name, *params)
    features, constants = [$", Object.constants].map{|x| Marshal.load(Marshal.dump(x)) }

    if root = params.find{|x| x.index(/\-r=|\-\-root=/) }
      root = root.split(/=/)[1]
      options, model_path = {}, File.expand_path(File.join(root, "/models/**/*.rb"))
      options = params.pop if params.last.is_a?(Hash)
      Dir[model_path].each{|path| require path }
      Array(options[:apps]).each do |app_name|
        path = File.expand_path(File.join(root, "/#{app_name}/app.rb"))
        require path if File.exist?(path)
      end if options[:apps]
    end
    "Padrino::Generators::#{name.to_s.camelize}".constantize.start(params)
    ($" - features).each{|x| $".delete(x) }
    (Object.constants - constants).each{|constant| Object.instance_eval{ remove_const(constant) }}
  end

  # expects_generated :model, "post title:string body:text"
  def expects_generated(generator, params="")
    Padrino.expects(:bin_gen).with(generator, *params.split(' ')).returns(true)
  end

  # expects_generated_project :test => :shoulda, :orm => :activerecord, :dev => true
  def expects_generated_project(options={})
    project_root = options[:root]
    project_name = options[:name]
    settings = options.slice!(:name, :root)
    components = settings.sort_by { |k, v| k.to_s }.map { |component, value| "--#{component}=#{value}" }
    params = [project_name, *components].push("-r=#{project_root}")
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
    #options.reverse_merge!(:root => "/tmp/sample_project")
    path = File.join(options[:root],'lib',"#{name}_initializer.rb")
    instance = mock
    instance.expects(:invoke!).at_least_once
    include_text = "    register #{name.to_s.camelize}Initializer\n"
    Thor::Actions::InjectIntoFile.expects(:new).with(anything,anything, include_text, anything).returns(instance)
    Thor::Actions::CreateFile.expects(:new).with(anything, path, kind_of(Proc), anything).returns(instance)
  end

  # expects_rake "custom"
  def expects_rake(command,options={})
    #options.reverse_merge!(:root => '/tmp')
    Padrino.expects(:bin).with("rake", command, "-c=#{options[:root]}").returns(true)
  end
end

module Webrat
  module Logging
    def logger # # @private
      @logger = nil
    end
  end
end
