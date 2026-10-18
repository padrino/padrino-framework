require_relative '../helper'
require_relative '../fixtures/sequel'
require 'nokogiri'

describe 'AdminPageGenerator' do
  before do
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{SecureRandom.hex}"
    `mkdir -p #{@apptmp}`
  end

  after do
    `rm -rf #{@apptmp}`
  end

  describe 'the admin page generator' do
    it 'should fail outside app root' do
      out, = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:admin_page, 'foo', "-r=#{@apptmp}/sample_project") }.status }
      assert_match(/not at the root/, out)
      assert_no_file_exists("#{@apptmp}/admin")
    end

    it 'should fail when the admin app does not exist' do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=sequel') }
      out, = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:admin_page, 'friend', "-r=#{@apptmp}/sample_project") }.status }
      assert_match(/Unable to locate 'Admin' application/, out)
      assert_no_dir_exists("#{@apptmp}/sample_project/admin")
    end

    %w[minirecord ohm].each do |removed_orm|
      it "should fail without writing anything when the project orm is no longer supported (#{removed_orm})" do
        capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=activerecord') }
        capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
        components = "#{@apptmp}/sample_project/.components"
        File.write(components, File.read(components).sub(':orm: activerecord', ":orm: #{removed_orm}"))
        out, = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:admin_page, 'friend', "-r=#{@apptmp}/sample_project") }.status }
        assert_match(/only supports activerecord or mongoid or sequel\. Sorry!/, out)
        assert_no_dir_exists("#{@apptmp}/sample_project/admin/views/friends")
      end
    end

    it 'should fail without an existent model' do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=activerecord') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      _, err = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:admin_page, 'foo', "-r=#{@apptmp}/sample_project") }.status }
      assert_match(/Model 'Foo' could not be found/, err)
      assert_no_dir_exists("#{@apptmp}/sample_project/admin/views/foos")
      assert_no_file_exists("#{@apptmp}/sample_project/admin/controllers/foos.rb")
      assert_no_match_in_file(/project_module :foos/, "#{@apptmp}/sample_project/admin/app.rb")
    end

    %w[erb haml slim].each do |renderer|
      it "should destroy pages whose models were already removed (#{renderer})" do
        Object.const_set(:GoneWidget, Class.new(Sequel::Model(:friends)))
        Object.const_set(:GoneGadget, Class.new(Sequel::Model(:pages)))
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=sequel', "-e=#{renderer}") }
        capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
        capture_io { generate(:admin_page, 'gone_widget', 'gone_gadget', "--root=#{@apptmp}/sample_project") }
        admin = "#{@apptmp}/sample_project/admin"
        assert_file_exists("#{admin}/views/gone_widgets/index.#{renderer}")
        assert_match_in_file("role.project_module :gone_gadgets, '/gone_gadgets'", "#{admin}/app.rb")

        Object.send(:remove_const, :GoneWidget)
        Object.send(:remove_const, :GoneGadget)
        status = nil
        _, err = capture_io do
          generate(:admin_page, 'gone_widget', 'gone_gadget', "--root=#{@apptmp}/sample_project", '-d')
        rescue SystemExit => e
          status = e.status
        end
        assert_nil status, err
        %w[gone_widgets gone_gadgets].each do |page|
          assert_no_file_exists("#{admin}/controllers/#{page}.rb")
          assert_no_dir_exists("#{admin}/views/#{page}")
          assert_no_match_in_file(/project_module :#{page}/, "#{admin}/app.rb")
        end
        assert_match_in_file("role.project_module :accounts, '/accounts'", "#{admin}/app.rb")
      ensure
        Object.send(:remove_const, :GoneWidget) if Object.const_defined?(:GoneWidget, false)
        Object.send(:remove_const, :GoneGadget) if Object.const_defined?(:GoneGadget, false)
      end
    end

    it 'should fail when the model does not match the project orm' do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=activerecord') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      _, err = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:admin_page, 'friend', "-r=#{@apptmp}/sample_project") }.status }
      assert_match(/Friend.*activerecord/m, err)
    end

    it 'should destroy a page even when the model does not match the project orm' do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=activerecord') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      FileUtils.mkdir_p("#{@apptmp}/sample_project/admin/views/friends")
      capture_io { generate(:admin_page, 'friend', "-r=#{@apptmp}/sample_project", '-d') }
      assert_no_dir_exists("#{@apptmp}/sample_project/admin/views/friends")
    end

    it 'should fail when the project has no orm and the model is not activerecord' do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=sequel') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      components = "#{@apptmp}/sample_project/.components"
      File.write(components, File.read(components).sub(/^:orm:.*\n/, ''))
      _, err = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:admin_page, 'friend', "-r=#{@apptmp}/sample_project") }.status }
      assert_match(/not based on/, err)
    end

    it 'should correctly generate a new page' do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=sequel', '-e=haml') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      capture_io { generate(:admin_page, 'friend', "--root=#{@apptmp}/sample_project") }
      assert_file_exists "#{@apptmp}/sample_project/admin/controllers/friends.rb"
      assert_match_in_file 'SampleProject::Admin.controllers :friends do', "#{@apptmp}/sample_project/admin/controllers/friends.rb"
      assert_match_in_file "role.project_module :friends, '/friends'", "#{@apptmp}/sample_project/admin/app.rb"
      assert_match_in_file 'elsif Padrino.env == :development && params[:bypass]', "#{@apptmp}/sample_project/admin/controllers/sessions.rb"
    end

    # users can override certain templates from a generators/templates folder in the destination_root
    it 'should use custom generator templates from the project root, if they exist' do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=sequel', '-e=haml') }
      custom_template_path = "#{@apptmp}/sample_project/generators/templates/haml/page/"
      `mkdir -p #{custom_template_path} && echo "%h1= 'Hello, custom generator' " > #{custom_template_path}index.haml.tt`
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      capture_io { generate(:admin_page, 'friend', "--root=#{@apptmp}/sample_project") }
      assert_match_in_file(/Hello, custom generator/, "#{@apptmp}/sample_project/admin/views/friends/index.haml")
    end

    describe 'renderers' do
      it 'should correctly generate a new page with haml' do
        capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=sequel', '-e=haml') }
        capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
        capture_io { generate(:admin_page, 'friend', "--root=#{@apptmp}/sample_project") }
        assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/_form.haml"
        assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/edit.haml"
        assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/index.haml"
        assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/new.haml"
        %w[name age email].each do |field|
          assert_match_in_file "label :#{field}", "#{@apptmp}/sample_project/admin/views/friends/_form.haml"
          assert_match_in_file "text_field :#{field}", "#{@apptmp}/sample_project/admin/views/friends/_form.haml"
        end
        assert_match_in_file 'check_box_tag :bypass', "#{@apptmp}/sample_project/admin/views/sessions/new.haml"
      end

      it 'should correctly generate a new page with erb' do
        capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=sequel', '-e=erb') }
        capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
        capture_io { generate(:admin_page, 'friend', "--root=#{@apptmp}/sample_project") }
        assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/_form.erb"
        assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/edit.erb"
        assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/index.erb"
        assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/new.erb"
        %w[name age email].each do |field|
          assert_match_in_file "label :#{field}", "#{@apptmp}/sample_project/admin/views/friends/_form.erb"
          assert_match_in_file "text_field :#{field}", "#{@apptmp}/sample_project/admin/views/friends/_form.erb"
        end
        assert_match_in_file 'check_box_tag :bypass', "#{@apptmp}/sample_project/admin/views/sessions/new.erb"
      end

      it 'should correctly generate a new page with slim' do
        capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=sequel', '-e=slim') }
        capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
        capture_io { generate(:admin_page, 'friend', "--root=#{@apptmp}/sample_project") }
        assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/_form.slim"
        assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/edit.slim"
        assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/index.slim"
        assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/new.slim"
        %w[name age email].each do |field|
          assert_match_in_file "label :#{field}", "#{@apptmp}/sample_project/admin/views/friends/_form.slim"
          assert_match_in_file "text_field :#{field}", "#{@apptmp}/sample_project/admin/views/friends/_form.slim"
        end
        assert_match_in_file 'check_box_tag :bypass', "#{@apptmp}/sample_project/admin/views/sessions/new.slim"
      end
    end

    %w[erb haml slim].each do |renderer|
      it "should render the list menu with the same classes as the stylesheet and script expect (#{renderer})" do
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=sequel', "-e=#{renderer}") }
        capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
        capture_io { generate(:admin_page, 'friend', "--root=#{@apptmp}/sample_project") }
        views = "#{@apptmp}/sample_project/admin/views"
        mock_app do
          set :views, views
          helpers Padrino::Admin::Helpers::ViewHelpers
          controllers :friends do
            get(:index) { @friends = []; render 'friends/index', layout: false }
            get(:new) {}
            delete(:destroy_many) {}
          end
        end
        get '/friends'
        assert_equal 200, last_response.status
        page = Nokogiri::HTML(last_response.body)
        classes = ->(node) { node['class'].split }
        assert_equal %w[list-menu-toggle dropdown-toggle], classes.call(page.at_css('[data-toggle=dropdown]'))
        assert_equal 'menu', page.at_css('ul.dropdown-menu')['role']
        assert_equal %w[list-menu-wrapper], classes.call(page.at_css('#select-all').parent)
        %w[#deselect-all #delete-selected].each do |link|
          assert_equal %w[list-menu-wrapper list-menu-wrapper-disabled], classes.call(page.at_css(link).parent)
        end
      end
    end

    it 'should correctly generate a new padrino admin application with multiple models at the same time' do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=sequel', '-e=haml') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      capture_io { generate(:admin_page, 'friend', 'page', "--root=#{@apptmp}/sample_project") }
      # For Friend
      assert_file_exists "#{@apptmp}/sample_project/admin/controllers/friends.rb"
      assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/_form.haml"
      assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/edit.haml"
      assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/index.haml"
      assert_file_exists "#{@apptmp}/sample_project/admin/views/friends/new.haml"
      %w[name age email].each do |field|
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
      %w[name body].each do |field|
        assert_match_in_file "label :#{field}", "#{@apptmp}/sample_project/admin/views/pages/_form.haml"
        assert_match_in_file "text_field :#{field}", "#{@apptmp}/sample_project/admin/views/pages/_form.haml"
      end
      assert_match_in_file "role.project_module :pages, '/pages'", "#{@apptmp}/sample_project/admin/app.rb"
    end
  end
end
