module Padrino
  module Generators

    class App < Thor::Group

      # Add this generator to our padrino-gen
      Padrino::Generators.add_generator(:app, self)

      # Define the source template root
      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      def self.banner; "padrino-gen project [name]"; end

      # Include related modules
      include Thor::Actions
      include Padrino::Generators::Actions

      desc "Description:\n\n\tpadrino-gen project generate a new Padrino application"

      argument :name, :desc => "The name of your padrino application"

      class_option :root, :desc => "The root destination", :aliases => '-r', :default => ".", :type => :string
      class_option :destroy, :aliases => '-d', :default => false,   :type    => :boolean

      # Show help if no argv given
      def self.start(given_args=ARGV, config={})
        given_args = ["-h"] if given_args.empty?
        super(given_args, config)
      end

      # Copies over the Padrino base admin application
      def create_app
        self.destination_root = options[:root]
        @class_name = name.underscore.classify
        if in_app_root?
          directory("app/", destination_root(name))
          append_file destination_root("config/apps.rb"),  "\nPadrino.mount(\"#{@class_name}\").to(\"/#{name.underscore}\")"
          
          return if self.behavior == :revoke
          say (<<-TEXT).gsub(/ {10}/,'')

          =================================================================
          Your #{@class_name} Application now is installed. 
          It's available on /#{name.underscore}
          You can setup a new path editing config/apps.rb
          =================================================================

          TEXT
        else
          say "You are not at the root of a Padrino application! (config/boot.rb not found)" and exit unless in_app_root?
        end
      end

    end

  end
end