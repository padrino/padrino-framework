module Padrino
  module Generators
    ##
    # Responsible for generating route helpers and associated tests within a Padrino application.
    #
    class Helper < Thor::Group

      Padrino::Generators.add_generator(:helper, self)

      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      def self.banner; "padrino-gen helper [name]"; end

      include Thor::Actions
      include Padrino::Generators::Actions
      include Padrino::Generators::Components::Actions

      desc "Description:\n\n\tpadrino-gen helper generates a new Padrino helper"

      argument     :name,       :desc => 'The name of your padrino helper'
      argument     :fields,     :desc => 'The fields for the helper',                            :default => [],     :type => :array
      class_option :root,       :desc => 'The root destination',                   :aliases => '-r', :default => '.',    :type => :string
      class_option :app,        :desc => 'The application destination path',       :aliases => '-a', :default => '/app', :type => :string
      class_option :destroy,                                                       :aliases => '-d', :default => false,  :type => :boolean
      class_option :namespace,  :desc => 'The name space of your padrino project', :aliases => '-n', :default => '',     :type => :string

      # Show help if no ARGV given
      require_arguments!

      ##
      # Execute helper generation
      #
      def create_helper
        validate_namespace name
        self.destination_root = options[:root]
        if in_app_root?
          app = options[:app]
          check_app_existence(app)
          @project_name = options[:namespace].underscore.camelize
          @project_name = fetch_project_name(app) if @project_name.empty?
          @app_name     = fetch_app_name(app)

          self.behavior = :revoke if options[:destroy]

          create_helper_files(app, name)
        else
          say 'You are not at the root of a Padrino application! (config/boot.rb not found)'
        end
      end
    end
  end
end
