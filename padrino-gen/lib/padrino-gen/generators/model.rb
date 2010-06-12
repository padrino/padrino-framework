module Padrino
  module Generators

    class Model < Thor::Group

      # Add this generator to our padrino-gen
      Padrino::Generators.add_generator(:model, self)

      # Define the source template root
      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      def self.banner; "padrino-gen model [name] [fields]"; end

      # Include related modules
      include Thor::Actions
      include Padrino::Generators::Actions
      include Padrino::Generators::Components::Actions

      desc "Description:\n\n\tpadrino-gen model generates a new model and migration files"

      argument :name, :desc => "The name of your padrino model"
      argument :fields, :desc => "The fields for the model", :type => :array, :default => []
      class_option :root, :desc => "The root destination", :aliases => '-r', :default => ".", :type => :string
      class_option :app, :desc => "The application destination path", :aliases => '-a', :default => "/app", :type => :string
      class_option :destroy, :aliases => '-d', :default => false, :type => :boolean
      class_option :skip_migration, :aliases => "-s", :default => false, :type => :boolean

      # Show help if no argv given
      require_arguments!

      def create_model
        self.destination_root = options[:root]
        if in_app_root?
          app = options[:app]
          check_app_existence(app)
          self.behavior = :revoke if options[:destroy]
          if invalids = invalid_fields(fields)
            say "Invalid field name:", :red
            say " #{invalids.join(", ")}"
            return
          end
          unless include_component_module_for(:orm)
            say "<= You need an ORM adapter for run this generator. Sorry!"
            raise SystemExit
          end
          include_component_module_for(:test)
          migration_name = "create_#{name.pluralize.underscore}"
          create_model_file(name, :fields => fields, :app => app)
          generate_model_test(name) if test?
          create_model_migration(migration_name, name, fields) unless options[:skip_migration]
        else
          say "You are not at the root of a Padrino application! (config/boot.rb not found)" and return unless in_app_root?
        end
      end
    end # Model
  end # Generators
end # Padrino