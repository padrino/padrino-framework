require 'padrino-core/cli/base' unless defined?(Padrino::Cli::Base)

module Padrino
  module Generators
    class Plugin < Thor::Group
      PLUGIN_URL = 'http://github.com/padrino/padrino-recipes/tree/master/plugins'
      # Add this generator to our padrino-gen
      Padrino::Generators.add_generator(:plugin, self)

      # Define the source plugin root
      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      def self.banner; "padrino-gen plugin [plugin_identifier] [options]"; end

      # Include related modules
      include Thor::Actions
      include Padrino::Generators::Actions
      include Padrino::Generators::Runner

      desc "Description:\n\n\tpadrino-gen plugin sets up a plugin within a Padrino application"

      argument :plugin_file, :desc => "The name or path to the Padrino plugin", :optional => true

      class_option :root, :desc => "The root destination", :aliases => '-r', :default => ".",   :type => :string
      class_option :list, :desc => "list available plugins", :aliases => '-l', :default => false, :type => :boolean
      class_option :destroy, :aliases => '-d', :default => false, :type => :boolean
      # Show help if no argv given
      require_arguments!

      # Create the Padrino Plugin
      def setup_plugin
        if options[:list] # list method ran here
          plugins = open(PLUGIN_URL).read.scan(%r{/plugins/(\w+)_plugin.rb}).uniq
          say "Available plugins:", :green
          say plugins.map { |plugin| "  - #{plugin}" }.join("\n")
        else # executing the plugin instructions
          self.behavior = :revoke if options[:destroy]
          self.destination_root = options[:root]
          execute_runner(:plugin, plugin_file)
        end
      end
    end # Plugins
  end # Generators
end # Padrino
