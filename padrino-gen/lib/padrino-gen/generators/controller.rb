require 'thor'

module Padrino
  module Generators

    class Controller < Thor::Group

      # Add this generator to our padrino-gen
      Padrino::Generators.add_generator(:controller, self)

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
      class_option :root, :desc => "The root destination", :aliases => '-r', :default => ".", :type => :string
      class_option :destroy, :aliases => '-d', :default => false, :type => :boolean

      # Show help if no argv given
      def self.start(given_args=ARGV, config={})
        given_args = ["-h"] if given_args.empty?
        super
      end

      def create_controller
        self.destination_root = options[:root]
        if in_app_root?
          @app_name = fetch_app_name(options[:root])
          @actions  = controller_actions(fields)
          @controller = name
          self.behavior = :revoke if options[:destroy]
          template "templates/controller.rb.tt", destination_root("app/controllers", "#{name}.rb")
          template "templates/helper.rb.tt",     destination_root("app/helpers", "#{name}_helper.rb")
          empty_directory destination_root("app/views/#{name}")
          include_component_module_for(:test)
          generate_controller_test(name)
        else
          say "You are not at the root of a Padrino application! (config/boot.rb not found)" and return unless in_app_root?
        end
      end
    end

  end
end
