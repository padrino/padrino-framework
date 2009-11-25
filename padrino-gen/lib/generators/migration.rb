require 'thor'

module Padrino
  module Generators

    class Migration < Thor::Group
      # Define the source template root
      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      def self.banner; "padrino-gen migration [name] [fields]"; end

      # Include related modules
      include Thor::Actions
      include Padrino::Generators::Actions
      include Padrino::Generators::Components::Actions

      desc "Description:\n\n\tpadrino-gen migration generates a new migration file"

      argument :name, :desc => "The name of your padrino migration"
      argument :columns, :desc => "The columns for the migration", :type => :array, :default => []
      class_option :root, :aliases => '-r', :default => nil, :type => :string

      # Copies over the base sinatra starting project
      def create_model
        if in_app_root?(options[:root])
          include_component_module_for(:orm, options[:root])
          create_migration_file(name, name, columns)
        else
          say "You are not at the root of a Padrino application! (config/boot.rb not found)" and return unless in_app_root?
        end
      end
    end

  end
end