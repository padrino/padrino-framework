require 'minitest/autorun'
require 'minitest/pride'
require 'rack/test'
require 'thor/group'
require 'padrino-gen'
require 'padrino-core'
require 'padrino-mailer'
require 'padrino-helpers'

require 'ext/minitest-spec'
require 'mocha/minitest'
require 'webmock/minitest'

Padrino::Generators.load_components!

class Minitest::Spec
  def stop_time_for_test
    time = Time.now
    Time.stubs(:now).returns(time)
    time
  end

  def stub_static_files
    # register fake URL to avoid downloading static files every time tests run
    fake_uri_base = 'https://raw.github.com/padrino/padrino-static/master/'
    %w[
      js/dojo.js
      js/ext.js
      js/jquery.js
      js/lowpro.js
      js/mootools.js
      js/protopak.js
      js/right.js
      ujs/dojo.js
      ujs/ext.js
      ujs/jquery.js
      ujs/mootools.js
      ujs/prototype.js
      ujs/right.js
    ].each do |suffix|
      WebMock::API.stub_request(:get, fake_uri_base + suffix)
    end
  end

  # generate(:controller, 'DemoItems', '-r=/tmp/sample_project')
  def generate(name, *params)
    "Padrino::Generators::#{name.to_s.camelize}".constantize.start(params)
  end

  # generate_with_parts(:app, "demo", "--root=/tmp/sample_project", :apps => "subapp")
  # This method is intended to reproduce the real environment.
  def generate_with_parts(name, *params)
    features, constants = [$LOADED_FEATURES, Object.constants].map {|x| Marshal.load(Marshal.dump(x)) }

    if root = params.find {|x| x.index(/-r=|--root=/) }
      root = root.split(/=/)[1]
      options, model_path = {}, File.expand_path(File.join(root, '/models/**/*.rb'))
      options = params.pop if params.last.is_a?(Hash)
      Dir[model_path].each {|path| require path }
      Array(options[:apps]).each do |app_name|
        path = File.expand_path(File.join(root, "/#{app_name}/app.rb"))
        require path if File.exist?(path)
      end if options[:apps]
    end
    "Padrino::Generators::#{name.to_s.camelize}".constantize.start(params)
    ($LOADED_FEATURES - features).each {|x| $LOADED_FEATURES.delete(x) }
    (Object.constants - constants).each {|constant| Object.instance_eval { remove_const(constant) }}
  end

  # expects_generated :model, "post title:string body:text"
  def expects_generated(generator, params = '')
    Padrino.expects(:bin_gen).with(generator, *params.split(' ')).returns(true)
  end

  # expects_generated_project :test => :shoulda, :orm => :activerecord, :dev => true
  def expects_generated_project(options = {})
    options = options.dup
    project_root = options.delete(:root)
    project_name = options.delete(:name)
    components = options.sort_by { |k, _v| k.to_s }.map { |component, value| "--#{component}=#{value}" }
    params = [project_name, *components].push("-r=#{project_root}")
    Padrino.expects(:bin_gen).with(*params.unshift('project')).returns(true)
  end

  # expects_dependencies 'nokogiri'
  def expects_dependencies(name)
    instance = mock
    instance.expects(:invoke!).once
    include_text = "gem '#{name}'\n"
    Thor::Actions::InjectIntoFile.expects(:new).with(anything, 'Gemfile', include_text, anything).returns(instance)
  end

  # expects_initializer :test, "# Example"
  def expects_initializer(name, body, options = {})
    #options.reverse_merge!(:root => "/tmp/sample_project")
    path = File.join(options[:root], 'config/initializers', "#{name}.rb")
    instance = mock
    instance.expects(:invoke!).at_least_once
    include_text = "    register #{name.to_s.camelize}Initializer\n"
    Thor::Actions::InjectIntoFile.expects(:new).with(anything, anything, include_text, anything).returns(instance)
    Thor::Actions::CreateFile.expects(:new).with(anything, path, kind_of(Proc), anything).returns(instance)
  end

  # expects_rake "custom"
  def expects_rake(command, options = {})
    #options.reverse_merge!(:root => '/tmp')
    Padrino.expects(:bin).with('rake', command, "-c=#{options[:root]}").returns(true)
  end
end
