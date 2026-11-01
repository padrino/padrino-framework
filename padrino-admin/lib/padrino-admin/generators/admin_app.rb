module Padrino
  module Generators
    ##
    # Defines the generator for creating a new admin app.
    #
    class AdminApp < Thor::Group
      # Add this generator to our padrino-gen
      Padrino::Generators.add_generator(:admin, self)

      # Define the source template root
      def self.source_root; __dir__; end
      # Defines the "banner" text for the CLI.
      def self.banner; 'padrino-gen admin'; end

      # Include related modules.
      include Thor::Actions
      include Padrino::Generators::Actions
      include Padrino::Generators::Admin::Actions
      include Padrino::Generators::Admin::KeepFiles

      # Look for custom template files in a generators folder under the project root.
      def source_paths
        if File.exist? destination_root('generators', 'templates')
          [destination_root('generators').to_s, __dir__]
        else
          [__dir__]
        end
      end

      desc "Description:\n\n\tpadrino-gen admin generates a new Padrino Admin application"

      class_option :skip_migration, type: :boolean, aliases: '-s', default: false
      class_option :root,           type: :string,  aliases: '-r', default: '.',       desc: 'The root destination'
      class_option :destroy,        type: :boolean, aliases: '-d', default: false
      class_option :renderer,       type: :string,  aliases: '-e',                     desc: 'Rendering engine (erb, haml, slim)'
      class_option :admin_model,    type: :string,  aliases: '-m', default: 'Account', desc: 'The name of model for access controlling'
      class_option :admin_name,     type: :string,  aliases: '-a', default: 'admin',   desc: 'The admin application name and path'

      # Copies over the Padrino base admin application.
      def create_admin
        self.destination_root = options[:root]
        if in_app_root?
          unless supported_orm.include?(orm)
            say "<= At the moment, Padrino only supports #{supported_orm.join(' or ')}. Sorry!", :yellow
            exit 1
          end

          tmp_ext = options[:renderer] || fetch_component_choice(:renderer)
          unless supported_ext.include?(tmp_ext.to_sym)
            say "<= You are using '#{tmp_ext}' and for admin we only support '#{supported_ext.join(', ')}'. Please use #{supported_ext.map { |ext| "-e #{ext}" }.join(' or ')}", :yellow
            exit 1
          end

          # Get the app's namespace.
          @app_name = fetch_app_name

          # setup admin app name
          @admin_name = options[:admin_name].classify
          @admin_path = options[:admin_name].underscore

          # Setup Admin Model
          @model_name     = options[:admin_model].classify
          @model_singular = @model_name.underscore
          @model_plural   = @model_singular.pluralize
          model_path      = destination_root('models', "#{@model_singular}.rb")

          # A plain app (g app admin) or a missing one: an admin app has access control once generated.
          first_install = !line_in_file?(destination_root(@admin_path, 'app.rb'), /Padrino::Admin::AccessControl/)

          stop_for_model_without_login(model_path) if first_install && !options[:destroy]

          store_component_choice(:admin_renderer, tmp_ext)

          self.behavior = :revoke if options[:destroy]

          empty_directory destination_root(@admin_path)

          directory 'templates/app',       destination_root(@admin_path)
          directory 'templates/assets',    destination_root('public', @admin_path)
          template  'templates/app.rb.tt', destination_root("#{@admin_path}/app.rb")
          mounted = /^\s*Padrino\.mount\W+#{@app_name}::#{@admin_name}\b/
          if options[:destroy] || !line_in_file?(destination_root('config/apps.rb'), mounted)
            inject_into_file destination_root('config/apps.rb'), <<~RUBY.prepend("\n"), before: %r{^Padrino.mount.*\.to\('/'\)$}
              Padrino.mount('#{@app_name}::#{@admin_name}', app_file: Padrino.root('#{@admin_path}/app.rb')).to('/#{@admin_path}')
            RUBY
          end

          unless options[:destroy] || orm != :activerecord || line_in_file?(destination_root(@admin_path, 'app.rb'), /^\s*use[\s(]+ConnectionPoolManagement\b/)
            insert_middleware 'ConnectionPoolManagement', @admin_path
          end

          params = [
            @model_singular, 'name:string', 'surname:string', 'email:string', 'crypted_password:string', 'role:string',
            "-r=#{options[:root]}"
          ]
          params << '-s' if options[:skip_migration]
          params << '-d' if options[:destroy]

          # An existing model is reused: the model generator would refuse it and exit 1.
          model_exists = already_exists?(@model_name, fetch_component_choice(:namespace)) || File.exist?(model_path)
          Padrino::Generators::Model.start(params) if options[:destroy] || !model_exists
          column = Struct.new(:name, :type)
          columns = %i[id name surname email].map { |col| column.new(col) }
          column_fields = [
            { name: :name,                  field_type: :text_field },
            { name: :surname,               field_type: :text_field },
            { name: :email,                 field_type: :text_field },
            { name: :password,              field_type: :password_field },
            { name: :password_confirmation, field_type: :password_field },
            { name: :role,                  field_type: :text_field }
          ]

          controller = destination_root("#{@admin_path}/controllers/#{@model_plural}.rb")
          controller_before = File.binread(controller) if File.exist?(controller)

          unless options[:destroy]
            admin_app = Padrino::Generators::AdminPage.new([@model_singular], root: options[:root], destroy: options[:destroy], admin_model: @model_singular, admin_name: options[:admin_name])
            admin_app.default_orm = Padrino::Admin::Generators::Orm.new(@model_singular, orm, columns, column_fields)
            admin_app.invoke_all
          end

          # TODO: See this, there's something wrong it's not being applied properly or something because test_account_model_generator last test fails.
          template "templates/account/#{orm}.rb.tt", model_path, force: !model_exists

          # Seeds of the admin model stay in place; moving others aside never replaces an earlier move.
          seed_destination = destination_root('db', 'seeds.rb')
          seed_backup      = destination_root('db/seeds.old')
          if first_install && File.exist?(seed_destination) && !File.exist?(seed_backup) && !line_in_file?(seed_destination, /\b#{@model_name}\b/)
            run "mv #{seed_destination} #{seed_backup}"
          end
          template 'templates/account/seeds.rb.tt', seed_destination

          empty_directory destination_root("#{@admin_path}/controllers")
          empty_directory destination_root("#{@admin_path}/views")
          empty_directory destination_root("#{@admin_path}/views/base")
          empty_directory destination_root("#{@admin_path}/views/layouts")
          empty_directory destination_root("#{@admin_path}/views/sessions")
          empty_directory destination_root("#{@admin_path}/views/errors")

          template "templates/#{ext}/app/base/index.#{ext}.tt",          destination_root("#{@admin_path}/views/base/index.#{ext}")
          template "templates/#{ext}/app/layouts/application.#{ext}.tt", destination_root("#{@admin_path}/views/layouts/application.#{ext}")
          template "templates/#{ext}/app/layouts/error.#{ext}.tt",       destination_root("#{@admin_path}/views/layouts/error.#{ext}")
          template "templates/#{ext}/app/sessions/new.#{ext}.tt",        destination_root("#{@admin_path}/views/sessions/new.#{ext}")
          # Custom error.
          template "templates/#{ext}/app/errors/403.#{ext}.tt",          destination_root("#{@admin_path}/views/errors/403.#{ext}")
          template "templates/#{ext}/app/errors/404.#{ext}.tt",          destination_root("#{@admin_path}/views/errors/404.#{ext}")
          template "templates/#{ext}/app/errors/500.#{ext}.tt",          destination_root("#{@admin_path}/views/errors/500.#{ext}")

          gemfile = destination_root('Gemfile')
          unless options[:destroy]
            add_missing_project_module @model_plural
            require_dependencies('bcrypt') unless line_in_file?(gemfile, /^\s*gem[\s(]+['"]bcrypt['"]/)
          end

          require_dependencies 'activesupport', version: '>= 3.1' if options[:destroy] || !line_in_file?(gemfile, /^\s*gem[\s(]+['"]activesupport['"]/)

          # A nicer select box.
          # TODO FIXME This doesn't make much sense in here. Review.
          # gsub_file destination_root("admin/views/#{@model_plural}/_form.#{ext}"), "f.text_field :role, class: :text_field", "f.select :role, options: access_control.roles"

          # Destroy account only if not logged in.
          controller_after = File.binread(controller) if File.exist?(controller)
          gsub_file controller, "if #{@model_singular}.destroy", "if #{@model_singular} != current_account && #{@model_singular}.destroy" if controller_after != controller_before
          return if self.behavior == :revoke

          instructions = []
          instructions << "Run 'bundle'"
          if %i[activerecord sequel].include?(orm)
            instructions << "Run 'bundle exec rake db:create' if you have not created a database yet"
            instructions << "Run 'bundle exec rake db:migrate'"
          end
          instructions << "Run 'bundle exec rake db:seed'"
          instructions << "Visit the admin panel in the browser at '/#{@admin_path}'"
          instructions.map! { |i| "  #{instructions.index(i) + 1}) #{i}" }

          say
          say '=' * 65, :green
          say 'The admin panel has been mounted! Next, follow these steps:', :green
          say '=' * 65, :green
          say instructions.join("\n")
          say '=' * 65, :green
          say
        else
          exit_outside_app_root!
        end
      end
    end
  end
end
