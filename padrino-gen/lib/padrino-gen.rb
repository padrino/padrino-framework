require 'padrino-core/tasks'
require 'padrino-core/command'

module Padrino
  ##
  # This method return the correct location of padrino-gen bin or
  # exec it using Kernel#system with the given args
  #
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

    DEV_PATH = File.expand_path("../../", File.dirname(__FILE__))

    class << self
      ##
      # Here we store our generators paths
      #
      def load_paths
        @_files ||= []
      end

      ##
      # Return a ordered list of task with their class
      #
      def mappings
        @_mappings ||= ActiveSupport::OrderedHash.new
      end

      ##
      # Gloabl add a new generator class to +padrino-gen+
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