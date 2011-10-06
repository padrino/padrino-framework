require 'padrino-core/support_lite'
require 'padrino-core/tasks'
require 'padrino-core/command'
require 'active_support/ordered_hash'

module Padrino
  ##
  # This method return the correct location of padrino-gen bin or
  # exec it using Kernel#system with the given args
  #
  # @param [Array<String>] args
  #   Splat of arguments to pass to padrino-gen
  #
  # @example
  #   Padrino.bin_gen(:app, name.to_s, "-r=#{destination_root}")
  #
  # @api semipublic
  def self.bin_gen(*args)
    @_padrino_gen_bin ||= [Padrino.ruby_command, File.expand_path("../../bin/padrino-gen", __FILE__)]
    args.empty? ? @_padrino_gen_bin : system(args.unshift(@_padrino_gen_bin).join(" "))
  end

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
      # Gloabl add a new generator class to +padrino-gen+
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
# We add our generators to Padrino::Genererator
#
Padrino::Generators.load_paths << Dir[File.dirname(__FILE__) + '/padrino-gen/generators/{project,app,mailer,controller,model,migration,plugin}.rb']

##
# We add our tasks to padrino-core
#
Padrino::Tasks.files << Dir[File.dirname(__FILE__) + "/padrino-gen/padrino-tasks/**/*.rb"]
