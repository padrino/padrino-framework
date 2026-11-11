require_relative '../helper'
require_relative '../fixtures/sequel'
require 'json'
require 'nokogiri'
require 'open3'
require 'padrino-gen/generators/cli'

describe 'AdminPageGenerator' do
  before do
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{SecureRandom.hex}"
    `mkdir -p #{@apptmp}`
  end

  after do
    `rm -rf #{@apptmp}`
  end

  describe 'the admin page generator' do
    it 'should stop with a message in a project without an app' do
      capture_io { generate(:project, 'sample_project', '--lean', "--root=#{@apptmp}", '-d', 'sequel', '-e', 'erb') }
      out, = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:admin_page, 'foo', "-r=#{@apptmp}/sample_project") }.status }
      assert_match(/Unable to locate 'App' application/, out)
    end

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

    it 'should fail without an existent model whose name repeats a namespace' do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=sequel') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      Object.const_set(:RepeatedPageShop, Module.new)
      RepeatedPageShop.const_set(:Order, Module.new)
      _, err = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:admin_page, 'repeated_page_shop/order/order', "-r=#{@apptmp}/sample_project") }.status }
      assert_match(/Model 'RepeatedPageShop::Order::Order' could not be found/, err)
    ensure
      Object.send(:remove_const, :RepeatedPageShop) if Object.const_defined?(:RepeatedPageShop, false)
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

    it 'should report a model that fails to load with the project instead of a missing one' do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=sequel') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      File.write("#{@apptmp}/sample_project/models/broken_widget.rb", "class BrokenWidget < Sequel::Modle; end\n")
      File.write("#{@apptmp}/sample_project/config/boot.rb", "require_relative '../models/broken_widget'\n")
      capture_io { Padrino::Generators::Cli.new([], root: "#{@apptmp}/sample_project").load_boot }
      _, err = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:admin_page, 'broken_widget', "-r=#{@apptmp}/sample_project") }.status }
      assert_match(/Model 'BrokenWidget' could not be loaded because the project failed to load!\nNameError: uninitialized constant Sequel::Modle/, err)
      refute_match(/could not be found/, err)
      assert_no_dir_exists("#{@apptmp}/sample_project/admin/views/broken_widgets")
    ensure
      Padrino::Generators.boot_error = nil
    end

    it 'should report the error of a model that fails to load when looked up' do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=sequel') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      File.write("#{@apptmp}/broken_page_sample.rb", "module BrokenPageSample; class Gadget; MissingConcern; end; end\n")
      Object.autoload(:BrokenPageSample, "#{@apptmp}/broken_page_sample.rb")
      _, err = capture_io { assert_equal 1, assert_raises(SystemExit) { generate(:admin_page, 'broken_page_sample/gadget', "-r=#{@apptmp}/sample_project") }.status }
      assert_match(/Model 'BrokenPageSample::Gadget' could not be loaded!\nNameError: uninitialized constant BrokenPageSample::Gadget::MissingConcern/, err)
    ensure
      Object.send(:remove_const, :BrokenPageSample) if Object.const_defined?(:BrokenPageSample, false)
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
      assert_no_match_in_file(/bypass/, "#{@apptmp}/sample_project/admin/controllers/sessions.rb")
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
        assert_no_match_in_file(/bypass/, "#{@apptmp}/sample_project/admin/views/sessions/new.haml")
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
        assert_no_match_in_file(/bypass/, "#{@apptmp}/sample_project/admin/views/sessions/new.erb")
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
        assert_no_match_in_file(/bypass/, "#{@apptmp}/sample_project/admin/views/sessions/new.slim")
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

      # Mongoid reports a boolean field's type as the class Mongoid::Boolean, not as :boolean.
      [nil, 'Mongoid::Boolean'].each do |type_name|
        it "should show boolean columns in the list as icons the stylesheet draws (#{renderer}#{", #{type_name}" if type_name})" do
          Sequel::Model.db.create_table!(:switches) do
            primary_key :id
            String :name
            TrueClass :enabled
          end
          # JRuby's jdbc-sqlite stores booleans as integers and loads 0 as 0, which is truthy.
          Object.const_set(:Switch, Class.new(Sequel::Model(:switches)) { plugin :typecast_on_load, :enabled })
          Switch.create(name: 'on', enabled: true)
          Switch.create(name: 'off', enabled: false)
          Switch.create(name: 'unset', enabled: nil)
          capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=sequel', "-e=#{renderer}") }
          capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
          if type_name
            boolean = Class.new
            boolean.define_singleton_method(:to_s) { type_name }
            columns = Switch.db_schema.map { |name, info| Padrino::Admin::Generators::Orm::Column.new(name, name == :enabled ? boolean : info[:type]) }
            Padrino::Admin::Generators::Orm.any_instance.stubs(:columns).returns(columns)
          end
          capture_io { generate(:admin_page, 'switch', "--root=#{@apptmp}/sample_project") }
          views = "#{@apptmp}/sample_project/admin/views"
          mock_app do
            set :views, views
            helpers Padrino::Admin::Helpers::ViewHelpers
            controllers :switches do
              get(:index) do
                @switches = Switch.order(:id).all
                render 'switches/index', layout: false
              end
              get(:new) {}
              get(:edit, with: :id) {}
              delete(:destroy, with: :id) {}
              delete(:destroy_many) {}
            end
          end
          get '/switches'
          assert_equal 200, last_response.status
          page = Nokogiri::HTML(last_response.body)
          column = page.css('#list thead th').map { |th| th.text.strip }.index('Enabled')
          on, off, unset = page.css('#list tbody tr').map { |row| row.css('td')[column] }
          icons = ->(cell) { cell.css('i.fa').flat_map { |icon| icon['class'].split - ['fa'] } }
          refute_empty icons.call(on)
          refute_empty icons.call(off)
          refute_equal icons.call(on), icons.call(off)
          assert_equal 'true', on.at_css('.sr-only')&.text
          assert_equal 'false', off.at_css('.sr-only')&.text
          assert_empty unset.children.to_s.strip
          stylesheet = File.read("#{@apptmp}/sample_project/public/admin/stylesheets/application.css")
          undrawn = (icons.call(on) + icons.call(off)).reject { |icon| stylesheet.include?(".#{icon}:before") }
          assert_empty undrawn, 'the stylesheet draws no glyph for these icons'
        ensure
          Object.send(:remove_const, :Switch) if Object.const_defined?(:Switch, false)
          Sequel::Model.db.drop_table?(:switches)
        end
      end

      it "should generate a form with an input for each column type, no placeholder help, and Save back to the list (#{renderer})" do
        skip 'the sqlite3 gem is only bundled on MRI' if RUBY_ENGINE == 'jruby'
        # Without the fixture's Account, the admin generator adds the account model and its migration.
        account = Object.send(:remove_const, :Account) if Object.const_defined?(:Account, false)
        capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=sequel', "-e=#{renderer}") }
        capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
        project = "#{@apptmp}/sample_project"
        File.write("#{project}/db/migrate/002_create_gadgets.rb", <<~'RUBY')
          Sequel.migration do
            up do
              create_table :gadgets do
                primary_key :id
                String :name
                Text :notes
                Integer :quantity
                Decimal :price
                Float :weight
                Date :released_on
                DateTime :published_at
                Time :opens_at, only_time: true
                TrueClass :active
              end
            end
          end
        RUBY
        File.write("#{project}/models/gadget.rb", "class Gadget < Sequel::Model; end\n")
        db = Sequel.sqlite("#{project}/db/sample_project_test.db")
        Sequel.extension :migration
        Sequel::Migrator.run(db, "#{project}/db/migrate")
        Object.const_set(:Gadget, Class.new(Sequel::Model(db[:gadgets])))
        capture_io { generate(:admin_page, 'gadget', "--root=#{project}") }
        script = <<~'RUBY'
          ENV['RACK_ENV'] = 'test'
          %w[json sequel haml slim erubi nokogiri rack/test].each { |lib| require lib }
          require File.expand_path('config/boot')
          account_id = Account.dataset.insert(email: 'admin@example.com', role: 'admin', crypted_password: 'unused')
          browser = Rack::Test::Session.new(Padrino.application)
          browser.env('rack.session', SampleProject::Admin.session_id => account_id)
          page = lambda do |path|
            browser.get(path)
            raise "#{path} answered #{browser.last_response.status}" unless browser.last_response.status == 200
            Nokogiri::HTML(browser.last_response.body)
          end
          inputs = lambda do |html|
            html.css('form .controls input:not([type=hidden]), form .controls textarea').to_h do |input|
              [input['name'][/\[(.*)\]/, 1], [input.name == 'textarea' ? 'textarea' : input['type'], input['step'], input['value']]]
            end
          end
          location = ->(response) { URI(response['Location']).path }
          attributes = { name: 'Widget', quantity: '7', price: '9.99', weight: '1.25', released_on: '2026-11-11',
                         published_at: '2026-11-11T10:30', opens_at: '09:15', active: '1' }
          new_page = page.call('/admin/gadgets/new')
          results = { 'new' => inputs.call(new_page), 'help' => new_page.css('.help-inline').map { |help| help.text.strip } }
          browser.post('/admin/gadgets/create', gadget: attributes)
          results['create'] = location.call(browser.last_response)
          browser.post('/admin/gadgets/create', gadget: attributes, save_and_continue: 'Save and continue')
          results['create and continue'] = location.call(browser.last_response)
          browser.put('/admin/gadgets/update/1', gadget: { quantity: '8' })
          results['update'] = location.call(browser.last_response)
          browser.put('/admin/gadgets/update/1', gadget: { quantity: '9' }, save_and_continue: 'Save and continue')
          results['update and continue'] = location.call(browser.last_response)
          results['edit'] = inputs.call(page.call('/admin/gadgets/edit/1'))
          puts "RESULTS #{JSON.generate(results)}"
        RUBY
        env = { 'BUNDLE_GEMFILE' => File.expand_path('../../../Gemfile', __dir__) }
        out, err, status = Open3.capture3(env, RbConfig.ruby, '-rbundler/setup', '-e', script, chdir: project)
        results = out[/^RESULTS (.*)$/, 1]
        assert results, "#{status}\n#{out}\n#{err}"
        results = JSON.parse(results)
        types = results['new'].transform_values { |(type, step)| [type, step] }
        assert_equal({ 'name' => ['text', nil], 'notes' => ['textarea', nil], 'quantity' => ['number', nil],
                       'price' => %w[number any], 'weight' => %w[number any], 'released_on' => ['date', nil],
                       'published_at' => ['datetime-local', nil], 'opens_at' => ['time', nil], 'active' => ['checkbox', nil] }, types)
        assert_equal [''] * 9, results['help']
        assert_equal '/admin/gadgets', results['create']
        assert_equal '/admin/gadgets/edit/2', results['create and continue']
        assert_equal '/admin/gadgets', results['update']
        assert_equal '/admin/gadgets/edit/1', results['update and continue']
        values = results['edit'].transform_values(&:last)
        assert_equal '9', values['quantity']
        assert_equal 9.99, Float(values['price'])
        assert_equal '2026-11-11', values['released_on']
        assert_equal '2026-11-11T10:30:00', values['published_at']
        assert_equal '09:15:00.000', values['opens_at']
      ensure
        Object.send(:remove_const, :Gadget) if Object.const_defined?(:Gadget, false)
        Object.send(:remove_const, :Account) if Object.const_defined?(:Account, false)
        Object.const_set(:Account, account) if account
        db&.disconnect
      end
    end

    describe 'the form field of a column' do
      def form_fields(orm, types)
        columns = types.each_with_index.map { |type, index| Padrino::Admin::Generators::Orm::Column.new(:"column#{index}", type) }
        Padrino::Admin::Generators::Orm.new('friend', orm, columns).column_fields.map { |column| [column[:field_type], column[:step]].compact }
      end

      def named_class(name)
        Class.new.tap { |klass| klass.define_singleton_method(:to_s) { name } }
      end

      it 'should match the Active Record column type' do
        types = %i[string text integer float decimal date datetime timestamptz time boolean binary]
        expected = [[:text_field], [:text_area], [:number_field], [:number_field, 'any'], [:number_field, 'any'], [:date_field],
                    [:datetime_local_field], [:datetime_local_field], [:time_field], [:check_box], [:text_field]]
        assert_equal expected, form_fields(:activerecord, types)
      end

      it 'should match the Mongoid field type, keeping a text field for times, which carry an offset' do
        types = [String, Integer, Float, BigDecimal, Date, DateTime, Time, named_class('ActiveSupport::TimeWithZone'),
                 named_class('Mongoid::Boolean'), Object]
        expected = [[:text_field], [:number_field], [:number_field, 'any'], [:number_field, 'any'], [:date_field],
                    [:text_field], [:text_field], [:text_field], [:check_box], [:text_field]]
        assert_equal expected, form_fields(:mongoid, types)
      end

      it 'should match the Sequel column type when the model is not loaded' do
        columns = %i[integer string].map { |type| Padrino::Admin::Generators::Orm::Column.new(type, type) }
        fields = Padrino::Admin::Generators::Orm.new('not_loaded_model', :sequel, columns).column_fields.map { |column| column[:field_type] }
        assert_equal %i[number_field text_field], fields
      end

      it 'should keep a text field for a Sequel enum column, whose reader returns a name' do
        Object.const_set(:EnumGadget, Class.new(Sequel::Model(:friends)) do
          plugin :enum
          enum :age, { young: 1, old: 2 }
          enum :name, { short: 1 }, override_accessors: false
        end)
        Object.const_set(:EnumGadgetPart, Class.new(EnumGadget))
        columns = %i[age name email].map { |name| Padrino::Admin::Generators::Orm::Column.new(name, :integer) }
        %w[enum_gadget enum_gadget_part].each do |model|
          fields = Padrino::Admin::Generators::Orm.new(model, :sequel, columns).column_fields.map { |column| column[:field_type] }
          assert_equal %i[text_field number_field number_field], fields, model
        end
      ensure
        Object.send(:remove_const, :EnumGadgetPart) if Object.const_defined?(:EnumGadgetPart, false)
        Object.send(:remove_const, :EnumGadget) if Object.const_defined?(:EnumGadget, false)
      end
    end

    it 'should not carry a flash over to the next page when a record is not found' do
      saved = Object.send(:remove_const, :SampleProject) if Object.const_defined?(:SampleProject, false)
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=sequel', '-e=erb') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      capture_io { generate(:admin_page, 'friend', "--root=#{@apptmp}/sample_project") }
      mock_app do
        enable :sessions
        helpers Padrino::Admin::Helpers::ViewHelpers
        get(:flash) { flash.keys.join(',') }
      end
      Object.const_set(:SampleProject, Module.new).const_set(:Admin, @app)
      load "#{@apptmp}/sample_project/admin/controllers/friends.rb"
      get '/friends/edit/999'
      assert_equal 404, last_response.status
      put '/friends/update/999'
      assert_equal 404, last_response.status
      delete '/friends/destroy/999'
      assert_equal 404, last_response.status
      get '/flash'
      assert_equal '', last_response.body
    ensure
      Object.send(:remove_const, :SampleProject) if Object.const_defined?(:SampleProject, false)
      Object.const_set(:SampleProject, saved) if saved
    end

    it 'should keep a text field for an Active Record enum, whose value survives an edit and save' do
      skip 'activerecord and sqlite3 are only bundled on MRI' if RUBY_ENGINE == 'jruby'
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=activerecord', '-e=erb') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      # Active Record is loaded in a separate process so that it stays out of the other tests.
      script = <<~'RUBY'
        require 'json'
        require 'nokogiri'
        require 'active_record'
        require 'thor/group'
        require 'padrino-admin'
        Padrino::Generators.load_components!
        ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
        ActiveRecord::Schema.verbose = false
        ActiveRecord::Schema.define do
          create_table(:posts) { |t| t.string :title; t.integer :status; t.integer :views }
        end
        class Post < ActiveRecord::Base
          enum :status, { draft: 0, published: 1 }
        end
        Padrino::Generators::AdminPage.start(%w[post -r=.])
        module SampleProject
          Admin = Sinatra.new(Padrino::Application) do
            register Padrino::Helpers
            enable :sessions
            helpers Padrino::Admin::Helpers::ViewHelpers
            set :views, File.expand_path('admin/views')
          end
        end
        # The admin layout needs the whole admin app (accounts, sessions, project modules).
        File.write('admin/views/layouts/application.erb', '<%= yield %>')
        load 'admin/controllers/posts.rb'
        browser = Rack::MockRequest.new(SampleProject::Admin)
        id = Post.create!(title: 'kept', status: :published, views: 3).id
        form = Nokogiri::HTML(browser.get("/posts/edit/#{id}").body)
        fields = form.css('form input[name^="post["]').to_h { |input| [input['name'][/\[(.*)\]/, 1], [input['type'], input['value']]] }
        # Submit the form unchanged, as a browser would.
        response = browser.request('PUT', "/posts/update/#{id}", params: { 'post' => fields.transform_values(&:last) }, lint: true)
        post = Post.find(id)
        puts "RESULTS #{JSON.generate(fields: fields, status: response.status, saved: [post.title, post.status, post.views])}"
      RUBY
      env = { 'RACK_ENV' => 'test', 'BUNDLE_GEMFILE' => ENV['BUNDLE_GEMFILE'] || File.expand_path('../../../Gemfile', __dir__) }
      out, err, status = Open3.capture3(env, RbConfig.ruby, '-rbundler/setup', '-e', script, chdir: "#{@apptmp}/sample_project")
      results = out[/^RESULTS (.*)$/, 1]
      assert results, "#{status}\n#{out}\n#{err}"
      results = JSON.parse(results)
      assert_equal({ 'title' => %w[text kept], 'status' => %w[text published], 'views' => %w[number 3] }, results['fields'])
      assert_equal 303, results['status']
      assert_equal ['kept', 'published', 3], results['saved']
    end

    it 'should answer a missing record with 404 and still find existing ones with activerecord' do
      skip 'activerecord and sqlite3 are only bundled on MRI' if RUBY_ENGINE == 'jruby'
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=activerecord', '-e=erb') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      # Active Record is loaded in a separate process so that it stays out of the other tests.
      # Entry has a primary key other than id.
      script = <<~'RUBY'
        require 'json'
        require 'active_record'
        require 'thor/group'
        require 'padrino-admin'
        require 'padrino-gen'
        Padrino::Generators.load_components!
        ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
        ActiveRecord::Schema.verbose = false
        ActiveRecord::Schema.define do
          create_table(:posts) { |t| t.string :title }
          create_table(:entries, id: false) { |t| t.primary_key :code; t.string :title }
        end
        class Post < ActiveRecord::Base; end
        class Entry < ActiveRecord::Base
          self.primary_key = 'code'
        end
        Padrino::Generators::AdminPage.start(%w[post entry -r=.])
        module SampleProject
          Admin = Sinatra.new(Padrino::Application) do
            register Padrino::Helpers
            enable :sessions
            helpers Padrino::Admin::Helpers::ViewHelpers
            set :views, File.expand_path('admin/views')
          end
        end
        # The admin layout needs the whole admin app (accounts, sessions, project modules).
        File.write('admin/views/layouts/application.erb', '<%= yield %>')
        load 'admin/controllers/posts.rb'
        load 'admin/controllers/entries.rb'
        browser = Rack::MockRequest.new(SampleProject::Admin)
        status = lambda do |verb, path, params = {}|
          browser.request(verb, path, params: params, lint: true).status
        rescue StandardError => e
          "#{e.class.name}: #{e.message}"
        end
        results = {}
        { 'posts' => [Post, 'post'], 'entries' => [Entry, 'entry'] }.each do |plural, (model, param)|
          id = model.create!(title: 'kept').id
          results[plural] = [
            status.call('GET', "/#{plural}/edit/#{id}"),
            status.call('PUT', "/#{plural}/update/#{id}", param => { title: 'changed' }),
            model.find(id).title,
            status.call('GET', "/#{plural}/edit/999"),
            status.call('PUT', "/#{plural}/update/999"),
            status.call('DELETE', "/#{plural}/destroy/999"),
            status.call('DELETE', "/#{plural}/destroy/#{id}"),
            model.exists?(id)
          ]
        end
        puts "RESULTS #{JSON.generate(results)}"
      RUBY
      env = { 'RACK_ENV' => 'test', 'BUNDLE_GEMFILE' => ENV['BUNDLE_GEMFILE'] || File.expand_path('../../../Gemfile', __dir__) }
      out, err, status = Open3.capture3(env, RbConfig.ruby, '-rbundler/setup', '-e', script, chdir: "#{@apptmp}/sample_project")
      results = out[/^RESULTS (.*)$/, 1]
      assert results, "#{status}\n#{out}\n#{err}"
      expected = [200, 303, 'changed', 404, 404, 404, 303, false]
      assert_equal({ 'posts' => expected, 'entries' => expected }, JSON.parse(results))
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
