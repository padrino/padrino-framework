require 'sinatra/base'
require 'padrino-core/version'
require 'padrino-support'
require 'padrino-support/inflections'
require 'padrino-core/configuration'
require 'padrino-core/application'

require 'padrino-core/caller'
require 'padrino-core/command'
require 'padrino-core/loader'
require 'padrino-core/logger'
require 'padrino-core/mounter'
require 'padrino-core/reloader'
require 'padrino-core/router'
require 'padrino-core/server'
require 'padrino-core/tasks'
require 'padrino-core/module'

if ENV['PADRINO_ENV'] || defined?(PADRINO_ENV)
  warn 'Environment variable PADRINO_ENV is deprecated. Please, use RACK_ENV.'
  ENV['RACK_ENV'] ||= ENV['PADRINO_ENV'] ||= PADRINO_ENV
end
RACK_ENV = ENV['RACK_ENV'] ||= 'development' unless defined?(RACK_ENV)
PADRINO_ROOT = ENV['PADRINO_ROOT'] ||= File.dirname(Padrino.first_caller) unless defined?(PADRINO_ROOT)

module Padrino
  class ApplicationLoadError < RuntimeError # @private
  end

  extend Configuration
  extend Loader

  class << self
    ##
    # Helper method for file references.
    #
    # @param [Array<String>] args
    #   The directories to join to {PADRINO_ROOT}.
    #
    # @return [String]
    #   The absolute path.
    #
    # @example
    #   # Referencing a file in config called settings.yml
    #   Padrino.root("config", "settings.yml")
    #   # returns PADRINO_ROOT + "/config/setting.yml"
    #
    def root(*args)
      File.expand_path(File.join(PADRINO_ROOT, *args))
    end

    ##
    # Helper method that return {RACK_ENV}.
    #
    # @return [Symbol]
    #   The Padrino Environment.
    #
    def env
      @_env ||= RACK_ENV.to_s.downcase.to_sym
    end

    ##
    # The resulting rack builder mapping each 'mounted' application.
    #
    # While reloading is enabled, every request, to any mounted app, runs in turn with code
    # reloads (see Reloader.serve).
    #
    # @return [#call]
    #   The Rack app: the router for the application, behind the middleware added with
    #   {Padrino.use}, and, while reloading is enabled, wrapped in a lambda that takes turns.
    #
    # @raise [ApplicationLoadError]
    #   No applications were mounted.
    #
    def application
      warn 'WARNING! No apps are mounted. Please, mount apps in `config/apps.rb`' if Padrino.mounted_apps.empty?
      router = Padrino::Router.new
      Padrino.mounted_apps.each { |app| app.map_onto(router) }
      warn_about_session_secret_in_source
      app = middleware.empty? ? router : add_middleware(router)
      Reloader.enabled? ? ->(env) { Reloader.serve { app.call(env) } } : app
    end

    ##
    # Configure Global Project Settings for mounted apps. These can be overloaded
    # in each individual app's own personal configuration. This can be used like:
    #
    # @yield []
    #   The given block will be called to configure each application.
    #
    # @example
    #   Padrino.configure_apps do
    #     enable  :sessions
    #     disable :raise_errors
    #   end
    #
    def configure_apps(&block)
      global_configurations << block if block_given?
    end

    ##
    # Stores global configuration blocks.
    #
    def global_configurations
      @_global_configurations ||= []
    end

    ##
    # Set +Encoding.default_internal+ and +Encoding.default_external+
    # to +Encoding::UFT_8+.
    #
    # Please note that in +1.9.2+ with some template engines like +haml+
    # you should turn off Encoding.default_internal to prevent problems.
    #
    # @see https://github.com/rtomayko/tilt/issues/75
    #
    # @return [NilClass]
    #
    def set_encoding
      # remove after 0.15
      warn 'Warning! Padrino.set_encoding is deprecated. Padrino no longer manages ruby default encodings'
      nil
    end

    ##
    # Creates Rack stack with the router added to the middleware chain.
    #
    def add_middleware(router)
      builder = Rack::Builder.new
      middleware.each { |mw, args, block| builder.use(mw, *args, &block) }
      builder.run(router)
      builder.to_app
    end

    ##
    # A Rack::Builder object that allows to add middlewares in front of all
    # Padrino applications.
    #
    # @return [Array<Array<Class, Array, Proc>>]
    #   The middleware classes.
    #
    def middleware
      @middleware ||= []
    end

    ##
    # Clears all previously configured middlewares.
    #
    # @return [Array]
    #   An empty array
    #
    def clear_middleware!
      @middleware = []
    end

    ##
    # Convenience method for adding a Middleware to the whole padrino app.
    #
    # @param [Class] m
    #   The middleware class.
    #
    # @param [Array] args
    #   The arguments for the middleware.
    #
    # @yield []
    #   The given block will be passed to the initialized middleware.
    #
    def use(middleware_class, *args, &block)
      middleware << [middleware_class, args, block]
    end

    ##
    # Registers a gem with padrino. This relieves the caller from setting up
    # loadpaths by itself and enables Padrino to look up apps in gem folder.
    #
    # The name given has to be the proper gem name as given in the gemspec.
    #
    # @param [String] name
    #   The name of the gem being registered.
    #
    # @param [Module] main_module
    #   The main module of the gem.
    #
    # @returns The root path of the loaded gem
    def gem(name, main_module)
      _, spec = Gem.loaded_specs.find { |spec_pair| spec_pair[0] == name }
      gems << spec
      modules << main_module
      spec.full_gem_path
    end

    ##
    # @returns [Gem::Specification]
    def gems
      @gems ||= []
    end

    ##
    # @returns [<Padrino::Module>]
    def modules
      @modules ||= []
    end

    private

    ##
    # Warns once per process (until Padrino.clear!) when a mounted app runs in
    # production with sessions on and a session secret it uses appears as a
    # quoted string in config/apps.rb or in the app's file, such as the fallback
    # generated projects write.
    #
    # ceiling: checks only config/apps.rb and each app's file, for quoted string
    # literals only, and only apps booted through Padrino.application; checking
    # other committed config files would widen it. Only `sessions: { use: ... }`
    # is recognised as a store that may take no secret, so an app that sets
    # `set :session_store, Rack::Session::Pool` (or another store without a
    # secret) still warns.
    #
    def warn_about_session_secret_in_source
      return if @_session_secret_warned || env != :production

      sources = Hash.new do |cache, path|
        cache[path] = File.file?(path) ? File.binread(path) : ''
      rescue SystemCallError
        cache[path] = ''
      end
      path = mounted_apps.lazy.map { |app| session_secret_source(app.app_obj, sources) }.find(&:itself)
      return unless path

      @_session_secret_warned = true
      warn <<~WARNING
        WARNING! The session secret appears in #{path.delete_prefix("#{root}/")}.
        Use a secret that isn't in the source: set the SESSION_SECRET environment variable to a new value (`padrino rake secret` prints one).
        If that file doesn't read SESSION_SECRET yet, change the line to:

            set :session_secret, ENV.fetch('SESSION_SECRET') { 'current value' }
      WARNING
    end

    ##
    # Returns the file in which one of the app's session secrets appears as a
    # quoted string, or nil. +sources+ caches each file's contents.
    #
    def session_secret_source(app, sources)
      literals = session_secrets(app).flat_map { |secret| ["'#{secret}'".b, %("#{secret}").b] }
      return if literals.empty?

      [root('config', 'apps.rb'), app.app_file].compact.uniq.find do |path|
        literals.any? { |literal| sources[path].include?(literal) }
      end
    end

    ##
    # Returns the secrets the app's session store is given: :secret and :secrets
    # from the store's config with `use:`, otherwise from the sessions options,
    # where :secret defaults to the session_secret setting.
    #
    def session_secrets(app)
      return [] unless app.respond_to?(:sessions?) && app.sessions?

      options = app.sessions.is_a?(Hash) ? app.sessions : {}
      if options[:use]
        options = options[:config] || {}
        secret = options[:secret]
      else
        secret = options.fetch(:secret) { app.session_secret }
      end
      [secret, *options[:secrets]].select { |value| value.is_a?(String) && !value.empty? }
    end
  end
end
