module Padrino
  module Generators

    class AdminApp < Thor::Group

      # Add this generator to our padrino-gen
      Padrino::Generators.add_generator(:admin, self)

      # Define the source template root and themes
      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      def self.banner; "padrino-gen admin"; end
      def self.themes; Dir[File.dirname(__FILE__) + "/templates/assets/stylesheets/themes/*"].map { |t| File.basename(t) }.sort; end

      # Include related modules
      include Thor::Actions
      include Padrino::Generators::Actions
      include Padrino::Generators::Admin::Actions

      desc "Description:\n\n\tpadrino-gen admin generates a new Padrino Admin application"

      class_option :skip_migration, :aliases => "-s", :default => false, :type => :boolean
      class_option :root, :desc => "The root destination", :aliases => '-r', :default => ".", :type => :string
      class_option :destroy, :aliases => '-d', :default => false, :type => :boolean
      class_option :name, :desc => "The app name", :aliases => '-a', :default => "Padrino Admin", :type => :string
      class_option :theme, :desc => "Your admin theme: (#{self.themes.join(", ")})", :default => "default", :type => :string

      # Copies over the Padrino base admin application
      def create_admin
        self.destination_root = options[:root]
        if in_app_root?

          unless supported_orm.include?(orm)
            say "<= At the moment, Padrino only supports #{supported_orm.join(" or ")}. Sorry!"
            raise SystemExit
          end

          unless self.class.themes.include?(options[:theme])
            say "<= You need to choose a theme from: #{self.class.themes.join(", ")}"
            raise SystemExit
          end

          self.behavior = :revoke if options[:destroy]

          ext = fetch_component_choice(:renderer)

          directory "templates/app",     destination_root("admin")
          directory "templates/assets",  destination_root("public", "admin")

          Padrino::Generators::Model.start([
            "account", "name:string", "surname:string", "email:string", "crypted_password:string", "salt:string", "role:string",
            "-r=#{options[:root]}", "-s=#{options[:skip_migration]}", "-d=#{options[:destroy]}"
          ])

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

          admin_app = Padrino::Generators::AdminPage.new(["account"], :root => options[:root])
          admin_app.default_orm = Padrino::Admin::Generators::Orm.new(:account, orm, columns, column_fields)
          admin_app.invoke

          template "templates/account/#{orm}.rb.tt",                     destination_root("app", "models", "account.rb"), :force => true
          template "templates/account/seeds.rb.tt",                      destination_root("db/seeds.rb")
          template "templates/#{ext}/app/base/_sidebar.#{ext}.tt",       destination_root("admin/views/base/_sidebar.#{ext}")
          template "templates/#{ext}/app/base/index.#{ext}.tt",          destination_root("admin/views/base/index.#{ext}")
          template "templates/#{ext}/app/layouts/application.#{ext}.tt", destination_root("admin/views/layouts/application.#{ext}")
          template "templates/#{ext}/app/sessions/new.#{ext}.tt",        destination_root("admin/views/sessions/new.#{ext}")

          add_project_module :accounts
          append_file destination_root("config/apps.rb"),  "\nPadrino.mount(\"Admin\").to(\"/admin\")"
          gsub_file destination_root("admin/views/accounts/_form.#{ext}"), "f.text_field :role, :class => :text_field", "f.select :role, :options => access_control.roles"
          gsub_file destination_root("admin/controllers/accounts.rb"), "if account.destroy", "if account != current_account && account.destroy"
          return if self.behavior == :revoke
          say (<<-TEXT).gsub(/ {10}/,'')

          =================================================================
          The admin panel has been mounted! Next, follow these steps:
          =================================================================
            1) Run migrations (if necessary)
            2) Run 'padrino rake seed'
            3) Visit the admin panel in the browser at '/admin'
          =================================================================

          TEXT
        else
          say "You are not at the root of a Padrino application! (config/boot.rb not found)" unless in_app_root?
        end
      end
    end # AdminApp
  end # Generators
end # Padrino