require File.expand_path(File.dirname(__FILE__) + '/../helper_isolated')

class TestAdmin < Test::Unit::TestCase

  def setup
    `rm -rf #{File.expand_path("../../tmp", __FILE__)}`
    `mkdir -p #{File.expand_path("../../tmp", __FILE__)}`
  end

  def teardown
    ENV['BUNDLE_GEMFILE'] = nil
    padrino(:stop, "--chdir=#{@apptmp}")
    `rm -rf #{File.expand_path("../../tmp", __FILE__)}`
  end

  %w(haml).each do |engine|
    %w(datamapper activerecord sequel).each do |orm|
      should "generate an admin with #{orm} and #{engine}" do
        @apptmp = File.expand_path("../../tmp/#{orm}-#{engine}", __FILE__)
        out = padrino_gen(:project, "#{orm}-#{engine}", "-d=#{orm}", "-e=#{engine}", "--root=#{File.expand_path("#{@apptmp}/../")}", "--dev")
        assert_match /Applying '#{orm}'/i, out
        assert_match /Applying '#{engine}'/i, out
        ENV['BUNDLE_GEMFILE'] = "#{@apptmp}/Gemfile"
        # This is more fast, but we need to check that every thing works fine with latest versions.
        # if bundle(:check) !~ /The Gemfile's dependencies are satisfied/i
        out = bundle(:install)
        assert_match /Your bundle is complete/, out
        out = padrino_gen(:admin, "--root=#{@apptmp}")
        assert_match /The admin panel has been mounted/, out
        replace_seed(@apptmp)
        out = padrino(:rake, migrate(orm), "seed", "--chdir=#{@apptmp}")
        assert_match /Rake/i, out
        out = padrino(:start, "-d", "--chdir=#{@apptmp}")
        assert_match /server has been daemonized with pid/, out
        sleep 10 # Take the time to boot
        header "Host", "localhost" # this is for follow redirects
        visit "http://localhost:3000/admin"
        fill_in :email,    :with => "info@padrino.com"
        fill_in :password, :with => "sample"
        click_button "Sign In"
        click_link "Accounts"
        # Editing
        click_button "Edit"
        fill_in "account[name]", :with => "Foo"
        fill_in "account[surname]", :with => "Bar"
        fill_in "account[email]", :with => "info@lipsiasoft.com"
        fill_in "account[password]", :with => "sample"
        fill_in "account[password_confirmation]", :with => "sample"
        click_button "Save"
        assert_have_selector ".notice", :content => "Account was successfully updated."
        assert_have_selector "#account_name", :value => "Foo"
        assert_have_selector "#account_surname", :value => "Bar"
        click_link "Accounts"
        assert_have_selector "td", :content => "Foo"
        assert_have_selector "td", :content => "Bar"
        # New account
        click_link "Accounts"
        click_link "New"
        click_button "Save"
        assert_have_selector ".error"
        fill_in "account[name]", :with => "Sam"
        fill_in "account[surname]", :with => "Max"
        fill_in "account[email]", :with => "info@sample.com"
        fill_in "account[password]", :with => "sample"
        fill_in "account[password_confirmation]", :with => "sample"
        click_button "Save"
        assert_have_selector ".notice", :content => "Account was successfully created."
        # Check Profile works
        click_link "Profile"
        assert_have_selector "#account_name", :value => "Foo"
        assert_have_selector "#account_surname", :value => "Bar"
        click_link "Accounts"
        # TODO: Check Destroy of account
        # TODO: Check: padrino g model Post title:string body:text; padrino g admin_page post
        # Logout
        click_button "Logout"
        assert_have_selector "h2", :content => "Login Box"
      end
    end
  end
end