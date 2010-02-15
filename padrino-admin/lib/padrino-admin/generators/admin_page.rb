module Padrino
  module Generators

    class AdminPage < Thor::Group

      # Add this generator to our padrino-gen
      Padrino::Generators.add_generator(:admin_page, self)

      # Define the source template root
      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      def self.banner; "padrino-gen admin_page [Model]"; end

      # Include related modules
      include Thor::Actions
      include Padrino::Generators::Actions

      desc "Description:\n\n\tpadrino-gen admin_page YourModel"
      argument :model, :desc => "The name of your model"
      class_option :root, :desc => "The root destination", :aliases => '-r', :type => :string
      class_option :destroy, :aliases => '-d', :default => false, :type => :boolean

      # Show help if no argv given
      def self.start(given_args=ARGV, config={})
        given_args = ["-h"] if given_args.empty?
        super(given_args, config)
      end

      # Create controller for admin
      def create_controller
        self.destination_root = options[:root]
        if in_app_root?
          @model_name     = model.classify
          @model_klass    = model.classify.constantize
          @model_plural   = model.underscore.pluralize
          @model_singular = model.underscore
          self.behavior   = :revoke if options[:destroy]

          template "templates/page/controller.rb.tt",     destination_root("/admin/controllers/#{@model_plural}.rb")
          template "templates/page/views/_form.haml.tt",  destination_root("/admin/views/#{@model_plural}/_form.haml")
          template "templates/page/views/edit.haml.tt",   destination_root("/admin/views/#{@model_plural}/edit.haml")
          template "templates/page/views/grid.js.erb.tt", destination_root("/admin/views/#{@model_plural}/grid.js.erb")
          template "templates/page/views/new.haml.tt",    destination_root("/admin/views/#{@model_plural}/new.haml")
          template "templates/page/views/store.jml.tt",   destination_root("/admin/views/#{@model_plural}/store.jml")

          add_access_control_permission("/admin", @model_plural)
          include_component_module_for(:test) if test?
          generate_controller_test(model.downcase.pluralize)
        else
          say "You are not at the root of a Padrino application! (config/boot.rb not found)" and return unless in_app_root?
        end
      end
    end

  end
end