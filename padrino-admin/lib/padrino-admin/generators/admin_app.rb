module Padrino
  module Generators

    class AdminApp < Thor::Group

      # Add this generator to our padrino-gen
      Padrino::Generators.add_generator(:admin, self)

      # Define the source template root
      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      def self.banner; "padrino-gen backend"; end

      # Include related modules
      include Thor::Actions
      include Padrino::Generators::Actions

      desc "Description:\n\n\tpadrino-gen controller generates a new Padrino Admin"

      class_option :root,    :aliases => '-r', :default => ".",     :type    => :string
      class_option :path,    :aliases => '-p', :type    => :string, :default => "admin"
      class_option :destroy, :aliases => '-d', :default => false,   :type    => :boolean

      # Copies over the Padrino base admin application
      def create_admin
        if in_app_root?(options[:root])
          @app_path = options[:path]
          @orm = fetch_component_choice(:orm, options[:root]).to_sym rescue :datamapper
          supported_orm = [:datamapper, :activerecord]
          skip_migration = case @orm
            when :activerecord then false
            when :sequel       then false
            else true
          end

          raise SystemExit, "A the moment we only support #{supported_orm.join(" or ")}. Sorry!" unless supported_orm.include?(@orm)

          self.behavior = :revoke if options[:destroy]
          directory("app/", File.join(options[:path]))

          Padrino::Generators::Model.dup.start([
            "account", "name:string", "surname:string", "email:string", "crypted_password:string", "salt:string", "role:string",
            "-r=#{options[:root]}", "-s=#{skip_migration}", "-d=#{options[:destroy]}"
          ])

          template "templates/db/seeds.rb.tt", app_root_path("/db/seeds.rb")

          if options[:destroy] || !File.read(app_root_path("config/apps.rb")).include?("Padrino.mount(\"Admin\").to(\"/#{@app_path}\")")
            append_file app_root_path("config/apps.rb"),  "\nPadrino.mount(\"Admin\").to(\"/#{@app_path}\")"
          end
          
          unless options[:destroy]
            say ""
            say "Your admin now is installed, now follow this steps:"
            say ""
            say "   - edit your config/database.rb"
            say "   - run padrino rake -T and run db creation according to your orm"
            say "   - run padrino rake seed"
            say ""
            say "That's all"
          end
        else
          say "You are not at the root of a Padrino application! (config/boot.rb not found)" and exit unless in_app_root?
        end
      end

    end

  end
end