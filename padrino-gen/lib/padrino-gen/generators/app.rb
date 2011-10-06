module Padrino
  module Generators

    ##
    # Responsible for applications within a Padrino project. Creates and mounts the application and gives the user related information.
    #
    class App < Thor::Group

      # Add this generator to our padrino-gen
      Padrino::Generators.add_generator(:app, self)

      # Define the source template root
      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      # Defines the banner for this CLI generator
      def self.banner; "padrino-gen project [name]"; end

      # Include related modules
      include Thor::Actions
      include Padrino::Generators::Actions

      desc "Description:\n\n\tpadrino-gen app generates a new Padrino application"

      argument :name, :desc => "The name of your padrino application"

      class_option :root,    :desc => "The root destination",       :aliases => '-r', :default => ".",   :type => :string
      class_option :destroy,                                        :aliases => '-d', :default => false, :type => :boolean
      class_option :tiny,    :desc => "Generate tiny app skeleton", :aliases => '-i', :default => false, :type => :boolean

      # Show help if no argv given
      require_arguments!

      # Copies over the Padrino base admin application
      #
      # @api private
      def create_app
        self.destination_root = options[:root]
        @app_name = name.gsub(/\W/, "_").underscore.camelize
        if in_app_root?
          self.behavior = :revoke if options[:destroy]
          app_skeleton(@app_name.downcase, options[:tiny])
          empty_directory destination_root("public/#{@app_name.downcase}")
          append_file destination_root("config/apps.rb"),  "\nPadrino.mount(\"#{@app_name}\").to(\"/#{@app_name.downcase}\")"

          return if self.behavior == :revoke
          say
          say "="*65, :green
          say "Your #{@app_name} application has been installed."
          say "="*65, :green
          say "This application has been mounted to /#{@app_name.downcase}"
          say "You can configure a different path by editing 'config/apps.rb"
          say "="*65, :green
          say
        else
          say "You are not at the root of a Padrino application! (config/boot.rb not found)"
        end
      end
    end # App
  end # Generators
end # Padrino
