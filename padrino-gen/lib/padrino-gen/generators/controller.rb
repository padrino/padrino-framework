module Padrino
  module Generators
    ##
    # Responsible for generating route controllers and associated tests within a Padrino application.
    #
    class Controller < Thor::Group

      # Add this generator to our padrino-gen
      Padrino::Generators.add_generator(:controller, self)

      # Define the source template root
      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      # Defines the banner for this CLI generator
      def self.banner; "padrino-gen controller [name]"; end

      # Include related modules
      include Thor::Actions
      include Padrino::Generators::Actions
      include Padrino::Generators::Components::Actions

      desc "Description:\n\n\tpadrino-gen controller generates a new Padrino controller"

      argument :name, :desc => "The name of your padrino controller"
      argument :fields, :desc => "The fields for the controller", :type => :array, :default => []
      class_option :root, :desc => "The root destination", :aliases => '-r', :default => ".", :type => :string
      class_option :app, :desc => "The application destination path", :aliases => '-a', :default => "/app", :type => :string
      class_option :destroy, :aliases => '-d', :default => false, :type => :boolean

      # Show help if no argv given
      require_arguments!

      # Execute controller generation
      #
      # @api private
      def create_controller
        self.destination_root = options[:root]
        if in_app_root?
          app = options[:app]
          check_app_existence(app)
          @app_name = fetch_app_name(app)
          @actions  = controller_actions(fields)
          @controller = name.to_s.underscore
          self.behavior = :revoke if options[:destroy]
          template "templates/controller.rb.tt", destination_root(app, "controllers", "#{name.to_s.underscore}.rb")
          template "templates/helper.rb.tt",     destination_root(app, "helpers", "#{name.to_s.underscore}_helper.rb")
          empty_directory destination_root(app, "/views/#{name.to_s.underscore}")
          include_component_module_for(:test)
          generate_controller_test(name) if test?
        else
          say "You are not at the root of a Padrino application! (config/boot.rb not found)"
        end
      end
    end # Controller
  end # Generators
end # Padrino
