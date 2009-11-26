require 'thor'

module Padrino
  module Generators

    class Controller < Thor::Group
      # Define the source template root
      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      def self.banner; "padrino-gen controller [name]"; end

      # Include related modules
      include Thor::Actions
      include Padrino::Generators::Actions
      include Padrino::Generators::Components::Actions

      desc "Description:\n\n\tpadrino-gen controller generates a new Padrino controller"

      argument :name, :desc => "The name of your padrino controller"
      argument :fields, :desc => "The fields for the controller", :type => :array, :default => []
      class_option :root, :aliases => '-r', :default => nil, :type => :string

      # Copies over the base sinatra starting project
      def create_controller
        if in_app_root?(options[:root])
          @app_name = fetch_app_name(options[:root])
          @actions = controller_actions(fields)
          template "templates/controller.rb.tt", app_root_path("app/controllers", "#{name}.rb")
          template "templates/helper.rb.tt",     app_root_path("app/helpers", "#{name}_helper.rb")
          empty_directory app_root_path("app/views/#{name}")
          include_component_module_for(:test, options[:root])
          generate_controller_test(name, options[:root] || '.')
        else
          say "You are not at the root of a Padrino application! (config/boot.rb not found)" and return unless in_app_root?
        end
      end
    end

  end
end
