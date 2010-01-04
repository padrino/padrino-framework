module Padrino
  class << self
    # Requires necessary dependencies as well as application files from root lib and models
    def load!
      return false if loaded?
      @_called_from = first_caller
      load_required_gems # load bundler gems
      require_dependencies("support_lite") # after we load the gem file we can know wich suport load
      require_dependencies("#{root}/config/apps.rb", "#{root}/config/database.rb") # load configuration
      require_dependencies("#{root}/lib/**/*.rb", "#{root}/models/*.rb") # load root app dependencies
      Stat.reload! # We need to fill our Stat::CACHE but we do that only for development
      Thread.current[:padrino_loaded] = true
    end

    # Method for reloading required applications and their files
    def reload!
      return unless Stat.changed?
      Stat.reload! # detects the modified files
      Padrino.mounted_apps.each { |m| m.app_object.reload! } # finally we reload all files for each app
    end

    # This adds the ablity to instantiate Padrino.load! after Padrino::Application definition.
    def called_from
      @_called_from || first_caller
    end

    # Return true if Padrino was loaded with Padrino.load!
    def loaded?
      Thread.current[:padrino_loaded]
    end

    # Attempts to require all dependency libs that we need.
    # If you use this method we can perform correctly a Padrino.reload!
    #
    # ==== Parameters
    # paths:: Path where is necessary require a dependency
    #
    # Example:
    #   # For require all our app libs we need to do:
    #   require_dependencies("#{Padrino.root}/lib/**/*.rb")
    def require_dependencies(*paths)
      paths.each do |path|
        Dir[path].each { |file| require(file) }
      end
    end
    alias :require_dependency :require_dependencies

    # Attempts to load all dependency libs that we need.
    # If you use this method we can perform correctly a Padrino.reload!
    #
    # ==== Parameters
    # paths:: Path where is necessary to load a dependency
    def load_dependencies(*paths)
      paths.each do |path|
        Dir[path].each { |file| load(file) }
      end
    end
    alias :load_dependency :load_dependencies

    protected

    # Loads the vendored gems or system wide gems through Gemfile
    def load_required_gems
      require root('vendor', 'gems', 'environment')
      Bundler.require_env(Padrino.env)
      say! "=> Loaded bundled gems"
    rescue LoadError
      require 'bundler'
      say "=> Locating Gemfile for #{Padrino.env}"
      if File.exist?(root("Gemfile"))
        Bundler::Dsl.load_gemfile(root("Gemfile")).require_env(Padrino.env)
        say! " ... Loaded system gems"
      else
        say! " ... Not Found"
      end
    end

    # Prints out a message to the stdout if not in test environment
    def say(text)
      print text if Padrino.env != :test
    end
    
    # Puts out a message to the stdout if not in test environment
    def say!(text)
      puts text if Padrino.env != :test
    end
  end
end
