require 'padrino-core/version'

module Padrino
  module Generators
    class Project < Thor::Group

      # Add this generator to our padrino-gen
      Padrino::Generators.add_generator(:project, self)

      # Define the source template root
      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      def self.banner; "padrino-gen project [name] [options]"; end

      # Include related modules
      include Thor::Actions
      include Padrino::Generators::Actions
      include Padrino::Generators::Runner
      include Padrino::Generators::Components::Actions

      desc "Description:\n\n\tpadrino-gen project generates a new Padrino project"

      argument :name, :desc => "The name of your padrino project"

      class_option :app ,         :desc => "The application name",                          :aliases => '-n', :default => nil,      :type => :string
      class_option :bundle,       :desc => "Run bundle install",                            :aliases => '-b', :default => false,    :type => :boolean
      class_option :root,         :desc => "The root destination",                          :aliases => '-r', :default => ".",      :type => :string
      class_option :dev,          :desc => "Use padrino from a git checkout",                                 :default => false,    :type => :boolean
      class_option :tiny,         :desc => "Generate tiny app skeleton",                    :aliases => '-i', :default => false,    :type => :boolean
      class_option :adapter,      :desc => "SQL adapter for ORM (sqlite, mysql, postgres)", :aliases => '-a', :default => "sqlite", :type => :string
      class_option :template,     :desc => "Generate project from template",                :aliases => '-p', :default => nil,      :type => :string

      # Definitions for the available customizable components
      component_option :orm,        "database engine",    :aliases => '-d', :choices => [:activerecord, :datamapper, :mongomapper, :mongoid, :sequel, :couchrest, :ohm, :mongomatic], :default => :none
      component_option :test,       "testing framework",  :aliases => '-t', :choices => [:rspec, :shoulda, :cucumber, :bacon, :testspec, :riot], :default => :none
      component_option :mock,       "mocking library",    :aliases => '-m', :choices => [:mocha, :rr], :default => :none
      component_option :script,     "javascript library", :aliases => '-s', :choices => [:jquery, :prototype, :rightjs, :mootools, :extcore, :dojo], :default => :none
      component_option :renderer,   "template engine",    :aliases => '-e', :choices => [:haml, :erb, :erubis, :liquid], :default => :haml
      component_option :stylesheet, "stylesheet engine",  :aliases => '-c', :choices => [:less, :sass, :compass, :scss], :default => :none

      # Show help if no argv given
      require_arguments!

      # Copies over the Padrino base application App
      def setup_project
        @app_name = (options[:app] || name).gsub(/\W/, "_").underscore.camelize
        self.destination_root = File.join(options[:root], name)
        if options[:template] # Run the template to create project
          execute_runner(:template, options[:template])
        else # generate project without template
          directory("project/", destination_root)
          app_skeleton('app', options[:tiny])
          store_component_config('.components')
          template "templates/Gemfile.tt", destination_root("Gemfile")
        end
      end

      # For each component, retrieve a valid choice and then execute the associated generator
      def setup_components
        return if options[:template]
        @_components = options.dup.slice(*self.class.component_types)
        self.class.component_types.each do |comp|
          choice = @_components[comp] = resolve_valid_choice(comp)
          execute_component_setup(comp, choice)
        end
        store_component_config('.components')
      end

      # Bundle all required components using bundler and Gemfile
      def bundle_dependencies
        if options[:bundle]
          run_bundler
        end
      end

      # Finish message
      def finish_message
        if options[:bundle]
          text = (<<-TEXT).gsub(/ {10}/,'')

          =================================================================
          #{name} is ready for development! Next, follow these steps:
          =================================================================
          1) cd #{name}
          =================================================================

          TEXT
        else
          text = (<<-TEXT).gsub(/ {10}/,'')

          =================================================================
          #{name} is ready for development! Next, follow these steps:
          =================================================================
          1) cd #{name}
          2) bundle install
          =================================================================

          TEXT
        end
        say(text)
      end
    end # Project
  end # Generators
end # Padrino
