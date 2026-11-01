require_relative '../helper'
require_relative '../fixtures/sequel'

describe 'AdminRerun' do
  before do
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{SecureRandom.hex}"
    `mkdir -p #{@apptmp}`
    @project = "#{@apptmp}/sample_project"
  end

  after do
    `rm -rf #{@apptmp}`
  end

  # Thor reads each answer through its line editor, which returns nil at the end of input.
  def with_answers(*answers)
    Thor::LineEditor.stubs(:readline).returns(*answers, nil)
    yield
  end

  def with_stdin(input)
    original = $stdin
    $stdin = StringIO.new(input)
    yield
  ensure
    $stdin = original
  end

  def edit(file)
    path = "#{@project}/#{file}"
    File.write(path, "#{yield(File.read(path))}\n# edited\n")
  end

  def snapshot
    Dir.glob("#{@project}/**/*", File::FNM_DOTMATCH).select { |path| File.file?(path) }.to_h { |path| [path, File.read(path)] }
  end

  %w[activerecord mongoid sequel].each do |orm|
    describe "with #{orm}" do
      before do
        Object.send(:remove_const, :Account) if defined?(Account)
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", "-d=#{orm}", '-e=haml') }
        capture_io { generate(:admin_app, "--root=#{@project}") }
        %w[models/account.rb db/seeds.rb admin/controllers/accounts.rb admin/views/base/index.haml public/admin/stylesheets/application.css].each do |file|
          edit(file) { |content| content }
        end
        edit('admin/app.rb') { |content| content.sub("'/accounts'", "'/accounts' # staff only") }
        edit('config/apps.rb') { |content| content.sub(".to('/admin')", ".to('/backend')") }
        edit('Gemfile') { |content| content.sub("gem 'bcrypt'", "gem 'bcrypt', '>= 3.1'") }
      end

      it 'should keep edited files when g admin runs again at the end of input' do
        edited = snapshot
        out, = capture_io { with_answers { generate(:admin_app, "--root=#{@project}") } }
        assert_equal edited, snapshot
        assert_match(%r{skip\s+admin/app\.rb}, out)
      end

      it 'should still overwrite a file when the conflict is answered with yes' do
        capture_io { with_answers(*['y'] * 50) { generate(:admin_app, "--root=#{@project}") } }
        assert_no_match_in_file(/# edited/, "#{@project}/models/account.rb")
        assert_no_match_in_file(/# edited/, "#{@project}/admin/controllers/accounts.rb")
        assert_match_in_file(/# edited/, "#{@project}/config/apps.rb")
      end

      it 'should keep the lines of app.rb when a yes rewrites it' do
        capture_io { with_answers(*['y'] * 50) { generate(:admin_app, "--root=#{@project}") } }
        app = "#{@project}/admin/app.rb"
        assert_no_match_in_file(/# edited/, app)
        assert_match_in_file(%r{role\.project_module :accounts, '/accounts'}, app)
        orm == 'activerecord' ? assert_match_in_file(/use ConnectionPoolManagement/, app) : assert_no_match_in_file(/ConnectionPoolManagement/, app)
        assert_match_in_file(/account != current_account && account\.destroy/, "#{@project}/admin/controllers/accounts.rb")
      end

      it 'should keep edited seeds that delegate to another file at the end of input' do
        File.write("#{@project}/db/seeds.rb", "load 'db/seeds/staff.rb'\n")
        edited = snapshot
        capture_io { with_answers { generate(:admin_app, "--root=#{@project}") } }
        assert_equal edited, snapshot
      end

      it 'should send delegating seeds through the overwrite prompt' do
        File.write("#{@project}/db/seeds.rb", "load 'db/seeds/staff.rb'\n")
        capture_io { with_answers(*['y'] * 50) { generate(:admin_app, "--root=#{@project}") } }
        assert_match_in_file(/Account\.new\(/, "#{@project}/db/seeds.rb")
        assert_no_file_exists("#{@project}/db/seeds.old")
      end

      it 'should move seeds without the model aside for the first install of another admin app' do
        File.write("#{@project}/db/seeds.rb", "load 'db/seeds/staff.rb'\n")
        capture_io { with_answers { generate(:admin_app, "--root=#{@project}", '-a=other') } }
        assert_match_in_file(/staff\.rb/, "#{@project}/db/seeds.old")
        assert_match_in_file(/Account\.new\(/, "#{@project}/db/seeds.rb")
      end

      it 'should keep gems declared with parentheses' do
        edit('Gemfile') do |content|
          content.sub(/^gem 'bcrypt'.*$/, "gem('bcrypt', '>= 3.1')").sub(/^gem 'activesupport'.*$/, "gem('activesupport', '>= 3.1')")
        end
        edited = snapshot
        capture_io { with_answers { generate(:admin_app, "--root=#{@project}") } }
        assert_equal edited, snapshot
        assert_equal 1, File.read("#{@project}/Gemfile").scan(/bcrypt/).size
        assert_equal 1, File.read("#{@project}/Gemfile").scan(/activesupport/).size
      end

      it 'should not stop a re-run for a model that gets authenticate elsewhere' do
        File.write("#{@project}/models/account.rb", "class Account\n  extend Credentials\nend\n")
        edited = snapshot
        capture_io do
          with_stdin('') do
            with_answers { generate(:admin_app, "--root=#{@project}") }
          rescue SystemExit => e
            flunk "the admin generator exited with status #{e.status}"
          end
        end
        assert_equal edited, snapshot
      end

      it 'should leave a removed destroy guard removed at the end of input' do
        edit('admin/controllers/accounts.rb') { |content| content.sub('account != current_account && ', '') }
        edited = snapshot
        capture_io { with_answers { generate(:admin_app, "--root=#{@project}") } }
        assert_equal edited, snapshot
      end
    end

    describe "with #{orm} and an account model that can't log in" do
      before do
        Object.send(:remove_const, :Account) if defined?(Account)
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", "-d=#{orm}", '-e=haml') }
        FileUtils.mkdir_p("#{@project}/models")
        File.write("#{@project}/models/account.rb", "class Account\nend\n")
      end

      it 'should stop before writing anything at the end of input' do
        before_run = snapshot
        _, err = capture_io do
          with_stdin('') { assert_equal 1, assert_raises(SystemExit) { generate(:admin_app, "--root=#{@project}") }.status }
        end
        assert_match(/no authenticate method/, err)
        assert_equal before_run, snapshot
      end

      it 'should replace the model when the prompt is answered with yes' do
        capture_io { with_stdin("y\n") { with_answers(*['y'] * 50) { generate(:admin_app, "--root=#{@project}") } } }
        assert_match_in_file(/def self\.authenticate/, "#{@project}/models/account.rb")
      end
    end

    describe "with #{orm} and an admin app that only partly exists" do
      before do
        Object.send(:remove_const, :Account) if defined?(Account)
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", "-d=#{orm}", '-e=haml') }
      end

      it 'should add the missing lines at the end of input and keep a partial app.rb' do
        FileUtils.mkdir_p("#{@project}/admin")
        File.write("#{@project}/admin/app.rb", "# partial\n")
        capture_io { with_answers { generate(:admin_app, "--root=#{@project}") } }
        assert_equal "# partial\n", File.read("#{@project}/admin/app.rb")
        assert_match_in_file(%r{Padrino\.mount\('SampleProject::Admin'.*\.to\('/admin'\)}, "#{@project}/config/apps.rb")
        assert_match_in_file(/gem 'bcrypt'/, "#{@project}/Gemfile")
      end

      it 'should stop for a plain model after g app admin at the end of input' do
        capture_io { generate(:app, 'admin', "-r=#{@project}") }
        FileUtils.mkdir_p("#{@project}/models")
        File.write("#{@project}/models/account.rb", "class Account\nend\n")
        before_run = snapshot
        capture_io do
          with_stdin('') { assert_equal 1, assert_raises(SystemExit) { generate(:admin_app, "--root=#{@project}") }.status }
        end
        assert_equal before_run, snapshot
      end

      it 'should add every line after g app admin and a yes' do
        capture_io { generate(:app, 'admin', "-r=#{@project}") }
        capture_io { with_answers(*['y'] * 50) { generate(:admin_app, "--root=#{@project}") } }
        assert_match_in_file(/gem 'bcrypt'/, "#{@project}/Gemfile")
        assert_match_in_file(/gem 'activesupport'/, "#{@project}/Gemfile")
        assert_equal 1, File.read("#{@project}/config/apps.rb").scan(/^Padrino\.mount\('SampleProject::Admin'/).size
        assert_match_in_file(%r{role\.project_module :accounts, '/accounts'}, "#{@project}/admin/app.rb")
      end
    end
  end

  describe 'the admin page generator' do
    before do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=sequel', '-e=haml') }
      capture_io { generate(:admin_app, "--root=#{@project}") }
      capture_io { with_answers { generate(:admin_page, 'section', "-r=#{@project}") } }
    end

    it 'should add the permission of a new page at the end of input' do
      assert_match_in_file(%r{role\.project_module :sections, '/sections'}, "#{@project}/admin/app.rb")
    end

    it 'should add the permission when the controller came from g controller' do
      capture_io { generate(:controller, 'widgets', '-a=admin', "-r=#{@project}") }
      Object.const_set(:Widget, Class.new(Sequel::Model(:sections)))
      capture_io { with_answers { generate(:admin_page, 'widget', "-r=#{@project}") } }
      assert_match_in_file(%r{role\.project_module :widgets, '/widgets'}, "#{@project}/admin/app.rb")
    ensure
      Object.send(:remove_const, :Widget) if defined?(Widget)
    end

    it 'should keep edited files when it runs again at the end of input' do
      edit('admin/controllers/sections.rb') { |content| content }
      edit('admin/views/sections/index.haml') { |content| content }
      edit('admin/app.rb') { |content| content.sub("'/sections'", "'/sections' # staff only") }
      edited = snapshot
      capture_io { with_answers { generate(:admin_page, 'section', "-r=#{@project}") } }
      assert_equal edited, snapshot
    end

    describe 'with a piped answer' do
      before do
        @controller = "#{@project}/admin/controllers/sections.rb"
        File.write(@controller, "# edited\n")
      end

      def rerun_answering(answer)
        capture_io { with_answers(answer) { generate(:admin_page, 'section', "-r=#{@project}") } }
      end

      it 'should overwrite the file when the answer is yes' do
        rerun_answering('y')
        assert_no_match_in_file(/# edited/, @controller)
      end

      it 'should keep the file when the answer is no' do
        rerun_answering('n')
        assert_equal "# edited\n", File.read(@controller)
      end

      it 'should keep the file when input runs out after asking for the diff' do
        Thor::Shell::Basic.any_instance.stubs(:show_diff)
        rerun_answering('d')
        assert_equal "# edited\n", File.read(@controller)
      end
    end
  end
end
