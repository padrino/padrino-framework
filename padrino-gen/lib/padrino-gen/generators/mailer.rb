module Padrino
  module Generators
    ##
    # Responsible for the generating mailers and message definitions.
    #
    class Mailer < Thor::Group

      Padrino::Generators.add_generator(:mailer, self)

      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      def self.banner; 'padrino-gen mailer [name]'; end

      include Thor::Actions
      include Padrino::Generators::Actions
      include Padrino::Generators::Components::Actions

      desc "Description:\n\n\tpadrino-gen mailer generates a new Padrino mailer"

      argument     :name,      :desc => 'The name of your padrino mailer'
      argument     :actions,   :desc => 'The delivery actions to add to your mailer',                                   :type =>  :array, :default =>  []
      class_option :root,      :desc => 'The root destination',                   :aliases => '-r', :default => '.',    :type => :string
      class_option :app,       :desc => 'The application destination path',       :aliases => '-a', :default => '/app', :type => :string
      class_option :destroy,                                                      :aliases => '-d', :default => false,  :type => :boolean
      class_option :namespace, :desc => 'The name space of your padrino project', :aliases => '-n', :default => '',     :type => :string

      # Show help if no ARGV given.
      require_arguments!

      ##
      # Execute mailer generation.
      #
      def create_mailer
        validate_namespace name
        self.destination_root = options[:root]
        if in_app_root?
          app = options[:app]
          check_app_existence(app)
          self.behavior    = :revoke if options[:destroy]
          @project_name    = options[:namespace].underscore.camelize
          @project_name    = fetch_project_name(app) if @project_name.empty?
          @app_name        = fetch_app_name(app)
          @actions         = actions.map(&:to_sym)
          @short_name      = name.to_s.gsub(/_mailer/i, '').underscore.downcase
          @mailer_basename = @short_name.underscore
          template "templates/mailer.rb.tt", destination_root(app, 'mailers', "#{@mailer_basename}.rb")
          empty_directory destination_root(app, 'views', 'mailers', @mailer_basename)
        else
          say 'You are not at the root of a Padrino application! (config/boot.rb not found)'
        end
      end
    end
  end
end
