require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestPluginGenerator < Test::Unit::TestCase
  def setup
    %w(sample_project sample_git sample_rake sample_admin).each { |proj| system("rm -rf /tmp/#{proj}") }
  end

  context "the plugin destroy option" do
    should "remove the plugin instance" do
      path = File.expand_path('../fixtures/plugin_template.rb', __FILE__)
      silence_logger { generate(:project, 'sample_project', '--root=/tmp') }
      silence_logger { generate(:plugin, path, '--root=/tmp/sample_project') }
      silence_logger { generate(:plugin, path, '--root=/tmp/sample_project', '-d') }
      assert_no_file_exists('/tmp/sample_project/lib/hoptoad_init.rb')
      assert_no_match_in_file(/enable \:raise_errors/,'/tmp/sample_project/app/app.rb')
      assert_no_match_in_file(/rack\_hoptoad/, '/tmp/sample_project/Gemfile')
    end
    
  end

  context 'the project generator with template' do
    setup do
      example_template_path = File.join(File.dirname(__FILE__), 'fixtures', 'example_template.rb')
      silence_logger { generate(:project, 'sample_project', "-p=#{example_template_path}", '-r=/tmp', '> /dev/null') }
    end

    before_should "invoke Padrino.bin_gen" do
      expects_generated_project :test => :shoulda, :orm => :activerecord, :dev => true
      expects_generated :model, "post title:string body:text -r=/tmp/sample_project"
      expects_generated :controller, "posts get:index get:new post:new -r=/tmp/sample_project"
      expects_generated :migration, "AddEmailToUser email:string -r=/tmp/sample_project"
      expects_generated :fake, "foo bar -r=/tmp/sample_project"
      expects_dependencies 'nokogiri'
      expects_initializer :test, "# Example"
      expects_generated :app, "testapp -r=/tmp/sample_project"
      expects_generated :controller, "users get:index -r=/tmp/sample_project --app=testapp"
    end


  end

  context "with resolving urls" do
    setup do
      @project_class = Padrino::Generators::Project.dup
    end

    should "resolve generic url properly" do
      template_file = 'http://www.example.com/test.rb'
      project_gen = @project_class.new(['sample_project'], ["-p=#{template_file}", '-r=/tmp'], {})
      project_gen.expects(:apply).with(template_file).returns(true).once
      silence_logger { project_gen.invoke }
    end

    should "resolve gist url properly" do
      FakeWeb.register_uri(:get, "http://gist.github.com/357045", :body => '<a href="/raw/357045/4356/blog_template.rb">raw</a>')
      template_file = 'http://gist.github.com/357045'
      resolved_path = 'http://gist.github.com/raw/357045/4356/blog_template.rb'
      project_gen = @project_class.new(['sample_project'], ["-p=#{template_file}", '-r=/tmp'], {})
      project_gen.expects(:apply).with(resolved_path).returns(true).once
      silence_logger { project_gen.invoke }
    end

    should "resolve official template" do
      template_file = 'sampleblog'
      resolved_path = "http://github.com/padrino/padrino-recipes/raw/master/templates/sampleblog_template.rb"
      project_gen = @project_class.new(['sample_project'], ["-p=#{template_file}", '-r=/tmp'], {})
      project_gen.expects(:apply).with(resolved_path).returns(true).once
      silence_logger { project_gen.invoke }
    end

    should "resolve local file" do
      template_file = 'path/to/local/file.rb'
      project_gen = @project_class.new(['sample_project'], ["-p=#{template_file}", '-r=/tmp'], {})
      project_gen.expects(:apply).with(File.expand_path(template_file)).returns(true).once
      silence_logger { project_gen.invoke }
    end

    should "resolve official plugin" do
      template_file = 'hoptoad'
      resolved_path = "http://github.com/padrino/padrino-recipes/raw/master/plugins/hoptoad_plugin.rb"
      plugin_gen = Padrino::Generators::Plugin.dup
      plugin_gen.any_instance.expects(:apply).with(nil)
      plugin_gen.any_instance.expects(:apply).with(resolved_path).returns(true).once
      silence_logger { plugin_gen.start([ template_file, '-r=/tmp']) }
    end
  end

  context "with git commands" do
    setup do
      git_template_path = File.join(File.dirname(__FILE__), 'fixtures', 'git_template.rb')
      silence_logger { generate(:project, 'sample_git', "-p=#{git_template_path}", '-r=/tmp', '> /dev/null') }
    end

    before_should "generate a repository correctly" do
      expects_generated_project :test => :rspec, :orm => :activerecord, :name => 'sample_git'
      expects_git :init, :root => '/tmp/sample_git'
      expects_git :add, :arguments => '.', :root => '/tmp/sample_git'
      expects_git :commit, :arguments => 'hello', :root => '/tmp/sample_git'
    end
  end

  context "with rake invocations" do
    setup do
      rake_template_path = File.join(File.dirname(__FILE__), 'fixtures', 'rake_template.rb')
      silence_logger { generate(:project, 'sample_rake', "-p=#{rake_template_path}", '-r=/tmp', '> /dev/null') }
    end

    before_should "Run rake task and list tasks" do
      expects_generated_project :test => :shoulda, :orm => :activerecord, :name => 'sample_rake'
      expects_rake "custom", :root => '/tmp/sample_rake'
    end
  end

  context "with admin commands" do
    setup do
      admin_template_path = File.join(File.dirname(__FILE__), 'fixtures', 'admin_template.rb')
      silence_logger { generate(:project, 'sample_admin', "-p=#{admin_template_path}", '-r=/tmp', '> /dev/null') }
    end

    before_should "generate correctly an admin" do
      expects_generated_project :test => :shoulda, :orm => :activerecord, :name => 'sample_admin'
      expects_generated :model, "post title:string body:text -r=/tmp/sample_admin"
      expects_rake "ar:create", :root => '/tmp/sample_admin'
      expects_generated :admin, "-r=/tmp/sample_admin"
      expects_rake "ar:migrate", :root => '/tmp/sample_admin'
      expects_generated :admin_page, "post -r=/tmp/sample_admin"
    end
  end
end
