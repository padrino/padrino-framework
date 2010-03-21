module Padrino
  module Generators

    class Mailer < Thor::Group

      # Add this generator to our padrino-gen
      Padrino::Generators.add_generator(:mailer, self)

      # Define the source template root
      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      def self.banner; "padrino-gen mailer [name]"; end

      # Include related modules
      include Thor::Actions
      include Padrino::Generators::Actions
      include Padrino::Generators::Components::Actions

      desc "Description:\n\n\tpadrino-gen mailer generates a new Padrino mailer"

      argument :name, :desc => "The name of your padrino mailer"
      class_option :root, :desc => "The root destination", :aliases => '-r', :default => ".", :type => :string
      class_option :app, :desc => "The application destination", :aliases => '-a', :default => "/app", :type => :string
      class_option :destroy, :aliases => '-d', :default => false, :type => :boolean

      # Show help if no argv given
      require_arguments!

      def create_mailer
        self.destination_root = options[:root]
        if in_app_root?
          app = options[:app].underscore
          check_app_existence(app)
          self.behavior = :revoke if options[:destroy]
          simple_name = name.to_s.gsub(/mailer/i, '')
          @mailer_basename = "#{simple_name.downcase.underscore}_mailer"
          @mailer_klass    = "#{simple_name.downcase.camelize}Mailer"
          template "templates/mailer_initializer.rb.tt", destination_root("lib/mailer.rb"), :skip => true
          template "templates/mailer.rb.tt", destination_root(app, "mailers", "#{@mailer_basename}.rb")
          inject_into_file(destination_root(app, "app.rb"), "    register MailerInitializer\n", :after => "configure do\n")
          empty_directory destination_root(app, 'views', @mailer_basename)
        else
          say "You are not at the root of a Padrino application! (config/boot.rb not found)" and return unless in_app_root?
        end
      end
    end # Mailer
  end # Generators
end # Padrino