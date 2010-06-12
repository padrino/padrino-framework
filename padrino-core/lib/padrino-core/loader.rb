module Padrino
  class << self
    ##
    # Requires necessary dependencies as well as application files from root lib and models
    #
    def load!
      return false if loaded?
      @_called_from = first_caller
      set_encoding
      set_load_paths(*load_paths) # We set the padrino load paths
      dependency_paths.each { |path| require_dependency(path) }
      Reloader::Stat.run! # We need to fill our Stat::CACHE
      Padrino.logger # Initialize our logger
      Thread.current[:padrino_loaded] = true
    end

    ##
    # Method for reloading required applications and their files
    #
    def reload!
      Reloader::Stat.reload! # detects the modified files
    end

    ##
    # This adds the ablity to instantiate Padrino.load! after Padrino::Application definition.
    #
    def called_from
      @_called_from || first_caller
    end

    ##
    # Return true if Padrino was loaded with Padrino.load!
    #
    def loaded?
      Thread.current[:padrino_loaded]
    end

    ##
    # Attempts to require all dependency libs that we need.
    # If you use this method we can perform correctly a Padrino.reload!
    # Another good thing that this method are dependency check, for example:
    #
    #   models
    #    \-- a.rb => require something of b.rb
    #    \-- b.rb
    #
    # In the example above if we do:
    #
    #   Dir["/models/*.rb"].each { |r| require r }
    #
    # we get an error, because we try to require first a.rb that need +something+ of b.rb.
    #
    # With +require_dependencies+ we don't have this problem.
    #
    # ==== Examples
    #   # For require all our app libs we need to do:
    #   require_dependencies("#{Padrino.root}/lib/**/*.rb")
    #
    def require_dependencies(*paths)
      # Extract all files to load
      files = paths.map { |path| Dir[path] }.flatten

      while files.present?
        # We need a size to make sure things are loading
        size_at_start = files.size

        # List of errors and failed files
        errors, failed = [], []

        # Now we try to require our dependencies
        files.each do |file|
          begin
            Reloader::Stat.safe_load(file)
            files.delete(file)
          rescue Exception => e
            errors << e
            failed << files
          end
        end

        # Stop processing if nothing loads or if everything has loaded
        raise errors.last if files.size == size_at_start && files.present?
        break if files.empty?
      end
    end
    alias :require_dependency :require_dependencies

    ##
    # Returns default list of path globs to load as dependencies
    #
    def dependency_paths
      # Load db adapter, libs, root models, app configuration
      @dependency_paths ||= [
        "#{root}/config/database.rb", "#{root}/lib/**/*.rb", "#{root}/shared/lib/**/*.rb",
        "#{root}/models/**/*.rb", "#{root}/shared/models/**/*.rb", @custom_dependencies,
        "#{root}/config/apps.rb"
      ].flatten.compact
    end

    ##
    # Appends custom dependency patterns to the be loaded for Padrino
    # ==== Examples
    #    Padrino.custom_dependencies("#{Padrino.root}/foo/bar/*.rb")
    #
    def custom_dependencies(*globs)
      @custom_dependencies ||= []
      @custom_dependencies.concat(globs)
    end

    ##
    # Attempts to load all dependency libs that we need.
    # If you use this method we can perform correctly a Padrino.reload!
    #
    def load_dependencies(*paths)
      paths.each do |path|
        FileSet.glob(path) { |file| load(file) }
      end
    end
    alias :load_dependency :load_dependencies

    ##
    # Concat to $LOAD_PATH the given paths
    #
    def set_load_paths(*paths)
      $:.concat(paths)
      $:.uniq!
    end
  end # self
end # Padrino
