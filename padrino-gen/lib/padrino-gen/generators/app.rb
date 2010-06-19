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

      desc "Description:\n\n\tpadrino-gen app generates a new Padrino application"

      argument :name, :desc => "The name of your padrino application"

      class_option :root,    :desc => "The root destination",       :aliases => '-r', :default => ".",   :type => :string
      class_option :destroy,                                        :aliases => '-d', :default => false, :type => :boolean
      class_option :tiny,    :desc => "Generate tiny app skeleton", :aliases => '-i', :default => false, :type => :boolean

      # Show help if no argv given
      require_arguments!

      # Copies over the Padrino base admin application
      def create_app
        self.destination_root = options[:root]
        @app_name = name.gsub(/\W/, "_").underscore.camelize
        if in_app_root?
          app_skeleton(name, options[:tiny])
          append_file destination_root("config/apps.rb"),  "\nPadrino.mount(\"#{@app_name}\").to(\"/#{name.underscore}\")"

          return if self.behavior == :revoke
          say (<<-TEXT).gsub(/ {10}/,'')

          =================================================================
          Your #{@app_name} application has been installed.
          This application has been mounted to /#{name.underscore}
          You can configure a different path by editing 'config/apps.rb'
          =================================================================

          TEXT
        else
          say "You are not at the root of a Padrino application! (config/boot.rb not found)" and exit unless in_app_root?
        end
      end
    end # App
  end # Generators
end # Padrino