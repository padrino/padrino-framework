module Padrino
  class << self
    attr_reader :loaded, :called_from
    alias_method :loaded?, :loaded

    # Requires necessary dependencies as well as application files from root lib and models
    def load!
      return if loaded?
      @called_from = caller_files.first
      load_required_gems # load bundler gems
      load_dependencies("#{root}/config/apps.rb", "#{root}/config/database.rb") # load configuration
      load_dependencies("#{root}/lib/**/*.rb", "#{root}/models/*.rb") # load root app dependencies
      reload! # We need to fill our Stat::CACHE but we do that only for development
      @loaded = true
    end

    # Attempts to require all dependencies with bundler; if this fails, uses system wide gems
    def load_required_gems
      load_bundler_manifest
      require_vendored_gems
    end

    # Attempts to load/require all dependency libs that we need.
    # If you use this method we can perform correctly a Padrino.reload!
    #
    # @param paths [Array] Path where is necessary require or load a dependency
    # @example For load all our app libs we need to do:
    #   load_dependencies("#{Padrino.root}/lib/**/*.rb")
    def load_dependencies(*paths)
      paths.each do |path|
        Dir[path].each { |file| require(file) }
      end
    end
    alias_method :load_dependency, :load_dependencies

    # Method for reload required classes
    def reload!
      Stat::reload!
    end

    protected

    # Loads the bundler manifest Gemfile if it exists
    def load_bundler_manifest
      require 'bundler'
      print "=> Locating Gemfile for #{PADRINO_ENV}"
      Bundler::Environment.load(root("Gemfile")).require_env(PADRINO_ENV)
      print " ... Loaded!"
    rescue Bundler::ManifestFileNotFound, Bundler::DefaultManifestNotFound => e
      print " ... Not Found"
    end

    # Loads bundled gems if they exist
    def require_vendored_gems
      load_dependencies(root('/../vendor', 'gems', PADRINO_ENV))
      puts " (Loading bundled gems)"
    rescue LoadError => e
      puts " (Loading system gems)"
    end
  end
end
