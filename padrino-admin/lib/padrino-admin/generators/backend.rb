require 'thor'
require 'padrino-gen' unless defined?(Padrino::Generators)
module Padrino
  module Generators

    class Backend < Thor::Group

      # Add this generator to our padrino-gen
      Padrino::Generators.add_generator(:backend, self)

      # Define the source template root
      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      def self.banner; "padrino-gen controller [name]"; end

      # Include related modules
      include Thor::Actions
      include Padrino::Generators::Actions

      desc "Description:\n\n\tpadrino-gen controller generates a new Padrino Admin"

      class_option :root, :aliases => '-r', :default => nil, :type => :string
    end

  end
end