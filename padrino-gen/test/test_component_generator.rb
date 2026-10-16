require_relative 'helper'
require 'rb-readline'
require 'timeout'

describe 'ComponentGenerator' do
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{SecureRandom.hex}"
    `mkdir -p #{@apptmp}`
    stub_static_files
  end

  def teardown
    `rm -rf #{@apptmp}`
  end

  describe 'the controller generator' do
    it 'should fail outside app root' do
      out, = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:component, 'demo', "-r=#{@apptmp}") }.status }
      assert_match(/not at the root/, out)
    end
  end

  describe 'add components' do
    it 'should properly generate default' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      out, = capture_io { generate(:component, '--orm=activerecord', "-r=#{@apptmp}/sample_project") }
      assert_match(/applying.*?activerecord.*?orm/, out)
      assert_match_in_file(/gem 'activerecord', '>= 3.1', require: 'active_record'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/gem 'sqlite3'/, "#{@apptmp}/sample_project/Gemfile")
      refute_match(/Switch renderer to/, out)
      database_template_path = File.join(__dir__, 'fixtures', 'database_template.rb')
      assert FileUtils.compare_file("#{@apptmp}/sample_project/config/database.rb", database_template_path)
      components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
      assert_equal 'activerecord', components_chosen[:orm]
    end

    it 'should move existing public styles into the tailwind source' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      File.write("#{@apptmp}/sample_project/public/stylesheets/application.css", "body { color: red; }\n")
      capture_io { generate(:component, '--stylesheet=tailwind', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/@import "tailwindcss";\n\nbody \{ color: red; \}/, "#{@apptmp}/sample_project/app/stylesheets/application.css")
      refute File.exist?("#{@apptmp}/sample_project/public/stylesheets/application.css")
    end

    it 'should keep the charset and imports of moved public styles above tailwind' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      File.write("#{@apptmp}/sample_project/public/stylesheets/application.css", "@charset \"UTF-8\";\n/* fonts */\n@import url(https://fonts.example.com/inter.css);\nbody { color: red; }\n")
      capture_io { generate(:component, '--stylesheet=tailwind', "-r=#{@apptmp}/sample_project") }
      expected = "@charset \"UTF-8\";\n/* fonts */\n@import url(https://fonts.example.com/inter.css);\n@import \"tailwindcss\";\n\nbody { color: red; }\n"
      assert_equal expected, File.read("#{@apptmp}/sample_project/app/stylesheets/application.css")
    end

    it 'should keep imports of moved public styles resolving from public/stylesheets' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      css = "@import \"reset.css\";\n@import url('print.css') print;\n@import \"//cdn.example.com/x.css\";\n@import url(/base.css);\n.a { color: red; }\n"
      File.write("#{@apptmp}/sample_project/public/stylesheets/application.css", css)
      capture_io { generate(:component, '--stylesheet=tailwind', "-r=#{@apptmp}/sample_project") }
      expected = "@import url(\"reset.css\");\n@import url('print.css') print;\n@import url(\"//cdn.example.com/x.css\");\n@import url(/base.css);\n" \
                 "@import \"tailwindcss\";\n\n.a { color: red; }\n"
      assert_equal expected, File.read("#{@apptmp}/sample_project/app/stylesheets/application.css")
    end

    it 'should move public styles with a byte order mark or non-UTF-8 bytes into the tailwind source' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      File.binwrite("#{@apptmp}/sample_project/public/stylesheets/application.css", "\xEF\xBB\xBF@charset \"UTF-8\";\nbody { content: \"\xE9\"; }\n")
      capture_io { generate(:component, '--stylesheet=tailwind', "-r=#{@apptmp}/sample_project") }
      expected = "@charset \"UTF-8\";\n@import \"tailwindcss\";\n\nbody { content: \"\xE9\"; }\n".b
      assert_equal expected, File.binread("#{@apptmp}/sample_project/app/stylesheets/application.css")
    end

    it 'should keep the tailwind source when re-run after a build' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--stylesheet=tailwind') }
      source = "#{@apptmp}/sample_project/app/stylesheets/application.css"
      File.write(source, "@import \"tailwindcss\";\n.btn { @apply px-4 py-2; }\n")
      File.write("#{@apptmp}/sample_project/public/stylesheets/application.css", ".btn{padding:1rem}\n")
      Readline.stubs(:readline).returns('y')
      capture_io { generate(:component, '--stylesheet=tailwind', "-r=#{@apptmp}/sample_project") }
      assert_equal "@import \"tailwindcss\";\n.btn { @apply px-4 py-2; }\n", File.read(source)
      assert File.exist?("#{@apptmp}/sample_project/public/stylesheets/application.css")
    end

    it 'should keep an edited tailwind rake file when applied again without a terminal' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--stylesheet=tailwind') }
      rakefile = "#{@apptmp}/sample_project/tasks/tailwind.rake"
      File.write(rakefile, "# edited\n")
      Readline.stubs(:readline).returns(nil)
      capture_io { generate(:component, '--stylesheet=tailwind', "-r=#{@apptmp}/sample_project") }
      assert_equal "# edited\n", File.read(rakefile)
    end

    it 'should tell to remove the old stylesheet engine when switching to tailwind' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--stylesheet=scss') }
      File.write("#{@apptmp}/sample_project/app/stylesheets/application.scss", ".compiled { color: red; }\n")
      File.write("#{@apptmp}/sample_project/public/stylesheets/application.css", ".compiled { color: red; }\n")
      Readline.stubs(:readline).returns('yes').once
      out, = capture_io { generate(:component, '--stylesheet=tailwind', "-r=#{@apptmp}/sample_project") }
      assert_equal "@import \"tailwindcss\";\n", File.read("#{@apptmp}/sample_project/app/stylesheets/application.css")
      assert_match(%r{Switching from scss: .* remove them from Gemfile, app/app\.rb and config/initializers/scss\.rb\.}, out)
    end

    it 'should move hand-written public styles when switching from scss without a scss source' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--stylesheet=scss') }
      File.write("#{@apptmp}/sample_project/public/stylesheets/application.css", ".handwritten { color: red; }\n")
      Readline.stubs(:readline).returns('yes').once
      capture_io { generate(:component, '--stylesheet=tailwind', "-r=#{@apptmp}/sample_project") }
      assert_equal "@import \"tailwindcss\";\n\n.handwritten { color: red; }\n", File.read("#{@apptmp}/sample_project/app/stylesheets/application.css")
    end

    it 'should not move compiled scss output when the project path has glob characters' do
      root = "#{@apptmp}/projects [old]"
      capture_io { generate(:project, 'sample_project', "--root=#{root}", '--stylesheet=scss') }
      File.write("#{root}/sample_project/app/stylesheets/application.scss", ".compiled { color: red; }\n")
      File.write("#{root}/sample_project/public/stylesheets/application.css", ".compiled { color: red; }\n")
      Readline.stubs(:readline).returns('yes').once
      capture_io { generate(:component, '--stylesheet=tailwind', "-r=#{root}/sample_project") }
      assert_equal "@import \"tailwindcss\";\n", File.read("#{root}/sample_project/app/stylesheets/application.css")
    end

    it 'should append the tailwind watcher to Procfile.dev once' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      File.write("#{@apptmp}/sample_project/Procfile.dev", "web: bundle exec padrino start\nvite: bundle exec vite dev\n")
      2.times { capture_io { generate(:component, '--stylesheet=tailwind', "-r=#{@apptmp}/sample_project") } }
      assert_equal "web: bundle exec padrino start\nvite: bundle exec vite dev\ncss: bundle exec rake tailwind:watch\n", File.read("#{@apptmp}/sample_project/Procfile.dev")
      assert_equal 1, File.read("#{@apptmp}/sample_project/.gitignore").scan(%r{^public/stylesheets/application\.css$}).size
    end

    it 'should start the tailwind lines on a new line' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      procfile = "#{@apptmp}/sample_project/Procfile.dev"
      gitignore = "#{@apptmp}/sample_project/.gitignore"
      File.write(procfile, 'web: bundle exec puma')
      File.write(gitignore, '.env')
      2.times { capture_io { generate(:component, '--stylesheet=tailwind', "-r=#{@apptmp}/sample_project") } }
      assert_equal "web: bundle exec puma\ncss: bundle exec rake tailwind:watch\n", File.read(procfile)
      assert_equal ".env\npublic/stylesheets/application.css\n", File.read(gitignore)
    end

    it 'should keep a css process already in Procfile.dev' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      procfile = "#{@apptmp}/sample_project/Procfile.dev"
      File.write(procfile, "web: bundle exec puma\ncss: bin/rails tailwindcss:watch\n")
      capture_io { generate(:component, '--stylesheet=tailwind', "-r=#{@apptmp}/sample_project") }
      assert_equal "web: bundle exec puma\ncss: bin/rails tailwindcss:watch\n", File.read(procfile)
    end

    it 'should properly generate with adapter' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      out, = capture_io { generate(:component, '--orm=sequel', '--adapter=postgres', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/gem 'pg'/, "#{@apptmp}/sample_project/Gemfile")
      refute_match(/Switch renderer to/, out)
      components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
      assert_equal 'sequel', components_chosen[:orm]
    end

    it 'should stop with the valid choices for an invalid option at the end of input' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      Thor::LineEditor.stubs(:readline).returns(nil).then.raises(RuntimeError, 'prompted again at end of input')
      stop = nil
      _, err = Timeout.timeout(30) do
        capture_io { stop = assert_raises(SystemExit) { generate(:component, '--orm=bogus', "-r=#{@apptmp}/sample_project") } }
      end
      assert_equal 1, stop.status
      assert_match(/No input left to choose a valid --orm; pass one of: .*\bsequel\b/, err)
    end

    %w[--renderer=bogus --adapter=bogus].each do |option|
      it "should change nothing when #{option} has no valid answer at the end of input" do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
        before = Dir["#{@apptmp}/sample_project/**/*", "#{@apptmp}/sample_project/.components"].to_h { |path| [path, File.file?(path) && File.read(path)] }
        Thor::LineEditor.stubs(:readline).returns(nil).then.raises(RuntimeError, 'prompted again at end of input')
        stop = nil
        Timeout.timeout(30) do
          capture_io { stop = assert_raises(SystemExit) { generate(:component, '--orm=sequel', option, "-r=#{@apptmp}/sample_project") } }
        end
        assert_equal 1, stop.status
        after = Dir["#{@apptmp}/sample_project/**/*", "#{@apptmp}/sample_project/.components"].to_h { |path| [path, File.file?(path) && File.read(path)] }
        assert_equal before, after
      end
    end

    it 'should enable fiber concurrency when adding an orm to a falcon project' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--server=falcon') }
      capture_io { generate(:component, '--orm=sequel', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/^Sequel\.extension :fiber_concurrency$/, "#{@apptmp}/sample_project/config/database.rb")
    end

    it 'should set the mongoid default time zone once when the orm is added again' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      2.times { capture_io { generate(:component, '--orm=mongoid', "-r=#{@apptmp}/sample_project") } }
      database = File.read("#{@apptmp}/sample_project/config/database.rb")
      assert_equal 1, database.scan(/^Time\.zone_default \|\|= Time\.find_zone!\('UTC'\)$/).size
    end

    it 'should not enable fiber concurrency when adding an orm to another project' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--server=puma') }
      capture_io { generate(:component, '--orm=sequel', "-r=#{@apptmp}/sample_project") }
      assert_no_match_in_file(/fiber_concurrency/, "#{@apptmp}/sample_project/config/database.rb")
    end

    it 'should load the mocha integration for the project test component' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=minitest', '--script=none') }
      capture_io { generate(:component, '--mock=mocha', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(%r{^require_relative '../config/boot'\nrequire 'mocha/minitest'\n}, "#{@apptmp}/sample_project/test/test_config.rb")
    end

    it 'should load rr for the project test component, once when run again' do
      { 'minitest' => ['test/test_config.rb', "require 'rr'\n"],
        'rspec' => ['spec/spec_helper.rb', "  conf.mock_with :rr\n"],
        'testunit' => ['test/test_config.rb', "require 'test/unit/rr'\n"],
        'shoulda' => ['test/test_config.rb', "require 'test/unit/rr'\n"] }.each do |test, (path, setup)|
        project = "#{@apptmp}/project_#{test}"
        capture_io { generate(:project, "project_#{test}", "--root=#{@apptmp}", "--test=#{test}", '--script=none') }
        2.times { capture_io { generate(:component, '--mock=rr', "-r=#{project}") } }
        assert_equal 1, File.read("#{project}/#{path}").scan(setup).size, "#{test}: #{path}"
        assert_no_match_in_file(/RR::Adapters/, "#{project}/#{path}")
        assert_equal 1, File.read("#{project}/Gemfile").scan(/^gem 'rr'/).size, test
      end
      assert_equal 1, File.read("#{@apptmp}/project_rspec/spec/spec_helper.rb").scan('RSpec::Core::ExampleGroup.include RR::DSL').size
      %w[testunit shoulda].each do |test|
        assert_equal 1, File.read("#{@apptmp}/project_#{test}/Gemfile").scan(/^gem 'test-unit-rr'/).size, test
      end
    end

    it 'should enable @app_name value' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate_with_parts(:component, '--test=cucumber', "-r=#{@apptmp}/sample_project", apps: 'app') }
      assert_match_in_file(/SampleProject::App\.tap \{ \|app\|  \}/, "#{@apptmp}/sample_project/features/support/env.rb")
    end

    it 'should generate component in specified app' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:app, 'compo', "-r=#{@apptmp}/sample_project") }
      capture_io { generate_with_parts(:component, '--test=cucumber', '--app=compo', "-r=#{@apptmp}/sample_project", apps: 'compo') }
      assert_match_in_file(/SampleProject::Compo\.tap \{ \|app\|  \}/, "#{@apptmp}/sample_project/features/support/env.rb")
    end

    it 'should not generate component in specified app if the app does not exist' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      out, = capture_io { assert_equal 1, assert_raises(SystemExit) { generate_with_parts(:component, '--test=cucumber', '--app=compo', "-r=#{@apptmp}/sample_project", apps: 'compo') }.status }
      assert_match(/SampleProject::Compo does not exist./, out)
      assert_no_file_exists("#{@apptmp}/sample_project/features")
    end

    it 'should not apply the other components when the app for the test component does not exist' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      out, = capture_io do
        assert_equal 1, assert_raises(SystemExit) { generate_with_parts(:component, '--orm=sequel', '--test=cucumber', '--app=compo', "-r=#{@apptmp}/sample_project", apps: 'compo') }.status
      end
      assert_match(/SampleProject::Compo does not exist./, out)
      assert_no_file_exists("#{@apptmp}/sample_project/config/database.rb")
      assert_equal 'none', YAML.load_file("#{@apptmp}/sample_project/.components")[:orm]
    end
  end

  describe 'vite script component' do
    it 'should start on a new line when Procfile.dev and .gitignore lack a trailing newline' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      root = "#{@apptmp}/sample_project"
      File.write("#{root}/Procfile.dev", 'web: bundle exec puma')
      File.write("#{root}/.gitignore", '.env')
      capture_io { generate(:component, '--script=vite', "-r=#{root}") }
      assert_equal "web: bundle exec puma\nvite: bundle exec vite dev\n", File.read("#{root}/Procfile.dev")
      assert_equal ".env\n/public/vite*\nnode_modules\n*.local\n", File.read("#{root}/.gitignore")
    end

    it 'should keep an activesupport line the Gemfile already has' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      root = "#{@apptmp}/sample_project"
      File.write("#{root}/Gemfile", "#{File.read("#{root}/Gemfile")}gem 'activesupport', '~> 8.1'\n")
      capture_io { generate(:component, '--script=vite', "-r=#{root}") }
      assert_equal 1, File.read("#{root}/Gemfile").scan(/^gem 'activesupport'/).size
    end

    it 'should keep an activesupport line written as a parenthesized call' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      root = "#{@apptmp}/sample_project"
      File.write("#{root}/Gemfile", "#{File.read("#{root}/Gemfile")}gem('activesupport', '~> 8.1')\n")
      capture_io { generate(:component, '--script=vite', "-r=#{root}") }
      assert_equal 1, File.read("#{root}/Gemfile").scan(/activesupport/).size
    end

    it 'should apply to a project without a Rakefile' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      FileUtils.rm("#{@apptmp}/sample_project/Rakefile")
      capture_io { generate(:component, '--script=vite', "-r=#{@apptmp}/sample_project") }
      assert_equal 'vite', YAML.load_file("#{@apptmp}/sample_project/.components")[:script]
    end

    it 'should apply when the default external encoding is not UTF-8' do
      original = Encoding.default_external
      begin
        capture_io { Encoding.default_external = Encoding::US_ASCII }
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=vite') }
      ensure
        capture_io { Encoding.default_external = original }
      end
      assert_file_exists("#{@apptmp}/sample_project/app/frontend/entrypoints/application.js")
    end

    it 'should apply to a project without a Gemfile' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      FileUtils.rm("#{@apptmp}/sample_project/Gemfile")
      capture_io { generate(:component, '--script=vite', "-r=#{@apptmp}/sample_project") }
      assert_file_exists("#{@apptmp}/sample_project/vite.config.ts")
    end

    it 'should say how to require Object#try when config/boot.rb has no Bundler.require line' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      root = "#{@apptmp}/sample_project"
      File.write("#{root}/config/boot.rb", File.read("#{root}/config/boot.rb").sub('Bundler.require(:default, RACK_ENV)', 'Bundler.require(:default, RACK_ENV.to_sym)'))
      out, = capture_io { generate(:component, '--script=vite', "-r=#{root}") }
      assert_match(%r{Add `require 'active_support/core_ext/object/try'`}, out)
    end

    it 'should add vite to an existing project and keep its package.json' do
      capture_io { generate(:project, 'sample_project', '--renderer=haml', "--root=#{@apptmp}") }
      File.write("#{@apptmp}/sample_project/package.json", "{}\n")
      out, = capture_io { generate(:component, '--script=vite', "-r=#{@apptmp}/sample_project") }
      assert_match(/applying.*?vite.*?script/, out)
      assert_match(/npm install -D vite@\^8\.0\.0 vite-plugin-ruby@\^5\.2\.5/, out)
      assert_match(/application\.haml/, out)
      assert_match(/^\s+= vite_javascript_tag 'application'/, out)
      assert_equal "{}\n", File.read("#{@apptmp}/sample_project/package.json")
      assert_match_in_file(/gem 'vite_padrino', '~> 3.0'/, "#{@apptmp}/sample_project/Gemfile")
      assert_match_in_file(/register VitePadrino/, "#{@apptmp}/sample_project/app/app.rb")
      assert_file_exists("#{@apptmp}/sample_project/app/frontend/entrypoints/application.js")
    end

    it 'should add the vite process to an existing Procfile.dev' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      procfile = "#{@apptmp}/sample_project/Procfile.dev"
      File.write(procfile, "web: bundle exec puma\n")
      capture_io { generate(:component, '--script=vite', "-r=#{@apptmp}/sample_project") }
      assert_equal "web: bundle exec puma\nvite: bundle exec vite dev\n", File.read(procfile)
    end

    it 'should keep a vite process already in Procfile.dev' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      procfile = "#{@apptmp}/sample_project/Procfile.dev"
      File.write(procfile, "web: bundle exec puma\nvite: bin/vite dev\n")
      capture_io { generate(:component, '--script=vite', "-r=#{@apptmp}/sample_project") }
      assert_equal "web: bundle exec puma\nvite: bin/vite dev\n", File.read(procfile)
    end

    it 'should keep edited vite files when applied again without a terminal' do
      capture_io { generate(:project, 'sample_project', '--script=vite', "--root=#{@apptmp}") }
      edited = %w[vite.config.ts app/frontend/entrypoints/application.js config/vite.json].map { |path| "#{@apptmp}/sample_project/#{path}" }
      edited.each { |path| File.write(path, "// edited\n") }
      Readline.stubs(:readline).returns(nil)
      capture_io { generate(:component, '--script=vite', "-r=#{@apptmp}/sample_project") }
      assert_equal(["// edited\n"] * 3, edited.map { |path| File.read(path) })
      assert_equal 1, File.read("#{@apptmp}/sample_project/Gemfile").scan(/^gem 'activesupport'/).size
      assert_equal 1, File.read("#{@apptmp}/sample_project/config/boot.rb").scan(%r{active_support/core_ext/object/try}).size
      assert_equal 1, File.read("#{@apptmp}/sample_project/Rakefile").scan('ViteRuby.install_tasks').size
      assert_equal "web: bundle exec padrino start\nvite: bundle exec vite dev\n", File.read("#{@apptmp}/sample_project/Procfile.dev")
    end
  end

  describe 'specified of same the component' do
    it 'should does not change' do
      capture_io { generate(:project, 'sample_project', '--script=jquery', "--root=#{@apptmp}") }
      components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
      assert_equal 'jquery', components_chosen[:script]
      out, = capture_io { generate(:component, '--script=jquery', "-r=#{@apptmp}/sample_project") }
      assert_match(/applying.*?jquery.*?script/, out)
      refute_match(/Switch renderer to/, out)
      components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
      assert_equal 'jquery', components_chosen[:script]
    end
  end

  describe 'component changes' do
    it 'should when allow changes, will be applied' do
      capture_io { generate(:project, 'sample_project', '--renderer=slim', "--root=#{@apptmp}") }
      components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
      assert_equal 'slim', components_chosen[:renderer]
      Readline.stubs(:readline).returns('yes').once
      out, = capture_io { generate(:component, '--renderer=haml', "-r=#{@apptmp}/sample_project") }
      assert_match(/applying.*?haml.*?renderer/, out)
      components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
      assert_equal 'haml', components_chosen[:renderer]
    end

    it 'should when deny changes, will not be applied' do
      capture_io { generate(:project, 'sample_project', '--renderer=slim', "--root=#{@apptmp}") }
      components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
      assert_equal 'slim', components_chosen[:renderer]
      Readline.stubs(:readline).returns('no').once
      out, = capture_io { generate(:component, '--renderer=haml', "-r=#{@apptmp}/sample_project") }
      refute_match(/applying.*?haml.*?renderer/, out)
      components_chosen = YAML.load_file("#{@apptmp}/sample_project/.components")
      assert_equal 'slim', components_chosen[:renderer]
    end
  end
end
