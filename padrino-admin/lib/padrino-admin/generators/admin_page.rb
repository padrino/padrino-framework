module Padrino
  module Generators

    class AdminPage < Thor::Group
      attr_accessor :orm

      # Add this generator to our padrino-gen
      Padrino::Generators.add_generator(:admin_page, self)

      # Define the source template root
      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      def self.banner; "padrino-gen admin_page [Model]"; end

      # Include related modules
      include Thor::Actions
      include Padrino::Generators::Actions
      include Padrino::Generators::Admin::Actions

      desc "Description:\n\n\tpadrino-gen admin_page YourModel"
      argument :model, :desc => "The name of your model"
      class_option :skip_migration, :aliases => "-s", :default => false, :type => :boolean
      class_option :root, :desc => "The root destination", :aliases => '-r', :type => :string
      class_option :destroy, :aliases => '-d', :default => false, :type => :boolean

      # Show help if no argv given
      require_arguments!

      # Create controller for admin
      def create_controller
        self.destination_root = options[:root]
        if in_app_root?
          @orm ||= Padrino::Admin::Generators::Orm.new(model, adapter)
          self.behavior = :revoke if options[:destroy]

          template "templates/page/controller.rb.tt",    destination_root("/admin/controllers/#{@orm.name_plural}.rb")
          template "templates/erb/page/_form.erb.tt",    destination_root("/admin/views/#{@orm.name_plural}/_form.erb")
          template "templates/erb/page/_sidebar.erb.tt", destination_root("/admin/views/#{@orm.name_plural}/_sidebar.erb")
          template "templates/erb/page/edit.erb.tt",     destination_root("/admin/views/#{@orm.name_plural}/edit.erb")
          template "templates/erb/page/index.erb.tt",    destination_root("/admin/views/#{@orm.name_plural}/index.erb")
          template "templates/erb/page/new.erb.tt",      destination_root("/admin/views/#{@orm.name_plural}/new.erb")

          add_project_module(@orm.name_plural)
        else
          say "You are not at the root of a Padrino application! (config/boot.rb not found)" and return unless in_app_root?
        end
      end
    end

  end
end