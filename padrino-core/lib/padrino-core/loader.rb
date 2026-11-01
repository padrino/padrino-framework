require 'monitor'

module Padrino
  module Loader
    # The loaded state and the lock that guards it belong to the extending module (Padrino),
    # so every thread sees the same state. Extending again keeps them.
    def self.extended(base)
      return if base.instance_variable_defined?(:@_load_lock)
      base.instance_variable_set(:@_load_lock, Monitor.new)
      base.instance_variable_set(:@_loaded, false)
      base.instance_variable_set(:@_loading_thread, nil)
    end

    ##
    # Hooks to be called before a load/reload.
    #
    # @yield []
    #   The given block will be called before Padrino was loaded/reloaded.
    #
    # @return [Array<Proc>]
    #   The load/reload before hooks.
    #
    # @example
    #   before_load do
    #     pre_initialize_something
    #   end
    #
    def before_load(&block)
      @_before_load ||= []
      @_before_load << block if block_given?
      @_before_load
    end

    ##
    # Hooks to be called after a load/reload.
    #
    # @yield []
    #   The given block will be called after Padrino was loaded/reloaded.
    #
    # @return [Array<Proc>]
    #   The load/reload hooks.
    #
    # @example
    #   after_load do
    #     SomeORM.finalize
    #   end
    #
    def after_load(&block)
      @_after_load ||= []
      @_after_load << block if block_given?
      @_after_load
    end

    ##
    # Requires necessary dependencies as well as application files from root
    # lib and models.
    #
    # Calls from other threads while it loads wait for it to finish, then return false.
    # If it raised, the next waiting caller runs the load instead.
    # A call made while loading, from the loading thread (in any fiber), returns false.
    #
    # @return [Boolean]
    #   returns true if Padrino is not already bootstraped otherwise else.
    #
    def load!
      return false if @_loaded || @_loading_thread == Thread.current
      @_load_lock.synchronize do
        return false if @_loaded
        @_loading_thread = Thread.current
        begin
          began_at = Time.now
          @_called_from = first_caller
          Padrino.logger
          Reloader.lock!
          before_load.each(&:call)
          require_dependencies(*dependency_paths)
          after_load.each(&:call)
          logger.devel "Loaded Padrino in #{Time.now - began_at} seconds"
          precompile_all_routes!
          @_loaded = true
        ensure
          @_loading_thread = nil
        end
      end
    end

    ##
    # Precompiles all routes if :precompile_routes is set to true
    #
    def precompile_all_routes!
      mounted_apps.each do |app|
        app_obj = app.app_obj
        next unless app_obj.respond_to?(:precompile_routes?) && app_obj.precompile_routes?
        app_obj.setup_application!
        logger.devel "Precompiled routes of #{app_obj} (routes size #{app_obj.compiled_router.routes.size})"
      end
    end

    ##
    # Clear the padrino env.
    #
    # @return [NilClass]
    #
    def clear!
      @_load_lock.synchronize do
        clear_middleware!
        mounted_apps.clear
        @_dependency_paths = nil
        before_load.clear
        after_load.clear
        global_configurations.clear
        Reloader.clear!
        @_loaded = false
      end
      nil
    end

    ##
    # Method for reloading required applications and their files.
    #
    def reload!
      return unless Reloader.changed?
      before_load.each(&:call)
      Reloader.reload!
      after_load.each(&:call)
    end

    ##
    # This adds the ability to instantiate {Padrino.load!} after
    # {Padrino::Application} definition.
    #
    def called_from
      @_called_from || first_caller
    end

    ##
    # Determines whether Padrino was loaded with {Padrino.load!}.
    #
    # It takes no lock, so it's safe from a trap handler; it reads false while a load is
    # still running.
    #
    # @return [Boolean]
    #   Specifies whether Padrino was loaded, in any thread.
    #
    def loaded?
      @_loaded
    end

    ##
    # Attempts to require all dependency libs that we need.
    # If you use this method we can perform correctly a Padrino.reload!
    # Another good thing that this method are dependency check, for example:
    #
    #   # models
    #   #  \-- a.rb => require something of b.rb
    #   #  \-- b.rb
    #
    # In the example above if we do:
    #
    #   Dir["/models/*.rb"].each { |r| require r }
    #
    # We get an error, because we try to require first +a.rb+ that need
    # _something_ of +b.rb+.
    #
    # With this method we don't have this problem.
    #
    # @param [Array<String>] paths
    #   The paths to require.
    #
    # @example For require all our app libs we need to do:
    #   require_dependencies("#{Padrino.root}/lib/**/*.rb")
    #
    def require_dependencies(*paths)
      options = { cyclic: true }.update(paths.last.is_a?(Hash) ? paths.pop : {})

      files = paths.flatten.flat_map { |path| Dir.glob(path).sort_by { |filename| filename.count('/') } }.uniq

      until files.empty?
        error = fatal = loaded = nil

        files.dup.each do |file|
          Reloader.enabled? || options[:force] ? Reloader.safe_load(file, options) : Reloader.untracked_load(file)
          files.delete(file)
          loaded = true
        rescue NameError, LoadError => error
          raise if Reloader.exclude.any? { |path| file.start_with?(path) } || options[:cyclic] == false
          logger.devel "Cyclic dependency reload for #{error.class}: #{error.message}"
        rescue Exception => fatal
          break
        end

        next unless fatal || !loaded
        exception = fatal || error
        logger.exception exception, :short
        raise exception
      end
    end

    ##
    # Returns default list of path globs to load as dependencies.
    # Appends custom dependency patterns to the be loaded for Padrino.
    #
    # @return [Array<String>]
    #   The dependencey paths.
    #
    # @example
    #   Padrino.dependency_paths << "#{Padrino.root}/uploaders/*.rb"
    #
    def dependency_paths
      @_dependency_paths ||= default_dependency_paths + modules_dependency_paths
    end

    private

    def modules_dependency_paths
      modules.map(&:dependency_paths).flatten
    end

    def default_dependency_paths
      @default_dependency_paths ||= [
        "#{root}/config/database.rb",
        "#{root}/lib/**/*.rb",
        "#{root}/models/**/*.rb",
        "#{root}/shared/**/*.rb",
        "#{root}/config/apps.rb"
      ]
    end
  end
end
