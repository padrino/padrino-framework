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
      class_option :destroy, :aliases => '-d', :default => false, :type => :boolean

      # Copies over the base sinatra starting project
      def create_model
        if in_app_root?(options[:root])
          remove_model_migration(name) if options[:destroy]
          self.behavior = :revoke if options[:destroy]
          include_component_module_for(:orm, options[:root])
          include_component_module_for(:test, options[:root])
          migration_name = "create_#{name.pluralize.underscore}"
          create_model_file(name, fields)
          generate_model_test(name)
          create_model_migration(migration_name, name, fields)
        else
          say "You are not at the root of a Padrino application! (config/boot.rb not found)" and return unless in_app_root?
        end
      end
    end

  module Components
    module Destroyers
      module ModelGen
        # destroys model and associated files
        def destroy(name)
          path = app_root_path('app/models/', "#{name.to_s.underscore}.rb")
          model_path = (File.exists?(path) ? path : nil)
          path = app_root_path('test/models/', "#{name.to_s.underscore}_test.rb")
          test_path = (File.exists?(path) ? path : nil)
          path = app_root_path('test/models/', "#{name.to_s.underscore}_spec.rb")
          spec_path = (File.exists?(path) ? path : nil)
          migration_path =  Dir[app_root_path('db/migrate/*.rb')].select do |f| 
            File.basename(f).match(/create_#{name.to_s.underscore}/)
          end.first
          [model_path, test_path, migration_path, spec_path].each do |file|
            if file
            remove_file(file)
            say "Deleted #{file}..."
            end
          end
        end
      end
    end
  end
  end
end