module Padrino
  class << self
    ##
    # Requires necessary dependencies as well as application files from root lib and models
    # 
    def load!
      return false if loaded?
      @_called_from = first_caller
      set_encoding
      set_load_paths(*load_paths) # we set the padrino load paths
      require_dependencies("#{root}/lib/**/*.rb", "#{root}/shared/lib/**/*.rb") # load root libs
      require_dependencies("#{root}/models/**/*.rb", "#{root}/shared/models/**/*.rb") # load root models
      require_dependencies("#{root}/config/database.rb", "#{root}/config/apps.rb") # load configuration
      Reloader::Stat.reload! # We need to fill our Stat::CACHE but we do that only for development
      Thread.current[:padrino_loaded] = true
    end

    ##
    # Method for reloading required applications and their files
    # 
    def reload!
      return unless Reloader::Stat.changed?
      Reloader::Stat.reload! # detects the modified files
      Padrino.mounted_apps.each { |m| m.app_object.reload! } # finally we reload all files for each app
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
            require file
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
    # Attempts to load all dependency libs that we need.
    # If you use this method we can perform correctly a Padrino.reload!
    #
    def load_dependencies(*paths)
      paths.each do |path|
        Dir[path].each { |file| load(file) }
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
