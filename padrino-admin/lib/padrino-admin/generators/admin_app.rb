module Padrino
  module Generators

    class AdminApp < Thor::Group

      # Add this generator to our padrino-gen
      Padrino::Generators.add_generator(:admin, self)

      # Define the source template root
      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      def self.banner; "padrino-gen admin"; end

      # Include related modules
      include Thor::Actions
      include Padrino::Generators::Actions
      include Padrino::Generators::Admin::Actions

      desc "Description:\n\n\tpadrino-gen admin generates a new Padrino Admin"

      class_option :skip_migration, :aliases => "-s", :default => false, :type => :boolean
      class_option :root, :desc => "The root destination", :aliases => '-r', :default => ".", :type => :string
      class_option :destroy, :aliases => '-d', :default => false, :type => :boolean

      # Copies over the Padrino base admin application
      def create_admin
        self.destination_root = options[:root]
        if in_app_root?

          unless supported_orm.include?(orm)
            say "<= A the moment we only support #{supported_orm.join(" or ")}. Sorry!"
            raise SystemExit
          end

          self.behavior = :revoke if options[:destroy]
          directory("app/", destination_root("admin"))
          directory("assets/", destination_root("public", "admin"))

          Padrino::Generators::Model.dup.start([
            "account", "name:string", "surname:string", "email:string", "crypted_password:string", "salt:string", "role:string",
            "-r=#{options[:root]}", "-s=#{options[:skip_migration]}", "-d=#{options[:destroy]}"
          ])

          insert_into_gemfile("haml")
          template "templates/page/db/seeds.rb.tt", destination_root("/db/seeds.rb")
          append_file destination_root("config/apps.rb"),  "\nPadrino.mount(\"Admin\").to(\"/admin\")"

          return if self.behavior == :revoke
          say (<<-TEXT).gsub(/ {10}/,'')

          =================================================================
          Admin has been successfully installed, now follow this steps:
          =================================================================
            1) Run migrations
            2) That's all!!
          =================================================================

          TEXT
        else
          say "You are not at the root of a Padrino application! (config/boot.rb not found)" and exit unless in_app_root?
        end
      end

    end

  end
end