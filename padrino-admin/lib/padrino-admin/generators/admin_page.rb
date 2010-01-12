module Padrino
  module Generators

    class AdminPage < Thor::Group

      # Add this generator to our padrino-gen
      Padrino::Generators.add_generator(:admin_page, self)

      # Define the source template root
      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      def self.banner; "padrino-gen backend_page [Model]"; end

      # Include related modules
      include Thor::Actions
      include Padrino::Generators::Actions

      desc "Description:\n\n\tpadrino-gen backend_page YourModel"
      argument :model, :desc => "The name of your model"
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
          @model_name     = model
          @model_klass    = model.constantize
          @model_plural   = model.to_s.downcase.pluralize
          @model_singular = model.to_s.downcase
          @app_root       = File.join(options[:root] || '.', options[:admin_path])
          self.behavior   = :revoke if options[:destroy]
          template "templates/controller.rb.tt",     app_root_path(options[:admin_path], "/controllers/#{@model_plural}.rb")
          template "templates/views/_form.haml.tt",  app_root_path(options[:admin_path], "/views/#{@model_plural}/_form.haml")
          template "templates/views/edit.haml.tt",   app_root_path(options[:admin_path], "/views/#{@model_plural}/edit.haml")
          template "templates/views/grid.js.erb.tt", app_root_path(options[:admin_path], "/views/#{@model_plural}/grid.js.erb")
          template "templates/views/new.haml.tt",    app_root_path(options[:admin_path], "/views/#{@model_plural}/new.haml")
          template "templates/views/store.jml.tt",   app_root_path(options[:admin_path], "/views/#{@model_plural}/store.jml")
          inject_into_file app_root_path("#{options[:admin_path]}/app.rb"),  access_control(@model_plural), :before => "      # Put before other permissions [don't delete this line!!!]"
          empty_directory app_root_path(options[:admin_path], "/views/#{@model_plural}")
          include_component_module_for(:test, options[:root])
          generate_controller_test(model.downcase.pluralize, options[:root])
        else
          say "You are not at the root of a Padrino application! (config/boot.rb not found)" and return unless in_app_root?
        end
      end
    end

  end
end