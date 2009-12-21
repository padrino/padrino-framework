require 'thor'

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
      class_option :root, :aliases => '-r', :default => nil, :type => :string

      # Copies over the base sinatra starting project
      def create_model
        if in_app_root?(options[:root])
          include_component_module_for(:orm, options[:root])
          include_component_module_for(:test, options[:root])
          migration_name = "create_#{name.pluralize.underscore}"
          model_success = create_model_file(name, fields)
          generate_model_test(name) if model_success
          model_success ? create_model_migration(migration_name, name, fields) : 
                          say("'#{name}' model has already been generated!")
        else
          say "You are not at the root of a Padrino application! (config/boot.rb not found)" and return unless in_app_root?
        end
      end
    end

  end
end