require 'thor'

module Padrino
  module Generators
    class Skeleton < Thor::Group
      # Define the source template root
      def self.source_root; File.dirname(__FILE__); end
      def self.banner; "padrino-gen project [name] [path] [options]"; end

      # Include related modules
      include Thor::Actions
      include Padrino::Generators::Actions
      include Padrino::Generators::Components::Actions

      desc "Description:\n\n\tpadrino-gen project generates a new Padrino project"

      argument :name, :desc => "The name of your padrino project"
      argument :path, :desc => "The path to create your padrino project"
      class_option :run_bundler, :aliases => '-b', :default => false, :type => :boolean

      # Definitions for the available customizable components
      component_option :orm,      "database engine",    :aliases => '-d', :choices => [:datamapper, :mongomapper, :activerecord, :sequel, :couchrest]
      component_option :test,     "testing framework",  :aliases => '-t', :choices => [:bacon, :shoulda, :rspec, :testspec, :riot]
      component_option :mock,     "mocking library",    :aliases => '-m', :choices => [:mocha, :rr]
      component_option :script,   "javascript library", :aliases => '-s', :choices => [:jquery, :prototype, :rightjs]
      component_option :renderer, "template engine",    :aliases => '-r', :choices => [:erb, :haml]

      # Copies over the base sinatra starting project
      def setup_skeleton
        self.destination_root = File.join(path, name)
        @class_name = name.classify
        directory("skeleton/", self.destination_root)
        store_component_config('.components')
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
          in_root { run 'gem bundle' }
        end
      end
    end
  end
end
