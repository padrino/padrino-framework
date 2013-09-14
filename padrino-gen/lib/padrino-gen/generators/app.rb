module Padrino
  module Generators

    ##
    # Responsible for applications within a Padrino project. Creates and mounts
    # the application and gives the user related information.
    #
    class App < Thor::Group

      Padrino::Generators.add_generator(:app, self)

      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      def self.banner; "padrino-gen app [name]"; end

      include Thor::Actions
      include Padrino::Generators::Actions

      desc "Description:\n\n\tpadrino-gen app generates a new Padrino application"
      argument     :name,      :desc => 'The name of your padrino application'
      class_option :root,      :desc => 'The root destination',                   :aliases => '-r', :default => '.',   :type => :string
      class_option :destroy,                                                      :aliases => '-d', :default => false, :type => :boolean
      class_option :tiny,      :desc => 'Generate tiny app skeleton',             :aliases => '-i', :default => false, :type => :boolean
      class_option :namespace, :desc => 'The name space of your padrino project', :aliases => '-n', :default => '',    :type => :string

      # Show help if no ARGV given
      require_arguments!

      ##
      # Copies over the Padrino base admin application.
      #
      def create_app
        self.destination_root = options[:root]
        @app_folder = name.gsub(/\W/, '_').underscore
        @app_name   = @app_folder.camelize
        if in_app_root?
          @project_name = options[:namespace].underscore.camelize
          @project_name = fetch_project_name(@app_folder) if @project_name.empty?
          lowercase_app_folder = @app_folder.downcase
          self.behavior = :revoke if options[:destroy]
          app_skeleton(lowercase_app_folder, options[:tiny])
          empty_directory destination_root("public/#{lowercase_app_folder}")
          append_file destination_root('config/apps.rb'), "\nPadrino.mount('#{@project_name}::#{@app_name}', :app_file => Padrino.root('#{lowercase_app_folder}/app.rb')).to('/#{lowercase_app_folder}')"

          return if self.behavior == :revoke
          say
          say '=' * 65, :green
          say "Your #{@app_name} application has been installed."
          say '=' * 65, :green
          say "This application has been mounted to /#{@app_name.downcase}"
          say "You can configure a different path by editing 'config/apps.rb'"
        else
          say 'You are not at the root of a Padrino application! (config/boot.rb not found)'
        end
      end
    end
  end
end
