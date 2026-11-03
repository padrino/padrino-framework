require_relative 'helper'

describe 'MailerGenerator' do
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{SecureRandom.hex}"
    `mkdir -p #{@apptmp}`
  end

  def teardown
    `rm -rf #{@apptmp}`
  end

  describe 'the mailer generator' do
    it 'should fail outside app root' do
      out, = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:mailer, 'demo', "-r=#{@apptmp}") }.status }
      assert_match(/not at the root/, out)
      assert_empty Dir.children(@apptmp)
    end

    it 'should fail with a message if given invalid namespace names' do
      capture_io { generate(:project, 'sample', "--root=#{@apptmp}") }
      _, err = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:mailer, 'wrong/name', "--root=#{@apptmp}/sample") }.status }
      assert_match(%r{Namespace 'wrong/name' must consist only of alphanumeric characters or '_'}, err)
    end

    ['', "gem 'padrino-mailer'\n", "gem 'padrino-helpers'\n"].each do |added|
      it "should stop without writing anything in an api project whose Gemfile adds #{added.empty? ? 'nothing' : added.chomp}" do
        capture_io { generate(:project, 'sample_project', '--api', "--root=#{@apptmp}") }
        File.write("#{@apptmp}/sample_project/Gemfile", added, mode: 'a')
        out, = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:mailer, 'demo', "-r=#{@apptmp}/sample_project") }.status }
        assert_match(/Add gem 'padrino-mailer' and gem 'padrino-helpers' to the Gemfile and `register Padrino::Mailer` to the app/, out)
        assert_no_file_exists("#{@apptmp}/sample_project/app/mailers/demo.rb")
        assert_no_dir_exists("#{@apptmp}/sample_project/app/views/mailers")
      end
    end

    it 'should generate a mailer in an api project whose Gemfile has padrino-mailer and padrino-helpers' do
      capture_io { generate(:project, 'sample_project', '--api', "--root=#{@apptmp}") }
      File.write("#{@apptmp}/sample_project/Gemfile", "gem 'padrino-mailer'\ngem 'padrino-helpers'\n", mode: 'a')
      capture_io { generate(:mailer, 'demo', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/SampleProject::App.mailer :demo/m, "#{@apptmp}/sample_project/app/mailers/demo.rb")
    end

    it 'should generate mailer in specified app' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:mailer, 'demo', '-a=/subby', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/SampleProject::Subby.mailer :demo/m, "#{@apptmp}/sample_project/subby/mailers/demo.rb")
      assert_dir_exists("#{@apptmp}/sample_project/subby/views/mailers/demo")
    end

    it 'should generate mailer in specified app with actions' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:app, 'subby', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:mailer, 'demo', 'action1', 'action2', '-a=/subby', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/SampleProject::Subby.mailer :demo/m, "#{@apptmp}/sample_project/subby/mailers/demo.rb")
      assert_match_in_file(/email :action1 do.*?end/m, "#{@apptmp}/sample_project/subby/mailers/demo.rb")
      assert_match_in_file(/email :action2 do.*?end/m, "#{@apptmp}/sample_project/subby/mailers/demo.rb")
      assert_dir_exists("#{@apptmp}/sample_project/subby/views/mailers/demo")
    end

    it 'should support generating a new mailer extended from base' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:mailer, 'demo', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/SampleProject::App.mailer :demo/m, "#{@apptmp}/sample_project/app/mailers/demo.rb")
      assert_dir_exists("#{@apptmp}/sample_project/app/views/mailers/demo")
    end

    it 'should support generating a new mailer extended from base with long name' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:mailer, 'UserNotice', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/SampleProject::App.mailer :user_notice/m, "#{@apptmp}/sample_project/app/mailers/user_notice.rb")
      assert_dir_exists("#{@apptmp}/sample_project/app/views/mailers/user_notice")
    end

    it 'should support generating a new mailer extended from base with capitalized name' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:mailer, 'DEMO', "-r=#{@apptmp}/sample_project") }
      assert_match_in_file(/SampleProject::App.mailer :demo/m, "#{@apptmp}/sample_project/app/mailers/demo.rb")
      assert_dir_exists("#{@apptmp}/sample_project/app/views/mailers/demo")
    end
  end

  describe 'the mailer destroy option' do
    it 'should destroy mailer file' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '--script=none', '-t=bacon') }
      capture_io { generate(:mailer, 'demo', "-r=#{@apptmp}/sample_project") }
      capture_io { generate(:mailer, 'demo', "-r=#{@apptmp}/sample_project", '-d') }
      assert_no_dir_exists("#{@apptmp}/sample_project/app/views/demo")
      assert_no_file_exists("#{@apptmp}/sample_project/app/mailers/demo.rb")
    end
  end
end
