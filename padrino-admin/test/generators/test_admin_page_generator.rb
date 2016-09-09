require File.expand_path(File.dirname(__FILE__) + '/../helper')
require File.join(File.dirname(__FILE__), '../fixtures/sequel')

describe "AdminPageGenerator" do
  before do 
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{SecureRandom.hex}"
    `mkdir -p #{@apptmp}`
  end

  after do
    `rm -rf #{@apptmp}`
  end

  describe 'the admin page generator' do
    it 'should fail outside app root' do
      out, err = capture_io { generate(:admin_page, 'foo', "-r=#{@apptmp}/sample_project") }
      assert_match(/not at the root/, out)
      assert_no_file_exists("#{@apptmp}/admin")
    end

    it 'should fail without an existent model' do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=activerecord') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      assert_raises(Padrino::Admin::Generators::OrmError) { generate(:admin_page, 'foo', "-r=#{@apptmp}/sample_project") }
    end

    it 'should correctly generate a new page' do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=sequel','-e=haml') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      capture_io { generate(:model, 'friend', "name:string", "age:integer", "email:string", "--root=#{@apptmp}/sample_project") }
      capture_io { generate(:admin_page, 'friend', "--root=#{@apptmp}/sample_project") }
      assert_file_exists "#{@apptmp}/sample_project/admin/controllers/friends.rb"
      assert_match_in_file "SampleProject::Admin.controllers :friends do", "#{@apptmp}/sample_project/admin/controllers/friends.rb"
      assert_match_in_file "role.project_module :friends, '/friends'", "#{@apptmp}/sample_project/admin/app.rb"
      assert_match_in_file "elsif Padrino.env == :development && params[:bypass]", "#{@apptmp}/sample_project/admin/controllers/sessions.rb"
    end

    # users can override certain templates from a generators/templates folder in the destination_root
    it "should use custom generator templates from the project root, if they exist" do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=sequel','-e=haml') }
      custom_template_path = "#{@apptmp}/sample_project/generators/templates/haml/page/"
      `mkdir -p #{custom_template_path} && echo "%h1= 'Hello, custom generator' " > #{custom_template_path}index.haml.tt`
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      capture_io { generate(:model, 'friend', "name:string", "age:integer", "email:string", "--root=#{@apptmp}/sample_project") }
      capture_io { generate(:admin_page, 'friend', "--root=#{@apptmp}/sample_project") }
      assert_match_in_file(/Hello, custom generator/, "#{@apptmp}/sample_project/admin/views/friends/index.haml")
    end

    describe "renderers" do
      it 'should correctly generate a new page with haml' do
        capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=sequel','-e=haml') }
        capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
        capture_io { generate(:model, 'friend', "name:string", "age:integer", "email:string", "--root=#{@apptmp}/sample_project") }
        capture_io { generate(:admin_page, 'friend', "--root=#{@apptmp}/sample_project") }
        assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/_form.haml"
        assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/edit.haml"
        assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/index.haml"
        assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/new.haml"
        %w(name age email).each do |field|
          assert_match_in_file "label :#{field}", "#{@apptmp}/sample_project/admin/views/friends/_form.haml"
          assert_match_in_file "text_field :#{field}", "#{@apptmp}/sample_project/admin/views/friends/_form.haml"
        end
        assert_match_in_file "check_box_tag :bypass", "#{@apptmp}/sample_project/admin/views/sessions/new.haml"
      end

      it 'should correctly generate a new page with erb' do
        capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=sequel','-e=erb') }
        capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
        capture_io { generate(:model, 'friend', "name:string", "age:integer", "email:string", "--root=#{@apptmp}/sample_project") }
        capture_io { generate(:admin_page, 'friend', "--root=#{@apptmp}/sample_project") }
        assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/_form.erb"
        assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/edit.erb"
        assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/index.erb"
        assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/new.erb"
        %w(name age email).each do |field|
          assert_match_in_file "label :#{field}", "#{@apptmp}/sample_project/admin/views/friends/_form.erb"
          assert_match_in_file "text_field :#{field}", "#{@apptmp}/sample_project/admin/views/friends/_form.erb"
        end
        assert_match_in_file "check_box_tag :bypass", "#{@apptmp}/sample_project/admin/views/sessions/new.erb"
      end

      it 'should correctly generate a new page with slim' do
        capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=sequel','-e=slim') }
        capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
        capture_io { generate(:model, 'friend', "name:string", "age:integer", "email:string", "--root=#{@apptmp}/sample_project") }
        capture_io { generate(:admin_page, 'friend', "--root=#{@apptmp}/sample_project") }
        assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/_form.slim"
        assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/edit.slim"
        assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/index.slim"
        assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/new.slim"
        %w(name age email).each do |field|
          assert_match_in_file "label :#{field}", "#{@apptmp}/sample_project/admin/views/friends/_form.slim"
          assert_match_in_file "text_field :#{field}", "#{@apptmp}/sample_project/admin/views/friends/_form.slim"
        end
        assert_match_in_file "check_box_tag :bypass", "#{@apptmp}/sample_project/admin/views/sessions/new.slim"
      end
    end

    it 'should correctly generate a new padrino admin application with multiple models at the same time' do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=sequel','-e=haml') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      capture_io { generate(:model, 'friend', "name:string", "age:integer", "email:string", "-root=#{@apptmp}/sample_project") }
      capture_io { generate(:model, 'page', "name:string", "body:string", "-root=#{@apptmp}/sample_project") }
      capture_io { generate(:admin_page, 'friend', 'page', "--root=#{@apptmp}/sample_project") }
      # For Friend
      assert_file_exists "#{@apptmp}/sample_project/admin/controllers/friends.rb"
      assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/_form.haml"
      assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/edit.haml"
      assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/index.haml"
      assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/new.haml"
      %w(name age email).each do |field|
        assert_match_in_file "label :#{field}", "#{@apptmp}/sample_project/admin/views/friends/_form.haml"
        assert_match_in_file "text_field :#{field}", "#{@apptmp}/sample_project/admin/views/friends/_form.haml"
      end
      assert_match_in_file "role.project_module :friends, '/friends'", "#{@apptmp}/sample_project/admin/app.rb"
      # For Page
      assert_file_exists "#{@apptmp}/sample_project/admin/controllers/pages.rb"
      assert_file_exists "#{@apptmp}/sample_project/admin/views/pages/_form.haml"
      assert_file_exists "#{@apptmp}/sample_project/admin/views/pages/edit.haml"
      assert_file_exists "#{@apptmp}/sample_project/admin/views/pages/index.haml"
      assert_file_exists "#{@apptmp}/sample_project/admin/views/pages/new.haml"
      %w(name body).each do |field|
        assert_match_in_file "label :#{field}", "#{@apptmp}/sample_project/admin/views/pages/_form.haml"
        assert_match_in_file "text_field :#{field}", "#{@apptmp}/sample_project/admin/views/pages/_form.haml"
      end
      assert_match_in_file "role.project_module :pages, '/pages'", "#{@apptmp}/sample_project/admin/app.rb"
    end
  end
end
