module Padrino
  module Generators
    ##
    # Responsible for the generating mailers and message definitions.
    #
    class Mailer < Thor::Group

      # Add this generator to our padrino-gen
      Padrino::Generators.add_generator(:mailer, self)

      # Define the source template root
      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      # Defines the banner for this CLI generator
      def self.banner; "padrino-gen mailer [name]"; end

      # Include related modules
      include Thor::Actions
      include Padrino::Generators::Actions
      include Padrino::Generators::Components::Actions

      desc "Description:\n\n\tpadrino-gen mailer generates a new Padrino mailer"

      argument :name, :desc => "The name of your padrino mailer"
      argument :actions, :desc => "The delivery actions to add to your mailer", :type => :array, :default => []
      class_option :root, :desc => "The root destination", :aliases => '-r', :default => ".", :type => :string
      class_option :app, :desc => "The application destination path", :aliases => '-a', :default => "/app", :type => :string
      class_option :destroy, :aliases => '-d', :default => false, :type => :boolean

      # Show help if no argv given
      require_arguments!

      # Execute mailer generation
      #
      # @api private
      def create_mailer
        self.destination_root = options[:root]
        if in_app_root?
          app = options[:app]
          check_app_existence(app)
          self.behavior = :revoke if options[:destroy]
          @app_name = fetch_app_name(app)
          @actions = actions.map{|a| a.to_sym}
          @short_name = name.to_s.gsub(/mailer/i, '').underscore.downcase
          @mailer_basename = @short_name.underscore
          template "templates/mailer.rb.tt", destination_root(app, "mailers", "#{@mailer_basename}.rb")
          empty_directory destination_root(app, 'views', 'mailers', @mailer_basename)
        else
          say "You are not at the root of a Padrino application! (config/boot.rb not found)"
        end
      end
    end # Mailer
  end # Generators
end # Padrino
