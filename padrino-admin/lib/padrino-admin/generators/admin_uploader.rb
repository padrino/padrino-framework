module Padrino
  module Generators

    class AdminUploader < Thor::Group

      # Add this generator to our padrino-gen
      Padrino::Generators.add_generator(:admin_uploader, self)

      # Define the source template root
      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      def self.banner; "padrino-gen admin_uploader [Name]"; end

      # Include related modules
      include Thor::Actions
      include Padrino::Generators::Actions

      desc "Description:\n\n\tpadrino-gen admin_uploader Name"
      argument :name, :desc => "The name of your uploader"
      class_option :admin_path, :aliases => '-p', :type => :string, :default => "admin"
      class_option :root,       :aliases => '-r', :type => :string
      class_option :destroy,    :aliases => '-d', :default => false, :type => :boolean

      # Show help if no argv given
      def self.start(given_args=ARGV, config={})
        given_args = ["-h"] if given_args.empty?
        super
      end

      # Create controller for admin
      def create_controller
        if in_app_root?(options[:root])
          @name           = name.classify
          @app_root       = File.join(options[:root] || '.', options[:admin_path])
          self.behavior   = :revoke if options[:destroy]

          if options[:destroy] || !File.read(app_root_path("GemFile")).include?("carrierwave")
            append_file app_root_path("Gemfile"),  "\n\n# Uploader requirements\ngem 'carrierwave'"
          end

          template "templates/uploader.rb.tt", app_root_path("/app/models/#{name.underscore}_uploader.rb")

          return if self.behavior == :revoke

          say (<<-TEXT).gsub(/ {10}/,'')

          -----------------------------------------------------
          1) Add a column in your models called ex (for AR):

            add_column :youtablename, :my_attachment, :string

          2) Now attach in models that need #{name} some like:

            mount_uploader :my_attachment, #{@name}Uploader

          3) Make sure you have +CarrierWave+ installed, if not:

            sudo gem install carrierwave

          Rember to upgrade your database !!!
          -----------------------------------------------------

          TEXT
        else
          say "You are not at the root of a Padrino application! (config/boot.rb not found)" and return unless in_app_root?
        end
      end
    end

  end
end