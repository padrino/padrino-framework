require 'padrino-core/version'
require 'securerandom' unless defined?(SecureRandom)

module Padrino
  module Generators
    ##
    # Responsible for generating new Padrino projects based on the specified project components.
    #
    class Project < Thor::Group

      # Add this generator to our padrino-gen
      Padrino::Generators.add_generator(:project, self)

      # Define the source template root
      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      # Defines the banner for this CLI generator
      def self.banner; "padrino-gen project [name] [options]"; end

      # Include related modules
      include Thor::Actions
      include Padrino::Generators::Actions
      include Padrino::Generators::Runner
      include Padrino::Generators::Components::Actions

      desc "Description:\n\n\tpadrino-gen project generates a new Padrino project"

      argument :name, :desc => "The name of your padrino project"

      class_option :app ,         :desc => "The application name",                                  :aliases => '-n', :default => nil,      :type => :string
      class_option :bundle,       :desc => "Run bundle install",                                    :aliases => '-b', :default => false,    :type => :boolean
      class_option :root,         :desc => "The root destination",                                  :aliases => '-r', :default => ".",      :type => :string
      class_option :dev,          :desc => "Use padrino from a git checkout",                                         :default => false,    :type => :boolean
      class_option :tiny,         :desc => "Generate tiny app skeleton",                            :aliases => '-i', :default => false,    :type => :boolean
      class_option :adapter,      :desc => "SQL adapter for ORM (sqlite, mysql, mysql2, postgres)", :aliases => '-a', :default => "sqlite", :type => :string
      class_option :template,     :desc => "Generate project from template",                        :aliases => '-p', :default => nil,      :type => :string

      # Definitions for the available customizable components
      component_option :orm,        "database engine",    :aliases => '-d', :choices => [:activerecord, :datamapper, :mongomapper, :mongoid, :sequel, :couchrest, :ohm, :mongomatic, :ripple], :default => :none
      component_option :test,       "testing framework",  :aliases => '-t', :choices => [:rspec, :shoulda, :cucumber, :bacon, :testspec, :riot, :minitest], :default => :none
      component_option :mock,       "mocking library",    :aliases => '-m', :choices => [:mocha, :rr], :default => :none
      component_option :script,     "javascript library", :aliases => '-s', :choices => [:jquery, :prototype, :rightjs, :mootools, :extcore, :dojo], :default => :none
      component_option :renderer,   "template engine",    :aliases => '-e', :choices => [:haml, :erb, :liquid, :slim], :default => :haml
      component_option :stylesheet, "stylesheet engine",  :aliases => '-c', :choices => [:less, :sass, :compass, :scss], :default => :none

      # Show help if no argv given
      require_arguments!

      # Copies over the Padrino base application App
      #
      # @api private
      def setup_project
        valid_constant?(options[:app] || name)
        @app_name = (options[:app] || name).gsub(/\W/, "_").underscore.camelize
        self.destination_root = File.join(options[:root], name)
        if options[:template] # Run the template to create project
          execute_runner(:template, options[:template])
        else # generate project without template
          directory("project/", destination_root)
          empty_directory destination_root("public/images")
          empty_directory destination_root("public/javascripts")
          empty_directory destination_root("public/stylesheets")
          empty_directory destination_root("tmp")
          store_component_config('.components')
          app_skeleton('app', options[:tiny])
          template "templates/Gemfile.tt", destination_root("Gemfile")
        end
      end

      # For each component, retrieve a valid choice and then execute the associated generator
      #
      # @api private
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
      #
      # @api private
      def bundle_dependencies
        if options[:bundle]
          run_bundler
        end
      end

      # Finish message
      #
      # @api private
      def finish_message
        say
        say "="*65, :green
        say "#{name} is ready for development!", :green
        say "="*65, :green
        say "$ cd #{options[:root]}/#{name}"
        say "$ bundle install" unless options[:bundle]
        say "="*65, :green
        say
      end
    end # Project
  end # Generators
end # Padrino
