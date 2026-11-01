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

    describe 'applied again with the same choice' do
      def rerun(*args)
        Readline.stubs(:readline).returns(nil)
        capture_io { generate(:component, *args, "-r=#{@apptmp}/sample_project") }
      end

      def rerun_test(*args, apps: 'app')
        Readline.stubs(:readline).returns(nil)
        capture_io { generate_with_parts(:component, *args, "-r=#{@apptmp}/sample_project", apps: apps) }
      end

      def project_file(path)
        "#{@apptmp}/sample_project/#{path}"
      end

      it 'should keep an edited database config for every orm' do
        %w[activerecord mongoid sequel].each do |orm|
          `rm -rf #{@apptmp}/sample_project`
          capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", "--orm=#{orm}") }
          File.write(project_file('config/database.rb'), "# edited\n")
          rerun("--orm=#{orm}")
          assert_equal "# edited\n", File.read(project_file('config/database.rb')), orm
        end
      end

      it 'should keep the adapter of the project and add no other driver' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=sequel', '--adapter=postgres') }
        assert_equal 'postgres', YAML.load_file(project_file('.components'))[:adapter]
        rerun('--orm=sequel')
        assert_no_match_in_file(/gem 'sqlite3'/, project_file('Gemfile'))
        assert_equal 'postgres', YAML.load_file(project_file('.components'))[:adapter]
      end

      it 'should keep an edited database config when given the adapter the project has' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=sequel', '--adapter=postgres') }
        File.write(project_file('config/database.rb'), "# edited\n")
        rerun('--orm=sequel', '--adapter=postgres')
        assert_equal "# edited\n", File.read(project_file('config/database.rb'))
      end

      it 'should keep an edited database config when a mistyped adapter is corrected to the project one' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=sequel', '--adapter=postgres') }
        File.write(project_file('config/database.rb'), "# edited\n")
        Readline.stubs(:readline).returns('postgres', nil)
        capture_io { generate(:component, '--orm=sequel', '--adapter=postgress', "-r=#{@apptmp}/sample_project") }
        assert_equal "# edited\n", File.read(project_file('config/database.rb'))
      end

      it 'should not record an adapter it did not use for a project that has none stored' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=sequel', '--adapter=postgres') }
        components = YAML.load_file(project_file('.components'))
        components.delete(:adapter)
        File.write(project_file('.components'), components.to_yaml)
        rerun('--orm=sequel')
        assert_no_match_in_file(/gem 'sqlite3'/, project_file('Gemfile'))
        assert_nil YAML.load_file(project_file('.components'))[:adapter]
        assert_match_in_file(%r{postgres://localhost}, project_file('config/database.rb'))
        rerun('--orm=sequel', '--adapter=sqlite')
        assert_match_in_file(%r{sqlite://}, project_file('config/database.rb'))
      end

      it 'should not record an adapter it did not use for an activerecord project that has none stored' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=activerecord', '--adapter=postgres') }
        components = YAML.load_file(project_file('.components'))
        components.delete(:adapter)
        File.write(project_file('.components'), components.to_yaml)
        rerun('--orm=activerecord')
        assert_no_match_in_file(/gem 'sqlite3'/, project_file('Gemfile'))
        assert_nil YAML.load_file(project_file('.components'))[:adapter]
        assert_match_in_file(/adapter:\s+'postgresql'/, project_file('config/database.rb'))
        rerun('--orm=activerecord', '--adapter=sqlite')
        assert_match_in_file(/adapter: 'sqlite3'/, project_file('config/database.rb'))
        assert_no_match_in_file(/postgresql/, project_file('config/database.rb'))
      end

      it 'should rewrite the database config when given another adapter' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=sequel') }
        rerun('--orm=sequel', '--adapter=postgres')
        assert_match_in_file(%r{postgres://localhost}, project_file('config/database.rb'))
        assert_equal 'postgres', YAML.load_file(project_file('.components'))[:adapter]
      end

      # Bundler refuses a Gemfile that lists a gem twice with different requirements.
      it 'should keep one activerecord line when switching to trilogy and back' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=activerecord', '--adapter=mysql2') }
        Readline.stubs(:readline).returns('yes')
        capture_io { generate(:component, '--orm=activerecord', '--adapter=trilogy', "-r=#{@apptmp}/sample_project") }
        assert_equal ["gem 'activerecord', '>= 7.1', require: 'active_record'"], File.readlines(project_file('Gemfile'), chomp: true).grep(/activerecord/)
        assert_match_in_file(/adapter:   'trilogy'/, project_file('config/database.rb'))
        assert_equal 'trilogy', YAML.load_file(project_file('.components'))[:adapter]

        capture_io { generate(:component, '--orm=activerecord', '--adapter=mysql2', "-r=#{@apptmp}/sample_project") }
        assert_equal ["gem 'activerecord', '>= 3.1', require: 'active_record'"], File.readlines(project_file('Gemfile'), chomp: true).grep(/activerecord/)
        assert_match_in_file(/adapter:   'mysql2'/, project_file('config/database.rb'))
      end

      def activerecord_lines
        File.readlines(project_file('Gemfile'), chomp: true).grep(/activerecord/)
      end

      def edit_gemfile(from, to)
        File.write(project_file('Gemfile'), File.read(project_file('Gemfile')).sub(from, to))
      end

      floors = { 'mysql2' => '>= 3.1', 'trilogy' => '>= 7.1' }
      [%w[mysql2 trilogy], %w[trilogy mysql2]].each do |from, to|
        old_line = "gem 'activerecord', '#{floors[from]}', require: 'active_record'"
        new_line = "gem 'activerecord', '#{floors[to]}', require: 'active_record'"

        it "should move the floor below a blank line when switching from #{from} to #{to}" do
          capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=activerecord', "--adapter=#{from}") }
          edit_gemfile(old_line, "\n#{old_line}")
          Readline.stubs(:readline).returns('yes')
          out, = capture_io { generate(:component, '--orm=activerecord', "--adapter=#{to}", "-r=#{@apptmp}/sample_project") }
          assert_equal [new_line], activerecord_lines
          assert_includes File.read(project_file('Gemfile')), "\n\n#{new_line}\n"
          refute_includes out, 'Keeping the Gemfile line'
        end

        it "should move the floor of an indented line when switching from #{from} to #{to}" do
          capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=activerecord', "--adapter=#{from}") }
          edit_gemfile(old_line, "group :default do\n  #{old_line}\nend")
          Readline.stubs(:readline).returns('yes')
          out, = capture_io { generate(:component, '--orm=activerecord', "--adapter=#{to}", "-r=#{@apptmp}/sample_project") }
          assert_equal ["  #{new_line}"], activerecord_lines
          refute_includes out, 'Keeping the Gemfile line'
        end
      end

      it 'should keep a raised activerecord floor when rerun on a mysql2 project' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=activerecord', '--adapter=mysql2') }
        edit_gemfile("'>= 3.1'", "'>= 7.1'")
        rerun('--orm=activerecord')
        assert_equal ["gem 'activerecord', '>= 7.1', require: 'active_record'"], activerecord_lines
      end

      it 'should keep a raised activerecord floor when rerun on a project with no stored adapter' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=activerecord', '--adapter=mysql2') }
        components = YAML.load_file(project_file('.components'))
        components.delete(:adapter)
        File.write(project_file('.components'), components.to_yaml)
        edit_gemfile("'>= 3.1'", "'>= 7.1'")
        rerun('--orm=activerecord')
        assert_equal ["gem 'activerecord', '>= 7.1', require: 'active_record'"], activerecord_lines
      end

      it 'should keep one activerecord line when rerun on a pinned trilogy project' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=activerecord', '--adapter=trilogy') }
        edit_gemfile("'>= 7.1'", "'~> 8.0'")
        rerun('--orm=activerecord')
        assert_equal ["gem 'activerecord', '~> 8.0', require: 'active_record'"], activerecord_lines
      end

      [
        "gem 'activerecord', '~> 8.0'", %(gem "activerecord", ">= 3.1", require: "active_record"), %(  gem 'activerecord'),
        "gem('activerecord', '~> 8.0')", "gem  'activerecord', '~> 8.0'"
      ].each do |line|
        it "should leave #{line.strip} and warn when switching to trilogy" do
          capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=activerecord', '--adapter=mysql2') }
          edit_gemfile("gem 'activerecord', '>= 3.1', require: 'active_record'", line)
          Readline.stubs(:readline).returns('yes')
          out, = capture_io { generate(:component, '--orm=activerecord', '--adapter=trilogy', "-r=#{@apptmp}/sample_project") }
          assert_equal [line], activerecord_lines
          assert_includes out, "Keeping the Gemfile line #{line.strip}"
        end
      end

      it 'should raise the floor when returning to activerecord with the trilogy adapter of sequel' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=activerecord', '--adapter=mysql2') }
        Readline.stubs(:readline).returns('yes')
        capture_io { generate(:component, '--orm=sequel', '--adapter=trilogy', "-r=#{@apptmp}/sample_project") }
        capture_io { generate(:component, '--orm=activerecord', '--adapter=trilogy', "-r=#{@apptmp}/sample_project") }
        assert_equal ["gem 'activerecord', '>= 7.1', require: 'active_record'"], activerecord_lines
      end

      it 'should leave a pinned line without a warning when switching between other adapters' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=activerecord', '--adapter=mysql2') }
        edit_gemfile("gem 'activerecord', '>= 3.1', require: 'active_record'", "gem 'activerecord', '~> 8.0'")
        Readline.stubs(:readline).returns('yes')
        out, = capture_io { generate(:component, '--orm=activerecord', '--adapter=postgres', "-r=#{@apptmp}/sample_project") }
        assert_equal ["gem 'activerecord', '~> 8.0'"], activerecord_lines
        refute_includes out, 'Keeping the Gemfile line'
      end

      it 'should not count activerecord-import as the activerecord line' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=sequel') }
        edit_gemfile("gem 'sequel'\n", "gem 'sequel'\ngem 'activerecord-import'\n")
        Readline.stubs(:readline).returns('yes')
        capture_io { generate(:component, '--orm=activerecord', "-r=#{@apptmp}/sample_project") }
        assert_includes activerecord_lines, "gem 'activerecord', '>= 3.1', require: 'active_record'"
      end

      %w[activerecord sequel].each do |orm|
        it "should change nothing when rerun on a #{orm} trilogy project" do
          capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", "--orm=#{orm}", '--adapter=trilogy') }
          gemfile, config = %w[Gemfile config/database.rb].map { |path| File.read(project_file(path)) }
          rerun("--orm=#{orm}")
          assert_equal gemfile, File.read(project_file('Gemfile'))
          assert_equal config, File.read(project_file('config/database.rb'))
          assert_equal 'trilogy', YAML.load_file(project_file('.components'))[:adapter]
        end
      end

      it 'should rewrite the database config when switching a sequel project to trilogy' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=sequel', '--adapter=mysql2') }
        Readline.stubs(:readline).returns('yes')
        capture_io { generate(:component, '--orm=sequel', '--adapter=trilogy', "-r=#{@apptmp}/sample_project") }
        assert_no_match_in_file(%r{mysql2://}, project_file('config/database.rb'))
        assert_match_in_file(%r{"trilogy://root@127.0.0.1/sample_project_test"}, project_file('config/database.rb'))
        assert_match_in_file(/gem 'trilogy'/, project_file('Gemfile'))
        assert_equal 'trilogy', YAML.load_file(project_file('.components'))[:adapter]
      end

      it 'should rewrite the database config when switching orm' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=sequel') }
        Readline.stubs(:readline).returns('yes')
        capture_io { generate(:component, '--orm=activerecord', "-r=#{@apptmp}/sample_project") }
        assert_match_in_file(/ActiveRecord::Base\.configurations/, project_file('config/database.rb'))
      end

      it 'should keep edited test setup files for every test component' do
        { 'bacon' => 'test/test.rake', 'minitest' => 'test/test.rake', 'rspec' => 'spec/spec.rake', 'shoulda' => 'test/test.rake',
          'testunit' => 'test/test.rake', 'cucumber' => 'cucumber.yml' }.each do |test, rake|
          `rm -rf #{@apptmp}/sample_project`
          capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", "--test=#{test}") }
          config = test == 'rspec' || test == 'cucumber' ? 'spec/spec_helper.rb' : 'test/test_config.rb'
          [rake, config].each { |file| File.write(project_file(file), "# edited\n") }
          rerun_test("--test=#{test}")
          [rake, config].each { |file| assert_equal "# edited\n", File.read(project_file(file)), "#{test}: #{file}" }
        end
      end

      it 'should keep the other edited setup files of cucumber' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=cucumber') }
        files = %w[features/support/env.rb features/support/url.rb spec/spec.rake]
        files.each { |file| File.write(project_file(file), "# edited\n") }
        rerun_test('--test=cucumber')
        files.each { |file| assert_equal "# edited\n", File.read(project_file(file)), file }
      end

      it 'should keep an edited stylesheet initializer and connection pool middleware' do
        %w[sass scss].each do |stylesheet|
          `rm -rf #{@apptmp}/sample_project`
          capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--orm=activerecord', "--stylesheet=#{stylesheet}") }
          files = %W[config/initializers/#{stylesheet}.rb lib/connection_pool_management_middleware.rb]
          files.each { |file| File.write(project_file(file), "# edited\n") }
          rerun('--orm=activerecord', "--stylesheet=#{stylesheet}")
          files.each { |file| assert_equal "# edited\n", File.read(project_file(file)), "#{stylesheet}: #{file}" }
        end
      end

      it 'should still point the test setup at the app named with --app' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=minitest') }
        capture_io { generate(:app, 'compo', "-r=#{@apptmp}/sample_project") }
        rerun_test('--test=minitest', '--app=compo', apps: 'compo')
        assert_match_in_file(/SampleProject::Compo/, project_file('test/test_config.rb'))
      end

      it 'should not bring back the cucumber samples a project deleted' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=cucumber') }
        samples = %w[features/add.feature features/step_definitions/add_steps.rb]
        samples.each { |file| File.delete(project_file(file)) }
        rerun_test('--test=cucumber')
        samples.each { |file| assert_no_file_exists(project_file(file)) }
      end

      it 'should write the test setup of the new component when switching' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=minitest') }
        File.write(project_file('test/test.rake'), "# edited\n")
        Readline.stubs(:readline).returns('yes')
        capture_io { generate_with_parts(:component, '--test=testunit', "-r=#{@apptmp}/sample_project", apps: 'app') }
        assert_no_match_in_file(/edited/, project_file('test/test.rake'))
      end

      it 'should keep an edited application.js for every script component' do
        %w[dojo htmx jquery mootools prototype ujs].each do |script|
          `rm -rf #{@apptmp}/sample_project`
          capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", "--script=#{script}") }
          File.write(project_file('public/javascripts/application.js'), "// edited\n")
          rerun("--script=#{script}")
          assert_equal "// edited\n", File.read(project_file('public/javascripts/application.js')), script
        end
      end
      it 'should keep an edited ujs.js' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=ujs') }
        File.write(project_file('public/javascripts/ujs.js'), "// edited\n")
        rerun('--script=ujs')
        assert_equal "// edited\n", File.read(project_file('public/javascripts/ujs.js'))
      end
    end

    describe 'ujs script component' do
      def script_choice
        YAML.load_file("#{@apptmp}/sample_project/.components")[:script]
      end

      def ujs_file
        "#{@apptmp}/sample_project/public/javascripts/ujs.js"
      end

      def apply_script(script, answer)
        Readline.stubs(:readline).returns(answer)
        capture_io { generate(:component, "--script=#{script}", "-r=#{@apptmp}/sample_project") }
      end

      it 'should add ujs to a project without a script' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
        capture_io { generate(:component, '--script=ujs', "-r=#{@apptmp}/sample_project") }
        assert_match_in_file(/data-method/, ujs_file)
        assert_equal 'ujs', script_choice
      end

      it 'should switch from jquery to ujs and back' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=jquery') }
        out, = apply_script('ujs', 'yes')
        assert_match(/applying.*?ujs.*?script/, out)
        assert_match(/remove the include tag of any script it replaces/, out)
        assert_match_in_file(/data-method/, ujs_file)
        assert_equal 'ujs', script_choice
        apply_script('jquery', 'yes')
        assert_equal 'jquery', script_choice
      end

      # An --api project has no padrino-helpers, so its layout has neither csrf_meta_tags nor javascript_include_tag.
      it 'should give a plain script tag for an api project' do
        out, = capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--api', '--script=ujs') }
        assert_includes out, '<script src="/javascripts/ujs.js"></script>'
        refute_match(/csrf_meta_tags/, out)
      end

      it 'should give a plain script tag when added to an api project' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--api') }
        out, = capture_io { generate(:component, '--script=ujs', "-r=#{@apptmp}/sample_project") }
        assert_includes out, '<script src="/javascripts/ujs.js"></script>'
        refute_match(/csrf_meta_tags/, out)
      end

      it 'should keep jquery when no input answers the switch prompt' do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=jquery') }
        Timeout.timeout(5) { apply_script('ujs', nil) }
        assert_no_file_exists(ujs_file)
        assert_equal 'jquery', script_choice
      end
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

    describe 'switching the mock component' do
      # The setup lines each mock adds to the helper of each test component.
      def mock_setup
        rr_rspec = ['  conf.mock_with :rr', "  # On ExampleGroup, not conf.include, so RSpec's own matchers (satisfy) stay ahead of rr's DSL.",
                    '  RSpec::Core::ExampleGroup.include RR::DSL']
        { 'mocha' => { 'rspec' => ['  conf.mock_with :mocha'], 'minitest' => ["require 'mocha/minitest'"],
                       'testunit' => ["require 'mocha/test_unit'"], 'shoulda' => ["require 'mocha/test_unit'"] },
          'rr' => { 'rspec' => rr_rspec, 'minitest' => ["require 'rr'"],
                    'testunit' => ["require 'test/unit/rr'"], 'shoulda' => ["require 'test/unit/rr'"] } }
      end

      def switch_mock(project, mock, *args)
        Readline.stubs(:readline).returns('yes')
        capture_io { generate_with_parts(:component, "--mock=#{mock}", *args, "-r=#{project}", apps: 'app') }
      end

      def assert_mock_setup(helper, test, mock)
        other = (mock_setup.keys - [mock]).first
        lines = File.read(helper).lines.map(&:chomp)
        mock_setup[mock][test].each { |line| assert_equal 1, lines.count(line), "#{test}: #{line}" }
        mock_setup[other][test].each { |line| assert_equal 0, lines.count { |l| l.strip == line.strip }, "#{test}: #{line}" }
        assert_equal 1, lines.count('# edited by the project'), test
        assert_equal mock, YAML.load_file("#{File.dirname(helper)}/../.components")[:mock], test
      end

      it 'should replace the setup of the previous mock in the test helper for every test component' do
        %w[rspec minitest testunit shoulda].product([[], :test]).each do |test, with_test|
          args = with_test == :test ? ["--test=#{test}"] : []
          project = "#{@apptmp}/project_#{test}_#{args.size}"
          capture_io { generate(:project, File.basename(project), "--root=#{@apptmp}", "--test=#{test}", '--mock=mocha', '--script=none') }
          helper = "#{project}/#{test == 'rspec' ? 'spec/spec_helper.rb' : 'test/test_config.rb'}"
          File.write(helper, "#{File.read(helper)}# edited by the project\n")
          assert_mock_setup(helper, test, 'mocha')
          switch_mock(project, 'rr', *args)
          assert_mock_setup(helper, test, 'rr')
          switch_mock(project, 'rr', *args)
          assert_mock_setup(helper, test, 'rr')
          switch_mock(project, 'mocha', *args)
          assert_mock_setup(helper, test, 'mocha')
          switch_mock(project, 'mocha', *args)
          assert_mock_setup(helper, test, 'mocha')
        end
      end

      it 'should remove the rr setup for rspec whose comment the project edited' do
        project = "#{@apptmp}/sample_project"
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=rspec', '--mock=rr', '--script=none') }
        helper = "#{project}/spec/spec_helper.rb"
        File.write(helper, File.read(helper).sub(/^  # On ExampleGroup.*\n/, "  # our note\n"))
        switch_mock(project, 'mocha')
        assert_no_match_in_file(/mock_with :rr|RR::DSL/, helper)
        assert_match_in_file(/^  # our note\n/, helper)
        assert_match_in_file(/^  conf\.mock_with :mocha\n/, helper)
      end

      it 'should keep the previous mock when the new one has no line to follow' do
        project = "#{@apptmp}/sample_project"
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=minitest', '--mock=mocha', '--script=none') }
        helper = "#{project}/test/test_config.rb"
        File.write(helper, File.read(helper).sub("require_relative '../config/boot'\n", "require_relative '../config/boot' # boot\n"))
        switch_mock(project, 'rr')
        assert_match_in_file(%r{^require 'mocha/minitest'\n}, helper)
      end

      it 'should never leave the project with neither mock when the helper cannot be read' do
        project = "#{@apptmp}/sample_project"
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--test=minitest', '--mock=mocha', '--script=none') }
        helper = "#{project}/test/test_config.rb"
        File.binwrite(helper, "#{File.binread(helper)}# caf\xC3\xA9\n".b)
        external = Encoding.default_external
        verbose, $VERBOSE = $VERBOSE, nil
        Encoding.default_external = Encoding::US_ASCII
        begin
          switch_mock(project, 'rr')
        rescue ArgumentError
          # Thor can't read the helper as US-ASCII; the switch fails, as on master.
        ensure
          Encoding.default_external = external
          $VERBOSE = verbose
        end
        content = File.binread(helper)
        assert(content.include?("require 'mocha/minitest'\n") || content.include?("require 'rr'\n"), content)
      end

      it 'should switch the mock of a project whose test component has no mock setup' do
        %w[bacon cucumber none].each do |test|
          project = "#{@apptmp}/project_#{test}"
          capture_io { generate(:project, "project_#{test}", "--root=#{@apptmp}", "--test=#{test}", '--mock=mocha', '--script=none') }
          before = Dir["#{project}/{test,spec,features}/**/*"].select { |path| File.file?(path) }.to_h { |path| [path, File.read(path)] }
          out, = switch_mock(project, 'rr')
          assert_match(/RR is in the Gemfile but not set up for the '#{test}' test component/, out)
          assert_equal 'rr', YAML.load_file("#{project}/.components")[:mock], test
          after = Dir["#{project}/{test,spec,features}/**/*"].select { |path| File.file?(path) }.to_h { |path| [path, File.read(path)] }
          assert_equal before, after, test
        end
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

    it 'should print the layout tags for a renderer applied in the same run' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      out, = capture_io { generate(:component, '--script=vite', '--renderer=haml', "-r=#{@apptmp}/sample_project") }
      assert_match(%r{layouts/application\.haml}, out)
      assert_match(/^\s+= vite_client_tag$/, out)
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

  describe 'htmx script component' do
    before { Readline.stubs(:readline).returns(nil) }

    def project_file(path)
      "#{@apptmp}/sample_project/#{path}"
    end

    def vendored_htmx
      File.binread(File.expand_path('../lib/padrino-gen/generators/templates/htmx/htmx.min.js', __dir__))
    end

    def apply_component(*args, answer: nil)
      Readline.stubs(:readline).returns(answer)
      capture_io { generate(:component, *args, "-r=#{@apptmp}/sample_project") }
    end

    it 'should install htmx and its CSRF script in a new project without the network' do
      WebMock.reset_executed_requests!
      out, = capture_io { generate(:project, 'sample_project', '--script=htmx', "--root=#{@apptmp}") }
      assert_match(/applying.*?htmx.*?script/, out)
      assert_equal vendored_htmx, File.binread(project_file('public/javascripts/htmx.js'))
      assert_match_in_file(/htmx:configRequest/, project_file('public/javascripts/htmx-csrf.js'))
      assert_match_in_file(/X-CSRF-Token/, project_file('public/javascripts/htmx-csrf.js'))
      assert_file_exists(project_file('public/javascripts/application.js'))
      assert_equal 'htmx', YAML.load_file(project_file('.components'))[:script]
      assert_not_requested :get, /.*/
    end

    it 'should add htmx to an existing project' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      apply_component('--script=htmx')
      assert_equal vendored_htmx, File.binread(project_file('public/javascripts/htmx.js'))
      assert_file_exists(project_file('public/javascripts/htmx-csrf.js'))
      assert_equal 'htmx', YAML.load_file(project_file('.components'))[:script]
    end

    it 'should install into a tiny project' do
      capture_io { generate(:project, 'sample_project', '--script=htmx', '--tiny', "--root=#{@apptmp}") }
      assert_equal vendored_htmx, File.binread(project_file('public/javascripts/htmx.js'))
      assert_file_exists(project_file('public/javascripts/htmx-csrf.js'))
    end

    it 'should keep edited files when applied again without a terminal' do
      capture_io { generate(:project, 'sample_project', '--script=htmx', "--root=#{@apptmp}") }
      edited = %w[htmx.js htmx-csrf.js application.js].map { |name| project_file("public/javascripts/#{name}") }
      edited.each { |path| File.write(path, "// edited\n") }
      apply_component('--script=htmx')
      edited.each { |path| assert_equal "// edited\n", File.read(path), path }
    end

    it 'should switch from jquery to htmx and back, keeping an edited application.js' do
      capture_io { generate(:project, 'sample_project', '--script=jquery', "--root=#{@apptmp}") }
      File.write(project_file('public/javascripts/application.js'), "// edited\n")

      apply_component('--script=htmx', answer: 'yes')
      assert_equal 'htmx', YAML.load_file(project_file('.components'))[:script]
      assert_match_in_file(/htmx:configRequest/, project_file('public/javascripts/htmx-csrf.js'))

      apply_component('--script=jquery', answer: 'yes')
      assert_equal 'jquery', YAML.load_file(project_file('.components'))[:script]
      assert_file_exists(project_file('public/javascripts/jquery-ujs.js'))
      assert_equal "// edited\n", File.read(project_file('public/javascripts/application.js'))
    end

    it 'should leave the project unchanged when the switch is declined without a terminal' do
      capture_io { generate(:project, 'sample_project', '--script=jquery', "--root=#{@apptmp}") }
      apply_component('--script=htmx')
      assert_equal 'jquery', YAML.load_file(project_file('.components'))[:script]
      assert_no_file_exists(project_file('public/javascripts/htmx.js'))
    end

    it 'should install into a lean project' do
      capture_io { generate(:project, 'sample_project', '--script=htmx', '--lean', "--root=#{@apptmp}") }
      assert_equal vendored_htmx, File.binread(project_file('public/javascripts/htmx.js'))
      assert_no_dir_exists(project_file('app'))
    end

    it 'should print a plain script tag for an api project, which has no helpers' do
      out, = capture_io { generate(:project, 'sample_project', '--script=htmx', '--api', "--root=#{@apptmp}") }
      assert_match(%r{<script src="/javascripts/htmx\.js"></script>}, out)
      refute_match(/csrf_meta_tags/, out)
      assert_file_exists(project_file('public/javascripts/htmx.js'))
    end

    it 'should print a plain script tag when added to an existing api project' do
      capture_io { generate(:project, 'sample_project', '--api', "--root=#{@apptmp}") }
      out, = apply_component('--script=htmx')
      assert_match(%r{<script src="/javascripts/htmx\.js"></script>}, out)
      refute_match(/csrf_meta_tags/, out)
    end

    it 'should print the layout lines for a renderer applied in the same run' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      out, = apply_component('--script=htmx', '--renderer=haml')
      assert_match(%r{layouts/application\.haml}, out)
      assert_match(/^\s+= csrf_meta_tags$/, out)
    end

    it 'should print the layout lines for the stored renderer when the switch is declined' do
      capture_io { generate(:project, 'sample_project', '--renderer=erb', "--root=#{@apptmp}") }
      out, = apply_component('--script=htmx', '--renderer=haml', answer: 'no')
      assert_match(%r{layouts/application\.erb}, out)
      assert_match(/<%= csrf_meta_tags %>/, out)
      assert_equal 'erb', YAML.load_file(project_file('.components'))[:renderer]
    end

    it 'should read the token where csrf_meta_tags writes it' do
      capture_io { generate(:project, 'sample_project', '--script=htmx', "--root=#{@apptmp}") }
      script = File.read(project_file('public/javascripts/htmx-csrf.js'))
      view = Object.new.extend(Padrino::Helpers::TagHelpers, Padrino::Helpers::AssetTagHelpers, Padrino::Helpers::FormHelpers::Security)
      view.stubs(is_protected_from_csrf?: true, csrf_param: 'authenticity_token', csrf_token: 'the-token')

      name = script[/meta\[name="([^"]+)"\]/, 1]
      attribute = script[/token\.(\w+)/, 1]
      tag = view.csrf_meta_tags[/<meta[^>]*name="#{name}"[^>]*>/]
      assert_match(/#{attribute}="the-token"/, tag)
    end

    it 'should print the layout lines for each template engine' do
      {
        'erb' => [/<%= csrf_meta_tags %>/, /<%= javascript_include_tag 'htmx', 'htmx-csrf', 'application' %>/, %r{layouts/application\.erb}],
        'haml' => [/^\s+= csrf_meta_tags$/, /^\s+= javascript_include_tag 'htmx', 'htmx-csrf', 'application'$/, %r{layouts/application\.haml}],
        'slim' => [/^\s+= csrf_meta_tags$/, /^\s+= javascript_include_tag 'htmx', 'htmx-csrf', 'application'$/, %r{layouts/application\.slim}]
      }.each do |renderer, expected|
        `rm -rf #{@apptmp}/sample_project`
        out, = capture_io { generate(:project, 'sample_project', '--script=htmx', "--renderer=#{renderer}", "--root=#{@apptmp}") }
        expected.each { |pattern| assert_match(pattern, out) }
      end
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
