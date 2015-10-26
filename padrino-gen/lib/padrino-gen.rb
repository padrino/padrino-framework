require 'padrino-core/tasks'
require 'padrino-gen/command'
require 'yaml'

module Padrino
  ##
  # This module it's used for register generators.
  #
  # Can be useful for 3rd party generators:
  #
  #   # custom_generator.rb
  #   class CustomGenerator < Thor::Group
  #     Padrino::Generators.add_generator(:custom_generator, self)
  #   end
  #
  # Now for handle generators in padrino you need to add it to into +load_paths+.
  #
  # Padrino::Generators.load_paths << "custom_generator.rb"
  #
  module Generators
    # Defines the absolute path to the padrino source folder.
    DEV_PATH = File.expand_path("../../", File.dirname(__FILE__))

    class << self
      ##
      # Store our generators paths.
      #
      def load_paths
        @_files ||= []
      end

      ##
      # Return an ordered list of task with their class.
      #
      def mappings
        @_mappings ||= {}
      end

      ##
      # Global add a new generator class to +padrino-gen+.
      #
      # @param [Symbol] name
      #   Key name for generator mapping.
      # @param [Class] klass
      #   Class of generator.
      #
      # @return [Hash] generator mappings
      #
      # @example
      #   Padrino::Generators.add_generator(:controller, Controller)
      #
      def add_generator(name, klass)
        mappings[name] = klass
      end

      ##
      # Load Global Actions and Component Actions then all files in +load_path+.
      #
      def load_components!
        require 'padrino-gen/generators/actions'
        require 'padrino-gen/generators/components/actions'
        require 'padrino-gen/generators/runner'
        load_paths.flatten.each { |file| require file  }
      end
    end
  end
end

# Add our generators to Padrino::Generators.
Padrino::Generators.load_paths << Dir[File.dirname(__FILE__) + '/padrino-gen/generators/{project,app,mailer,controller,helper,model,migration,plugin,component,task}.rb']

# Add our tasks to padrino-core.
Padrino::Tasks.files << Dir[File.dirname(__FILE__) + "/padrino-gen/padrino-tasks/**/*.rb"]
