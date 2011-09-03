require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "PluginGenerator" do
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{UUID.new.generate}"
    `mkdir -p #{@apptmp}`
  end

  def teardown
    `rm -rf #{@apptmp}`
  end

  context "the plugin destroy option" do
    should "remove the plugin instance" do
      path = File.expand_path('../fixtures/plugin_template.rb', __FILE__)
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:plugin, path, "--root=#{@apptmp}/sample_project") }
      capture_io { generate(:plugin, path, "--root=#{@apptmp}/sample_project", '-d') }
      assert_no_file_exists("#{@apptmp}/sample_project/lib/hoptoad_init.rb")
      assert_no_match_in_file(/enable \:raise_errors/,"#{@apptmp}/sample_project/app/app.rb")
      assert_no_match_in_file(/rack\_hoptoad/, "#{@apptmp}/sample_project/Gemfile")
    end
  end

  context 'the project generator with template' do
    should "invoke Padrino.bin_gen" do
      expects_generated_project :name => 'sample_project', :test => :shoulda, :orm => :activerecord, :dev => true, :template => 'mongochist', :root => @apptmp
      expects_generated :model, "post title:string body:text -r=#{@apptmp}/sample_project"
      expects_generated :controller, "posts get:index get:new post:new -r=#{@apptmp}/sample_project"
      expects_generated :migration, "AddEmailToUser email:string -r=#{@apptmp}/sample_project"
      expects_generated :fake, "foo bar -r=#{@apptmp}/sample_project"
      expects_generated :plugin, "carrierwave -r=#{@apptmp}/sample_project"
      expects_dependencies 'nokogiri'
      expects_initializer :test, "# Example", :root => "#{@apptmp}/sample_project"
      expects_generated :app, "testapp -r=#{@apptmp}/sample_project"
      expects_generated :controller, "users get:index -r=#{@apptmp}/sample_project --app=testapp"
      example_template_path = File.join(File.dirname(__FILE__), 'fixtures', 'example_template.rb')
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", "-p=#{example_template_path}", '> /dev/null') }
    end
  end

  context "with resolving urls" do

    should "resolve generic url properly" do
      template_file = 'http://www.example.com/test.rb'
      project_gen = Padrino::Generators::Project.new(['sample_project'], ["-p=#{template_file}", "-r=#{@apptmp}"], {})
      project_gen.expects(:apply).with(template_file).returns(true).once
      capture_io { project_gen.invoke_all }
    end

    should "resolve gist url properly" do
      FakeWeb.register_uri(:get, "https://gist.github.com/357045", :body => '<a href="/raw/357045/4356/blog_template.rb">raw</a>')
      template_file = 'https://gist.github.com/357045'
      resolved_path = 'https://gist.github.com/raw/357045/4356/blog_template.rb'
      project_gen = Padrino::Generators::Project.new(['sample_project'], ["-p=#{template_file}", "-r=#{@apptmp}"], {})
      project_gen.expects(:apply).with(resolved_path).returns(true).once
      capture_io { project_gen.invoke_all }
    end

    should "resolve official template" do
      template_file = 'sampleblog'
      resolved_path = "https://github.com/padrino/padrino-recipes/raw/master/templates/sampleblog_template.rb"
      project_gen = Padrino::Generators::Project.new(['sample_project'], ["-p=#{template_file}", "-r=#{@apptmp}"], {})
      project_gen.expects(:apply).with(resolved_path).returns(true).once
      capture_io { project_gen.invoke_all }
    end

    should "resolve local file" do
      template_file = 'path/to/local/file.rb'
      project_gen = Padrino::Generators::Project.new(['sample_project'], ["-p=#{template_file}", "-r=#{@apptmp}"], {})
      project_gen.expects(:apply).with(File.expand_path(template_file)).returns(true).once
      capture_io { project_gen.invoke_all }
    end

    should "resolve official plugin" do
      template_file = 'hoptoad'
      resolved_path = "https://github.com/padrino/padrino-recipes/raw/master/plugins/hoptoad_plugin.rb"
      plugin_gen = Padrino::Generators::Plugin.new([ template_file], ["-r=#{@apptmp}/sample_project"],{})
      plugin_gen.expects(:in_app_root?).returns(true).once
      plugin_gen.expects(:apply).with(resolved_path).returns(true).once
      capture_io { plugin_gen.invoke_all }
    end
  end

  context "with git commands" do
    should "generate a repository correctly" do
      expects_generated_project :test => :rspec, :orm => :activerecord, :name => 'sample_git', :root => "#{@apptmp}"
      expects_git :init, :root => "#{@apptmp}/sample_git"
      expects_git :add, :arguments => '.', :root => "#{@apptmp}/sample_git"
      expects_git :commit, :arguments => 'hello', :root => "#{@apptmp}/sample_git"
      git_template_path = File.join(File.dirname(__FILE__), 'fixtures', 'git_template.rb')
      capture_io { generate(:project, 'sample_git', "-p=#{git_template_path}", "-r=#{@apptmp}", '> /dev/null') }
    end
  end

  context "with rake invocations" do
    should "Run rake task and list tasks" do
      expects_generated_project :test => :shoulda, :orm => :activerecord, :name => 'sample_rake', :root => "#{@apptmp}"
      expects_rake "custom", :root => "#{@apptmp}/sample_rake"
      rake_template_path = File.join(File.dirname(__FILE__), 'fixtures', 'rake_template.rb')
      capture_io { generate(:project, 'sample_rake', "-p=#{rake_template_path}", "-r=#{@apptmp}", '> /dev/null') }
    end
  end

  context "with admin commands" do
    should "generate correctly an admin" do
      expects_generated_project :test => :shoulda, :orm => :activerecord, :name => 'sample_admin', :root => "#{@apptmp}"
      expects_generated :model, "post title:string body:text -r=#{@apptmp}/sample_admin"
      expects_rake "ar:create", :root => "#{@apptmp}/sample_admin"
      expects_generated :admin, "-r=#{@apptmp}/sample_admin"
      expects_rake "ar:migrate", :root => "#{@apptmp}/sample_admin"
      expects_generated :admin_page, "post -r=#{@apptmp}/sample_admin"
      admin_template_path = File.join(File.dirname(__FILE__), 'fixtures', 'admin_template.rb')
      capture_io { generate(:project, 'sample_admin', "-p=#{admin_template_path}", "-r=#{@apptmp}", '> /dev/null') }
    end
  end
end
