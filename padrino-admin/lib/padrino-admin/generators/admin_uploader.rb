module Padrino
  module Generators

    class AdminUploader < Thor::Group

      # Add this generator to our padrino-gen
      Padrino::Generators.add_generator(:admin_uploader, self)

      # Define the source template root
      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      def self.banner; "padrino-gen admin_uploader"; end

      # Include related modules
      include Thor::Actions
      include Padrino::Generators::Actions

      desc "Description:\n\n\tpadrino-gen admin_uploader Name"
      class_option :admin_path, :desc => "Path where is stored your admin app", :aliases => '-p', :type => :string, :default => "admin"
      class_option :root,       :desc => "The root destination",                :aliases => '-r', :type => :string, :default => "."
      class_option :destroy,    :desc => "Destroy the uploader",                :aliases => '-d', :default => false, :type => :boolean

      # Create controller for admin
      def create_controller
        self.destination_root = options[:root]
        if in_app_root?
          @app_root       = File.join(options[:root], options[:admin_path])
          self.behavior   = :revoke if options[:destroy]

          if options[:destroy] || !File.read(destination_root("GemFile")).include?("carrierwave")
            append_file destination_root("Gemfile"),  "\n\n# Uploader requirements\ngem 'carrierwave'"
          end

          copy_file "templates/uploader/controller.rb",      destination_root(options[:admin_path], "/controllers/uploads.rb")
          copy_file "templates/uploader/views/grid.js.erb",  destination_root(options[:admin_path], "/views/uploads/grid.js.erb")
          copy_file "templates/uploader/views/store.jml",    destination_root(options[:admin_path], "/views/uploads/store.jml")
          copy_file "templates/uploader/models/upload.rb",   destination_root("app", "models", "upload.rb")
          copy_file "templates/uploader/models/uploader.rb", destination_root("lib", "uploader.rb")

          Padrino::Generators::Migration.dup.start([
            "upload", "file:string", "created_at:datetime",
            "-r=#{options[:root]}", "-d=#{options[:destroy]}"
          ]) unless skip_migrations(options[:root])

          add_permission(options[:admin_path], "role.project_module :uploads, \"/admin/uploads.js\"")

          return if self.behavior == :revoke

          say (<<-TEXT).gsub(/ {10}/,'')

          -----------------------------------------------------
          1) Run migrations
          2) That's all!!
          -----------------------------------------------------

          TEXT
        else
          say "You are not at the root of a Padrino application! (config/boot.rb not found)" and return unless in_app_root?
        end
      end
    end

  end
end