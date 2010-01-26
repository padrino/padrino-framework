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

      desc "Description:\n\n\tpadrino-gen admin generates a new Padrino Admin"

      class_option :root, :desc => "The root destination",    :aliases => '-r', :default => ".",     :type    => :string
      class_option :path,    :aliases => '-p', :type    => :string, :default => "admin"
      class_option :destroy, :aliases => '-d', :default => false,   :type    => :boolean

      # Copies over the Padrino base admin application
      def create_admin
        self.destination_root = options[:root]
        if in_app_root?
          @app_path = options[:path]

          unless supported_orm.include?(orm(options[:root]))
            say "<= A the moment we only support #{supported_orm.join(" or ")}. Sorry!"
            raise SystemExit
          end

          self.behavior = :revoke if options[:destroy]
          directory("app/", destination_root(options[:path]))

          Padrino::Generators::Model.dup.start([
            "account", "name:string", "surname:string", "email:string", "crypted_password:string", "salt:string", "role:string",
            "-r=#{options[:root]}", "-s=#{skip_migrations(options[:root])}", "-d=#{options[:destroy]}"
          ])

          insert_into_gemfile("haml")

          template "templates/page/db/seeds.rb.tt", destination_root("/db/seeds.rb")

          if options[:destroy] || !File.read(destination_root("config/apps.rb")).include?("Padrino.mount(\"Admin\").to(\"/#{@app_path}\")")
            append_file destination_root("config/apps.rb"),  "\nPadrino.mount(\"Admin\").to(\"/#{@app_path}\")"
          end

          unless options[:destroy]
            say (<<-TEXT).gsub(/ {12}/,'')

            -----------------------------------------------------------------
            Your admin now is installed, now follow this steps:

              - edit your config/database.rb
              - run padrino rake -T and run db creation according to your orm
              - run padrino rake seed

            That's all
            -----------------------------------------------------------------

            TEXT
          end
        else
          say "You are not at the root of a Padrino application! (config/boot.rb not found)" and exit unless in_app_root?
        end
      end

    end

  end
end