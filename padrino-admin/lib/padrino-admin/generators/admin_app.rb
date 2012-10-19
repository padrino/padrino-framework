module Padrino
  module Generators
    ##
    # Defines the generator for creating a new admin app.
    #
    class AdminApp < Thor::Group

      # Add this generator to our padrino-gen
      Padrino::Generators.add_generator(:admin, self)

      # Define the source template root
      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      # Defines the "banner" text for the CLI.
      def self.banner; "padrino-gen admin"; end
      # Defines the theme names for admin based on available.
      # def self.themes; Dir[File.dirname(__FILE__) + "/templates/assets/stylesheets/themes/*"].map { |t| File.basename(t) }.sort; end

      # Include related modules
      include Thor::Actions
      include Padrino::Generators::Actions
      include Padrino::Generators::Admin::Actions

      desc "Description:\n\n\tpadrino-gen admin generates a new Padrino Admin application"

      class_option :skip_migration, :aliases => "-s", :default => false, :type => :boolean
      class_option :app, :aliases => "-a", :desc => "The model destination path", :default => '.', :type => :string
      class_option :root, :desc => "The root destination", :aliases => '-r', :default => ".", :type => :string
      class_option :destroy, :aliases => '-d', :default => false, :type => :boolean
      # class_option :theme, :desc => "Your admin theme: (#{self.themes.join(", ")})", :default => "default", :type => :string
      class_option :renderer, :aliases => '-e', :desc => "Rendering engine (erb, haml)", :type => :string
      class_option :admin_model, :aliases => '-m', :desc => "The name of model for access controlling", :default => 'Account', :type => :string

      # Copies over the Padrino base admin application
      def create_admin
        self.destination_root = options[:root]
        if in_app_root?
          unless supported_orm.include?(orm)
            say "<= At the moment, Padrino only supports #{supported_orm.join(" or ")}. Sorry!", :yellow
            raise SystemExit
          end

          tmp_ext = options[:renderer] || fetch_component_choice(:renderer)
          unless supported_ext.include?(tmp_ext.to_sym)
            say "<= Your are using '#{tmp_ext}' and for admin we only support '#{supported_ext.join(', ')}'. Please use -e haml or -e erb or -e slim", :yellow
            raise SystemExit
          end

          store_component_choice(:admin_renderer, tmp_ext)

          self.behavior = :revoke if options[:destroy]

          empty_directory destination_root("admin")

          # Setup Admin Model
          @model_name     = options[:admin_model].classify
          @model_singular = @model_name.underscore
          @model_plural   = @model_singular.pluralize

          directory "templates/app",       destination_root("admin")
          directory "templates/assets",    destination_root("public", "admin")
          template  "templates/app.rb.tt", destination_root("admin/app.rb")
          append_file destination_root("config/apps.rb"),  "\nPadrino.mount(\"Admin\").to(\"/admin\")"
          insert_middleware 'ActiveRecord::ConnectionAdapters::ConnectionManagement', 'admin' if [:mini_record, :activerecord].include?(orm)

          params = [
            @model_singular, "name:string", "surname:string", "email:string", "crypted_password:string", "role:string",
            "-a=#{options[:app]}",
            "-r=#{options[:root]}"
          ]
          params << "-s" if options[:skip_migration]
          params << "-d" if options[:destroy]

          Padrino::Generators::Model.start(params)
          column = Struct.new(:name, :type)
          columns = [:id, :name, :surname, :email].map { |col| column.new(col) }
          column_fields = [
            { :name => :name,                  :field_type => :text_field },
            { :name => :surname,               :field_type => :text_field },
            { :name => :email,                 :field_type => :text_field },
            { :name => :password,              :field_type => :password_field },
            { :name => :password_confirmation, :field_type => :password_field },
            { :name => :role,                  :field_type => :text_field }
          ]

          admin_app = Padrino::Generators::AdminPage.new([@model_singular], :root => options[:root], :destroy => options[:destroy])
          admin_app.default_orm = Padrino::Admin::Generators::Orm.new(@model_singular, orm, columns, column_fields)
          admin_app.invoke_all

          template "templates/account/#{orm}.rb.tt", destination_root(options[:app], "models", "#{@model_singular}.rb"), :force => true

          if File.exist?(destination_root("db/seeds.rb"))
            run "mv #{destination_root('db/seeds.rb')} #{destination_root('db/seeds.old')}"
          end
          template "templates/account/seeds.rb.tt", destination_root("db/seeds.rb")

          empty_directory destination_root("admin/controllers")
          empty_directory destination_root("admin/views")
          empty_directory destination_root("admin/views/base")
          empty_directory destination_root("admin/views/layouts")
          empty_directory destination_root("admin/views/sessions")

          template "templates/#{ext}/app/base/index.#{ext}.tt",          destination_root("admin/views/base/index.#{ext}")
          template "templates/#{ext}/app/layouts/application.#{ext}.tt", destination_root("admin/views/layouts/application.#{ext}")
          template "templates/#{ext}/app/sessions/new.#{ext}.tt",        destination_root("admin/views/sessions/new.#{ext}")

          add_project_module @model_plural
          require_dependencies('bcrypt-ruby', :require => 'bcrypt')

          # A nicer select box
          gsub_file destination_root("admin/views/#{@model_plural}/_form.#{ext}"), "f.text_field :role, :class => :text_field", "f.select :role, :options => access_control.roles"

          # Destroy account only if not logged in
          gsub_file destination_root("admin/controllers/#{@model_plural}.rb"), "if #{@model_singular}.destroy", "if #{@model_singular} != current_account && #{@model_singular}.destroy"
          return if self.behavior == :revoke

          instructions = []
          instructions << "Run 'bundle install'"
          instructions << "Run 'padrino rake ar:migrate'" if orm == :activerecord
          instructions << "Run 'padrino rake dm:auto:upgrade'" if orm == :datamapper
          instructions << "Run 'ohm mani padme hum'" if orm == :ohm
          instructions << "Run 'padrino rake seed'"
          instructions << "Visit the admin panel in the browser at '/admin'"
          instructions.map! { |i| "  #{instructions.index(i)+1}) #{i}" }

          say
          say "="*65, :green
          say "The admin panel has been mounted! Next, follow these steps:", :green
          say "="*65, :green
          say instructions.join("\n")
          say "="*65, :green
          say
        else
          say "You are not at the root of a Padrino application! (config/boot.rb not found)"
        end
      end
    end # AdminApp
  end # Generators
end # Padrino
