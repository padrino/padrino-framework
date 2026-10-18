require_relative 'helper'

describe 'PluginGenerator' do
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{SecureRandom.hex}"
    `mkdir -p #{@apptmp}`
  end

  def teardown
    `rm -rf #{@apptmp}`
  end

  describe 'the plugin generator' do
    it 'should respect --root option' do
      path = File.expand_path('fixtures/plugin_template.rb', __dir__)
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      out, _err = capture_io { generate(:plugin, path, "--root=#{@apptmp}/sample_project") }
      refute_match(/You are not at the root/, out)
    end

    it 'should add gems in a group the Gemfile has no section for' do
      plugin = "#{@apptmp}/group_plugin.rb"
      File.write(plugin, "require_dependencies 'foo_dev', group: :development\nrequire_dependencies 'foo_test', group: :test\n")
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:plugin, plugin, "--root=#{@apptmp}/sample_project") }
      assert_match_in_file(/# Component requirements\ngem 'foo_dev', group: 'development'\n/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/# Test requirements\ngem 'foo_test', group: 'test'\n/, "#{@apptmp}/sample_project/Gemfile")
    end

    it 'should write an Array group and give each gem the version' do
      plugin = "#{@apptmp}/options_plugin.rb"
      File.write(plugin, "require_dependencies 'foo_both', group: [:development, :test]\nrequire_dependencies 'foo_a', 'foo_b', version: '>= 2'\n")
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:plugin, plugin, "--root=#{@apptmp}/sample_project") }
      assert_match_in_file(/^gem 'foo_both', group: \[:development, :test\]$/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/^gem 'foo_a', '>= 2'$/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/^gem 'foo_b', '>= 2'$/, "#{@apptmp}/sample_project/Gemfile")
    end

    it 'should fail outside app root' do
      path = File.expand_path('fixtures/plugin_template.rb', __dir__)
      out, = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:plugin, path, "--root=#{@apptmp}") }.status }
      assert_match(/not at the root/, out)
    end

    it 'should fail if the project template cannot be loaded' do
      path = "#{@apptmp}/missing_template.rb"
      out, = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:project, 'sample_project', "--template=#{path}", "--root=#{@apptmp}") }.status }
      assert_match(/The template at #{path} could not be loaded/, out)
    end
  end

  describe 'the plugin destroy option' do
    it 'should remove the plugin instance' do
      path = File.expand_path('fixtures/plugin_template.rb', __dir__)
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:plugin, path, "--root=#{@apptmp}/sample_project") }
      capture_io { generate(:plugin, path, "--root=#{@apptmp}/sample_project", '-d') }
      assert_no_file_exists("#{@apptmp}/sample_project/lib/hoptoad_initializer.rb")
      assert_no_match_in_file(/enable :raise_errors/, "#{@apptmp}/sample_project/app/app.rb")
      assert_no_match_in_file(/rack_hoptoad/, "#{@apptmp}/sample_project/Gemfile")
    end
  end

  describe 'the project generator with template' do
    it 'should invoke Padrino.bin_gen' do
      expects_generated_project name: 'sample_project', test: :shoulda, orm: :activerecord, dev: true, template: 'mongochist', root: @apptmp
      expects_generated :model, "post title:string body:text -r=#{@apptmp}/sample_project"
      expects_generated :controller, "posts get:index get:new post:new -r=#{@apptmp}/sample_project"
      expects_generated :migration, "AddEmailToUser email:string -r=#{@apptmp}/sample_project"
      expects_generated :fake, "foo bar -r=#{@apptmp}/sample_project"
      expects_generated :plugin, "carrierwave -r=#{@apptmp}/sample_project"
      File.stubs(:exist?).returns(true)
      expects_dependencies 'nokogiri'
      expects_initializer :test, '# Example', root: "#{@apptmp}/sample_project"
      expects_generated :app, "testapp -r=#{@apptmp}/sample_project"
      expects_generated :controller, "users get:index -r=#{@apptmp}/sample_project --app=testapp"
      example_template_path = File.join(__dir__, 'fixtures', 'example_template.rb')
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", "-p=#{example_template_path}", '> /dev/null') }
      File.unstub(:exist?)
    end

    it 'should run generators named with a Symbol' do
      template_path = "#{@apptmp}/symbol_template.rb"
      File.write(template_path, "project orm: :sequel\ngenerate :model, 'post title:string'\n")
      out, = capture_subprocess_io { generate(:project, 'sample_project', "--root=#{@apptmp}", "-p=#{template_path}") }
      refute_match(/could not be loaded/, out)
      assert_match_in_file(/class Post < Sequel::Model/, "#{@apptmp}/sample_project/models/post.rb")
    end

    it 'should pass --dev on to the project a template generates' do
      template_path = "#{@apptmp}/dev_template.rb"
      File.write(template_path, "project orm: :none\n")
      capture_subprocess_io { generate(:project, 'sample_project', "--root=#{@apptmp}", "-p=#{template_path}", '--dev') }
      assert_match_in_file(%r{gem 'padrino-' \+ g, path: '#{Regexp.escape(Padrino::Generators::DEV_PATH)}/padrino-' \+ g}, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/^# gem 'padrino', '#{Regexp.escape(Padrino.version)}'/, "#{@apptmp}/sample_project/Gemfile")
    end

    it 'should keep the dev setting a template gives its project' do
      template_path = "#{@apptmp}/no_dev_template.rb"
      File.write(template_path, "project orm: :none, dev: false\n")
      capture_subprocess_io { generate(:project, 'sample_project', "--root=#{@apptmp}", "-p=#{template_path}", '--dev') }
      assert_match_in_file(/^gem 'padrino', '#{Regexp.escape(Padrino.version)}'/, "#{@apptmp}/sample_project/Gemfile")
    end

    it 'should let a template check whether app succeeded' do
      template_path = "#{@apptmp}/app_result_template.rb"
      File.write(template_path, "project orm: :none\nputs(app(:blog) ? 'FIRST OK' : 'FIRST FAILED')\nputs(app(:blog) ? 'AGAIN OK' : 'AGAIN FAILED')\n")
      out, = capture_subprocess_io { generate(:project, 'sample_project', "--root=#{@apptmp}", "-p=#{template_path}") }
      assert_match(/^FIRST OK$/, out)
      assert_match(/^AGAIN FAILED$/, out)
    end

    it 'should generate a sub app named with a Symbol' do
      template_path = "#{@apptmp}/app_template.rb"
      File.write(template_path, "project orm: :none\napp :blog\n")
      out, = capture_subprocess_io { generate(:project, 'sample_project', "--root=#{@apptmp}", "-p=#{template_path}") }
      refute_match(/could not be loaded/, out)
      assert_match_in_file(/class Blog < Padrino::Application/, "#{@apptmp}/sample_project/blog/app.rb")
    end
  end

  describe 'with resolving urls' do
    it 'should resolve generic url properly' do
      template_file = 'http://www.example.com/test.rb'
      stub_request :get, template_file
      project_gen = Padrino::Generators::Project.new(['sample_project'], ["-p=#{template_file}", "-r=#{@apptmp}"], {})
      project_gen.expects(:apply).with(template_file).returns(true).once
      capture_io { project_gen.invoke_all }
    end

    def expect_template_applied(template_file, resolved_path)
      project_gen = Padrino::Generators::Project.new(['sample_project'], ["-p=#{template_file}", "-r=#{@apptmp}"], {})
      project_gen.expects(:apply).with(resolved_path).returns(true).once
      capture_io { project_gen.invoke_all }
    end

    def stub_gist_page_without_user
      # GitHub redirects a gist page without the user to the user's page. Its raw button doesn't match
      # the old scraping regex.
      stub_request(:get, 'https://gist.github.com/357045')
        .to_return(status: 302, headers: { 'Location' => 'https://gist.github.com/achiurizo/357045' })
      stub_request(:get, 'https://gist.github.com/achiurizo/357045')
        .to_return(body: '<a href="/achiurizo/357045/raw/8f73/blog_template.rb" class="Button">Raw</a>')
    end

    it 'should resolve a gist page url without the user to the raw file on the user\'s path' do
      stub_gist_page_without_user
      expect_template_applied('https://gist.github.com/357045', 'https://gist.github.com/achiurizo/357045/raw')
    end

    it 'should fall back to the gist page url when the user lookup fails' do
      stub_request(:get, 'https://gist.github.com/357045').to_return(status: 404)
      expect_template_applied('https://gist.github.com/357045', 'https://gist.github.com/357045/raw')
    end

    it 'should not take a /raw in the query of a gist page url for a raw url' do
      expect_template_applied('https://gist.github.com/achiurizo/357045?x=/raw', 'https://gist.github.com/achiurizo/357045/raw')
    end

    it 'should resolve a gist page url that names the user' do
      expect_template_applied('https://gist.github.com/achiurizo/357045/', 'https://gist.github.com/achiurizo/357045/raw')
    end

    it 'should drop the fragment and query of a gist page url' do
      expect_template_applied('https://gist.github.com/achiurizo/357045?a=1#file-blog_template-rb', 'https://gist.github.com/achiurizo/357045/raw')
    end

    it 'should apply a raw gist url without a file name as given' do
      expect_template_applied('https://gist.github.com/achiurizo/357045/raw', 'https://gist.github.com/achiurizo/357045/raw')
    end

    it 'should apply a raw gist file url as given' do
      template_file = 'https://gist.githubusercontent.com/achiurizo/357045/raw/8f73/blog_template.rb'
      expect_template_applied(template_file, template_file)
    end

    it 'should apply any https url ending in .rb as remote' do
      expect_template_applied('https://example.com/templates/blog_template.rb', 'https://example.com/templates/blog_template.rb')
    end

    it 'should resolve a local file whose path mentions gist' do
      expect_template_applied('templates/gist_template.rb', File.expand_path('templates/gist_template.rb'))
    end

    it 'should run a gist template through the redirect to its raw host' do
      stub_request(:get, 'https://gist.github.com/achiurizo/357045/raw')
        .to_return(status: 301, headers: { 'Location' => 'https://gist.githubusercontent.com/achiurizo/357045/raw' })
      stub_request(:get, 'https://gist.githubusercontent.com/achiurizo/357045/raw')
        .to_return(body: "create_file 'from_gist.txt', 'hello'\n")
      out, = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-p=https://gist.github.com/achiurizo/357045') }
      refute_match(/could not be loaded/, out)
      assert_match_in_file(/hello/, "#{@apptmp}/sample_project/from_gist.txt")
    end

    it 'should resolve official template' do
      template_file = 'sampleblog'
      resolved_path = 'https://raw.githubusercontent.com/padrino/padrino-recipes/master/templates/sampleblog_template.rb'
      stub_request(:get, resolved_path).to_return(body: template_file)
      project_gen = Padrino::Generators::Project.new(['sample_project'], ["-p=#{template_file}", "-r=#{@apptmp}"], {})
      project_gen.expects(:apply).with(resolved_path).returns(true).once
      capture_io { project_gen.invoke_all }
    end

    it 'should resolve local file' do
      template_file = 'path/to/local/file.rb'
      project_gen = Padrino::Generators::Project.new(['sample_project'], ["-p=#{template_file}", "-r=#{@apptmp}"], {})
      project_gen.expects(:apply).with(File.expand_path(template_file)).returns(true).once
      capture_io { project_gen.invoke_all }
    end

    it 'should resolve official plugin' do
      template_file = 'hoptoad'
      resolved_path = 'https://raw.githubusercontent.com/padrino/padrino-recipes/master/plugins/hoptoad_plugin.rb'
      stub_request(:get, resolved_path).to_return(body: template_file)
      plugin_gen = Padrino::Generators::Plugin.new([template_file], ["-r=#{@apptmp}/sample_project"], {})
      plugin_gen.expects(:in_app_root?).returns(true).once
      plugin_gen.expects(:apply).with(resolved_path).returns(true).once
      capture_io { plugin_gen.invoke_all }
    end

    it 'should resolve a gist page url given to the plugin generator' do
      plugin_gen = Padrino::Generators::Plugin.new(['https://gist.github.com/357045'], ["-r=#{@apptmp}/sample_project"], {})
      plugin_gen.expects(:in_app_root?).returns(true).once
      stub_gist_page_without_user
      plugin_gen.expects(:apply).with('https://gist.github.com/achiurizo/357045/raw').returns(true).once
      capture_io { plugin_gen.invoke_all }
    end

    it 'should print a warning if template cannot be found' do
      template_file = 'hwat'
      resolved_path = 'https://raw.githubusercontent.com/padrino/padrino-recipes/master/plugins/hwat_plugin.rb'
      stub_request(:get, resolved_path).to_return(status: 404)
      plugin_gen = Padrino::Generators::Plugin.new([template_file], ["-r=#{@apptmp}/sample_project"], {})
      plugin_gen.expects(:in_app_root?).returns(true).once
      # Use regex to ignore trailing whitespace in message
      plugin_gen.expects(:say).with { |message, color| (message =~ /The template at #{resolved_path} could not be loaded:.*404.*/) && (color == :red) }.returns(true).once
      capture_io { assert_equal 1, assert_raises(SystemExit) { plugin_gen.invoke_all }.status }
    end
  end

  describe 'with list option' do
    it 'should return a list of available plugins with no parameter' do
      plugin_gen = Padrino::Generators::Plugin.new([], [], {})
      plugin_gen.expects(:list_plugins).returns(true).once
      capture_io { plugin_gen.invoke_all }
    end

    it 'should list the plugins named on the recipes page with the default certificate checks' do
      page = '<a href="/padrino/padrino-recipes/blob/master/plugins/omniauth_plugin.rb">' \
             '<a href="/padrino/padrino-recipes/blob/master/plugins/will_paginate_plugin.rb">'
      WebMock::API.stub_request(:get, Padrino::Generators::Plugin::PLUGIN_URL).to_return(body: page)
      Net::HTTP.any_instance.expects(:verify_mode=).never
      out, = capture_io { Padrino::Generators::Plugin.new([], ['-l'], {}).invoke_all }
      assert_match(/- omniauth$/, out)
      assert_match(/- will_paginate$/, out)
    end

    it 'should return a list of available plugins with list option' do
      plugin_gen = Padrino::Generators::Plugin.new(['some_plugin'], ['-l', "-r=#{@apptmp}/sample_project"], {})
      plugin_gen.expects(:list_plugins).returns(true).once
      capture_io { plugin_gen.invoke_all }
    end
  end

  describe 'with git commands' do
    it 'should generate a repository correctly' do
      skip 'Change stubs here'
      expects_generated_project test: :rspec, orm: :activerecord, name: 'sample_git', root: @apptmp.to_s
      expects_git :init, root: "#{@apptmp}/sample_git"
      expects_git :add, arguments: '.', root: "#{@apptmp}/sample_git"
      expects_git :commit, arguments: 'hello', root: "#{@apptmp}/sample_git"
      git_template_path = File.join(__dir__, 'fixtures', 'git_template.rb')
      capture_io { generate(:project, 'sample_git', "-p=#{git_template_path}", "-r=#{@apptmp}", '2>&1 /dev/null') }
    end
  end

  describe 'with rake invocations' do
    it 'should Run rake task and list tasks' do
      expects_generated_project test: :shoulda, orm: :activerecord, name: 'sample_rake', root: @apptmp.to_s
      expects_rake 'custom', root: "#{@apptmp}/sample_rake"
      rake_template_path = File.join(__dir__, 'fixtures', 'rake_template.rb')
      capture_io { generate(:project, 'sample_rake', "-p=#{rake_template_path}", "-r=#{@apptmp}", '> /dev/null') }
    end
  end

  describe 'with the environment of the steps' do
    def run_steps_under_caller_bundle(project)
      saved = ENV.to_h
      # ENV when Bundler loaded, and what the caller's `bundle exec` exported to its children
      # (PADRINO_LOG_LEVEL was set before Bundler loaded and cleared since; a template set MY_TEMPLATE_VAR)
      Bundler.stubs(:original_env).returns('PATH' => ENV['PATH'], 'RUBYOPT' => '-W0', 'RUBYLIB' => '/user/lib', 'PADRINO_LOG_LEVEL' => 'test')
      ENV.delete('PADRINO_LOG_LEVEL')
      ENV.update('BUNDLE_GEMFILE' => '/caller/Gemfile', 'BUNDLE_LOCKFILE' => '/caller/Gemfile.lock', 'RUBYOPT' => '-rbundler/setup -W0',
                 'BUNDLER_SETUP' => '/caller/bundler/setup', 'BUNDLER_ORIG_PATH' => ENV['PATH'], 'MY_TEMPLATE_VAR' => 'x',
                 'PATH' => "/caller/vendor/bundle/bin:#{ENV['PATH']}", 'GEM_HOME' => '/caller/vendor/bundle/ruby', 'GEM_PATH' => '',
                 'RUBYLIB' => '/caller/bundler/lib:/user/lib')
      seen = {}
      keys = %w[PATH RUBYOPT BUNDLE_GEMFILE BUNDLE_LOCKFILE BUNDLER_SETUP BUNDLER_ORIG_PATH MY_TEMPLATE_VAR PADRINO_LOG_LEVEL
                GEM_HOME GEM_PATH RUBYLIB]
      record = ->(step) { seen[step] = ENV.to_h.slice(*keys) }
      Padrino.stubs(:bin).with { |*args| record.call(args.first) }.returns(true)
      Padrino.stubs(:bin_gen).with { |*args| record.call(args.first.to_s) }.returns(true)
      path = "#{@apptmp}/steps_plugin.rb"
      File.write(path, "rake 'custom'\ngenerate :model, 'post'\napp :blog\n")
      capture_io { generate(:plugin, path, "--root=#{project}") }
      assert_equal '/caller/Gemfile', ENV['BUNDLE_GEMFILE']
      assert_equal '-rbundler/setup -W0', ENV['RUBYOPT']
      seen
    ensure
      ENV.replace(saved)
    end

    it "should run rake, generate and app under a bundled project's own bundle" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      project = "#{@apptmp}/sample_project"
      File.write("#{project}/Gemfile.lock", '')
      seen = run_steps_under_caller_bundle(project)
      expected = { 'PATH' => ENV['PATH'], 'RUBYOPT' => '-rbundler/setup -W0', 'BUNDLE_GEMFILE' => "#{project}/Gemfile",
                   'BUNDLE_LOCKFILE' => "#{project}/Gemfile.lock", 'MY_TEMPLATE_VAR' => 'x', 'RUBYLIB' => '/user/lib' }
      assert_equal({ 'rake' => expected, 'model' => expected, 'app' => expected }, seen)
    end

    it "should run rake, generate and app under the caller's bundle until the project is bundled" do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      seen = run_steps_under_caller_bundle("#{@apptmp}/sample_project")
      expected = { 'PATH' => "/caller/vendor/bundle/bin:#{ENV['PATH']}", 'RUBYOPT' => '-rbundler/setup -W0',
                   'BUNDLE_GEMFILE' => '/caller/Gemfile', 'BUNDLE_LOCKFILE' => '/caller/Gemfile.lock',
                   'BUNDLER_SETUP' => '/caller/bundler/setup', 'BUNDLER_ORIG_PATH' => ENV['PATH'], 'MY_TEMPLATE_VAR' => 'x',
                   'GEM_HOME' => '/caller/vendor/bundle/ruby', 'GEM_PATH' => '', 'RUBYLIB' => '/caller/bundler/lib:/user/lib' }
      assert_equal({ 'rake' => expected, 'model' => expected, 'app' => expected }, seen)
    end
  end

  describe 'with admin commands' do
    it 'should generate correctly an admin' do
      expects_generated_project test: :shoulda, orm: :activerecord, name: 'sample_admin', root: @apptmp.to_s
      expects_generated :model, "post title:string body:text -r=#{@apptmp}/sample_admin"
      expects_rake 'ar:create', root: "#{@apptmp}/sample_admin"
      expects_generated :admin, "-r=#{@apptmp}/sample_admin"
      expects_rake 'ar:migrate', root: "#{@apptmp}/sample_admin"
      expects_generated :admin_page, "post -r=#{@apptmp}/sample_admin"
      admin_template_path = File.join(__dir__, 'fixtures', 'admin_template.rb')
      capture_io { generate(:project, 'sample_admin', "-p=#{admin_template_path}", "-r=#{@apptmp}", '> /dev/null') }
    end
  end
end
