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
      include Padrino::Generators::Admin::Actions

      desc "Description:\n\n\tpadrino-gen admin_uploader Name"
      class_option :root,       :desc => "The root destination", :aliases => '-r', :type => :string, :default => "."
      class_option :destroy,    :desc => "Destroy the uploader", :aliases => '-d', :default => false, :type => :boolean

      # Create controller for admin
      def create_controller
        self.destination_root = options[:root]
        if in_app_root?

          unless File.exist?(destination_root("admin"))
            say "<= You need to create an admin application first!"
            raise SystemExit
          end

          self.behavior = :revoke if options[:destroy]

          copy_file "templates/uploader/controller.rb",     destination_root("/admin/controllers/uploads.rb")
          copy_file "templates/uploader/views/grid.js.erb", destination_root("/admin/views/uploads/grid.js.erb")
          copy_file "templates/uploader/views/store.jml",   destination_root("/admin/views/uploads/store.jml")
          copy_file "templates/uploader/lib/uploader.rb",   destination_root("lib", "uploader.rb")

          Padrino::Generators::Model.dup.start([
            "upload", "file:string", "created_at:datetime",
            "-r=#{options[:root]}", "-s=#{options[:skip_migration]}", "-d=#{options[:destroy]}"
          ])

          inject_into_file destination_root("app", "models", "upload.rb"), :before => "end" do
            (<<-RUBY).gsub(/ {14}/, '  ')
              mount_uploader :file, Uploader

              def size
                file.size if file
              end

              def content_type
                file.content_type if file
              end
            RUBY
          end

          # Add a carrierwave dependency
          inject_into_file("Gemfile", "\n# Uploader requirements\n# gem 'mini_magick'\ngem 'carrierwave'\n", :before => "\n# Padrino")

          # Only for datamapper
          if orm == :datamapper
            inject_into_file destination_root("app", "models", "upload.rb"), :after => "property :file, String" do
              ", :auto_validation => false"
            end
          end

          add_permission("/admin", "role.project_module :uploads, \"/admin/uploads.js\"")

          return if self.behavior == :revoke
          say (<<-TEXT).gsub(/ {10}/,'')

          =================================================================
          Uploader has been successfully installed, now follow this steps:
          =================================================================
            1) Run migrations
            2) That's all!!
          =================================================================

          TEXT
        else
          say "You are not at the root of a Padrino application! (config/boot.rb not found)" and return unless in_app_root?
        end
      end
    end

  end
end