require 'padrino-core/support_lite'
require 'padrino-core/tasks'
require 'padrino-gen/command'
require 'active_support/ordered_hash'

module Padrino
  ##
  # This module it's used for register generators
  #
  # Can be useful for 3rd party generators:
  #
  #   # custom_generator.rb
  #   class CustomGenerator < Thor::Group
  #     Padrino::Generators.add_generator(:custom_generator, self)
  #   end
  #
  # Now for handle generators in padrino you need to add it to into +load_paths+
  #
  # Padrino::Generators.load_paths << "custom_generator.rb"
  #
  module Generators
    # Defines the absolute path to the padrino source folder
    DEV_PATH = File.expand_path("../../", File.dirname(__FILE__))

    class << self
      ##
      # Here we store our generators paths
      #
      # @api semipublic
      def load_paths
        @_files ||= []
      end

      ##
      # Return a ordered list of task with their class
      #
      # @api semipublic
      def mappings
        @_mappings ||= ActiveSupport::OrderedHash.new
      end

      ##
      # Global add a new generator class to +padrino-gen+
      #
      # @param [Symbol] name
      #   key name for generator mapping
      # @param [Class] klass
      #   class of generator
      #
      # @return [Hash] generator mappings
      #
      # @example
      #   Padrino::Generators.add_generator(:controller, Controller)
      #
      # @api semipublic
      def add_generator(name, klass)
        mappings[name] = klass
      end

      ##
      # Load Global Actions and Component Actions then all files in +load_path+.
      #
      # @api private
      def load_components!
        require 'padrino-gen/generators/actions'
        require 'padrino-gen/generators/components/actions'
        require 'padrino-gen/generators/runner'
        load_paths.flatten.each { |file| require file  }
      end
    end
  end # Generators
end # Padrino

##
# We add our generators to Padrino::Generators
#
Padrino::Generators.load_paths << Dir[File.dirname(__FILE__) + '/padrino-gen/generators/{project,app,mailer,controller,model,migration,plugin}.rb']

##
# We add our tasks to padrino-core
#
Padrino::Tasks.files << Dir[File.dirname(__FILE__) + "/padrino-gen/padrino-tasks/**/*.rb"]
