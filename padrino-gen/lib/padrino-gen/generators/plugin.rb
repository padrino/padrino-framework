require 'padrino-core/cli/base' unless defined?(Padrino::Cli::Base)
require 'net/https'

module Padrino
  module Generators
    ##
    # Responsible for executing plugins instructions within a Padrino project.
    #
    class Plugin < Thor::Group
      # Defines the default URL for official padrino recipe plugins
      PLUGIN_URL = 'https://github.com/padrino/padrino-recipes/tree/master/plugins'
      # Add this generator to our padrino-gen
      Padrino::Generators.add_generator(:plugin, self)

      # Define the source plugin root
      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      # Defines the banner for this CLI generator
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
      #
      # @api private
      def setup_plugin
        if options[:list] # list method ran here
          plugins = {}
          uri = URI.parse(PLUGIN_URL)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true if uri.scheme == "https"
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          http.start do
            http.request_get(uri.path) do |res|
              plugins = res.body.scan(%r{/plugins/(\w+)_plugin.rb}).uniq
            end
          end
          say "Available plugins:", :green
          say plugins.map { |plugin| "  - #{plugin}" }.join("\n")
        else # executing the plugin instructions
          if in_app_root?
            self.behavior = :revoke if options[:destroy]
            self.destination_root = options[:root]
            execute_runner(:plugin, plugin_file)
          else
            say "You are not at the root of a Padrino application! (config/boot.rb not found)"
          end
        end
      end
    end # Plugins
  end # Generators
end # Padrino
