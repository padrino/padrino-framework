require 'padrino-core/application' unless defined?(Padrino::Application)

module Padrino
  module Generators
    ##
    # Responsible for generating route controllers and associated tests within a Padrino application.
    #
    class Controller < Thor::Group

      Padrino::Generators.add_generator(:controller, self)

      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      def self.banner; "padrino-gen controller [name]"; end

      include Thor::Actions
      include Padrino::Generators::Actions
      include Padrino::Generators::Components::Actions

      desc "Description:\n\n\tpadrino-gen controller generates a new Padrino controller"

      argument     :name,       :desc => 'The name of your padrino controller'
      argument     :fields,     :desc => 'The fields for the controller',                            :default => [],     :type => :array
      class_option :root,       :desc => 'The root destination',                   :aliases => '-r', :default => '.',    :type => :string
      class_option :app,        :desc => 'The application destination path',       :aliases => '-a', :default => '/app', :type => :string
      class_option :destroy,                                                       :aliases => '-d', :default => false,  :type => :boolean
      class_option :namespace,  :desc => 'The name space of your padrino project', :aliases => '-n', :default => '',     :type => :string
      class_option :layout,     :desc => 'The layout for the controller',          :aliases => '-l', :default => '',     :type => :string
      class_option :parent,     :desc => 'The parent of the controller',           :aliases => '-p', :default => '',     :type => :string
      class_option :provides,   :desc => 'The formats provided by the controller', :aliases => '-f', :default => '',     :type => :string
      class_option :'no-helper',:desc => 'Not generate helper',                                      :default => false,  :type => :boolean

      # Show help if no ARGV given
      require_arguments!

      ##
      # Execute controller generation
      #
      def create_controller
        validate_namespace name
        self.destination_root = options[:root]
        if in_app_root?
          app = options[:app]
          check_app_existence(app)
          @project_name = options[:namespace].underscore.camelize
          @project_name = fetch_project_name(app) if @project_name.empty?
          @app_name     = fetch_app_name(app)
          @actions      = controller_actions(fields)
          @controller   = name.to_s.underscore
          @layout       = options[:layout] if options[:layout] && !options[:layout].empty?

          block_opts = []
          block_opts << ":parent => :#{options[:parent]}" if options[:parent] && !options[:parent].empty?
          block_opts << ":provides => [#{options[:provides]}]" if options[:provides] && !options[:provides].empty?
          @block_opts_string = block_opts.join(', ') unless block_opts.empty?

          self.behavior = :revoke if options[:destroy]
          template 'templates/controller.rb.tt', destination_root(app, 'controllers', "#{name.to_s.underscore}.rb")
          empty_directory destination_root(app, "/views/#{name.to_s.underscore}")

          if test?
            include_component_module_for(:test)
            path = @controller.dup

            if options[:parent] && !options[:parent].empty?
              path = Application.process_path_for_parent_params(path, [options[:parent]]).prepend("/")
            end
            path.prepend("/") unless path.start_with?("/")
            generate_controller_test(name, path)
          end

          create_helper_files(app, name) unless options[:'no-helper']
        else
          say 'You are not at the root of a Padrino application! (config/boot.rb not found)'
        end
      end
    end
  end
end
