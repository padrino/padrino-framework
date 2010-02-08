module Padrino
  module Generators
    class App < Thor::Group

      # Add this generator to our padrino-gen
      Padrino::Generators.add_generator(:app, self)

      # Define the source template root
      def self.source_root; File.dirname(__FILE__); end
      def self.banner; "padrino-gen project [name] [options]"; end

      # Include related modules
      include Thor::Actions
      include Padrino::Generators::Actions
      include Padrino::Generators::Components::Actions

      desc "Description:\n\n\tpadrino-gen project generates a new Padrino project"

      argument :name, :desc => "The name of your padrino project"

      class_option :run_bundler, :aliases => '-b', :default => false, :type => :boolean
      class_option :root, :desc => "The root destination",        :aliases => '-r', :default => ".",   :type => :string

      # Definitions for the available customizable components
      component_option :orm,      "database engine",    :aliases => '-d', :choices => [:datamapper, :mongomapper, :activerecord, :sequel, :couchrest]
      component_option :test,     "testing framework",  :aliases => '-t', :choices => [:bacon, :shoulda, :rspec, :testspec, :riot]
      component_option :mock,     "mocking library",    :aliases => '-m', :choices => [:mocha, :rr]
      component_option :script,   "javascript library", :aliases => '-s', :choices => [:jquery, :prototype, :rightjs]
      component_option :renderer, "template engine",    :aliases => '-e', :choices => [:erb, :haml]

      # Show help if no argv given
      def self.start(given_args=ARGV, config={})
        given_args = ["-h"] if given_args.empty?
        super
      end

      # Copies over the Padrino base application App
      def setup_app
        @class_name = name.underscore.classify
        self.destination_root = File.join(options[:root], name)
        directory("app/", destination_root)
        store_component_config('.components')
        template "templates/Gemfile.tt", destination_root("Gemfile")
      end

      # For each component, retrieve a valid choice and then execute the associated generator
      def setup_components
        self.class.component_types.each do |comp|
          choice = resolve_valid_choice(comp)
          execute_component_setup(comp, choice)
        end
      end

      # Bundle all required components using bundler and Gemfile
      def bundle_dependencies
        if options[:run_bundle]
          say "Bundling application dependencies using bundler..."
          in_root { run 'bundle install' }
        end
      end
    end
  end
end
