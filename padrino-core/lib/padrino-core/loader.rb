module Padrino
  class << self
    # Requires necessary dependencies as well as application files from root lib and models
    def load!
      load_required_gems # load bundler gems
      load_dependencies("#{root}/config/apps.rb", "#{root}/config/database.rb")
      load_dependencies("#{root}/lib/**/*.rb", "#{root}/models/*.rb") # load root app dependencies
      reload! # We need to fill our Stat::CACHE but we do that only for development
    end

    # Method for reload required classes
    def reload!
      Stat::reload!
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

    # Attempts to require all dependencies with bundler; if fails, we try to use system wide gems
    def load_required_gems
      begin
        require 'bundler'
        gemfile_path = root("Gemfile")
        puts "=> Loading GemFile #{gemfile_path} for #{PADRINO_ENV}"
        Bundler::Environment.load(gemfile_path).require_env(PADRINO_ENV)
      rescue Bundler::DefaultManifestNotFound => e
        puts "=> You didn't create Bundler Gemfile manifest or you are not in a Sinatra application."
      end

      begin
        load_dependencies(root('/../vendor', 'gems', PADRINO_ENV))
        puts "=> Using bundled gems"
      rescue LoadError => e
        puts "=> Using system wide gems (No bundled gems)"
      end
    end
  end
end