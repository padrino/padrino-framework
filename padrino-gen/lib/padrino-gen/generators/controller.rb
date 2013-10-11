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

      argument     :name,      :desc => 'The name of your padrino controller'
      argument     :fields,    :desc => 'The fields for the controller',                            :default => [],     :type => :array
      class_option :root,      :desc => 'The root destination',                   :aliases => '-r', :default => '.',    :type => :string
      class_option :app,       :desc => 'The application destination path',       :aliases => '-a', :default => '/app', :type => :string
      class_option :destroy,                                                      :aliases => '-d', :default => false,  :type => :boolean
      class_option :namespace, :desc => 'The name space of your padrino project', :aliases => '-n', :default => '',     :type => :string
      class_option :layout,    :desc => 'The layout for the controller',          :aliases => '-l', :default => '',     :type => :string
      class_option :parent,    :desc => 'The parent of the controller',           :aliases => '-p', :default => '',     :type => :string
      class_option :provides,  :desc => 'the formats provided by the controller', :aliases => '-f', :default => '',     :type => :string

      # Show help if no ARGV given
      require_arguments!

      ##
      # Execute controller generation
      #
      def create_controller
        self.destination_root = options[:root]
        if in_app_root?
          app = options[:app]
          check_app_existence(app)
          @project_name = options[:namespace].underscore.camelize
          @project_name = fetch_project_name(app) if @project_name.empty?
          @app_name     = fetch_app_name(app)
          @actions      = controller_actions(fields)
          @controller   = name.to_s.underscore
          @layout       = options[:layout] if exist_option?(options[:layout])
          @block_opts_string = create_block_options
          self.behavior = :revoke if options[:destroy]
          template 'templates/controller.rb.tt', destination_root(app, 'controllers', "#{@controller}.rb")
          template 'templates/helper.rb.tt',     destination_root(app, 'helpers', "#{@controller}_helper.rb")
          empty_directory destination_root(app, "/views/#{@controller}")
          include_component_module_for(:test)
          generate_controller_test(name) if test?
        else
          say 'You are not at the root of a Padrino application! (config/boot.rb not found)'
        end
      end

      private

      def exist_option?(option)
        option && !option.empty?
      end

      def create_block_options
        block_options = []
        block_options << ":parent => :#{options[:parent]}" if exist_option?(options[:parent])
        block_options << ":provides => [#{options[:provides]}]" if exist_option?(options[:provides])
        block_options.empty? ? nil : block_options.join(', ')
      end
    end
  end
end
