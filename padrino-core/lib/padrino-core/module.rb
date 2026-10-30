module Padrino
  module Module
    attr_writer :root

    ##
    # Register this module as being loaded from a gem. This automatically
    # sets the root and therefore the dependency paths correctly.
    #
    # @param [String] name
    #   The name of the gem. Has to be the name as stated in the gemspec.
    #
    # @returns the gems root.
    def gem!(name)
      self.root = Padrino.gem(name, self)
    end

    ##
    # Helper method for file references within a Padrino module.
    #
    # @param [Array<String>] args
    #   The directories to join to {Module.root}.
    #
    # @return [String]
    #   The absolute path.
    #
    # @example
    #   module MyModule
    #     extend Padrino::Module
    #     gem! 'my_gem'
    #   end
    #   Module.root!
    def root(*args)
      File.expand_path(File.join(@root, *args))
    end

    ##
    # Returns the path globs of the module's files to load as dependencies. The list
    # is built again on each call, so appending to it has no effect; to load more
    # files, override the method and add globs to +super+.
    #
    # @return [Array<String>]
    #   The dependency paths.
    #
    # @example
    #   module MyModule
    #     extend Padrino::Module
    #     gem! 'my_gem'
    #
    #     def self.dependency_paths
    #       super + ["#{root}/uploaders/*.rb"]
    #     end
    #   end
    #
    def dependency_paths
      [
        "#{root}/lib/**/*.rb", "#{root}/shared/lib/**/*.rb",
        "#{root}/models/**/*.rb", "#{root}/shared/models/**/*.rb"
      ]
    end
  end
end
