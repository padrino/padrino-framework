require 'pathname'
require 'padrino-core/reloader/rack'
require 'padrino-core/reloader/storage'

module Padrino
  ##
  # High performance source code reloader middleware
  #
  module Reloader
    ##
    # This reloader is suited for use in a many environments because each file
    # will only be checked once and only one system call to stat(2) is made.
    #
    # Please note that this will not reload files in the background, and does so
    # only when explicitly invoked.
    #
    extend self

    # The modification times for every file in a project.
    MTIMES = {}

    ##
    # Specified folders can be excluded from the code reload detection process.
    # Default excluded directories at Padrino.root are: test, spec, features, tmp, config, db and public
    #
    def exclude
      @_exclude ||= Set.new(%w[test spec tmp features config public db].map { |path| Padrino.root(path) })
    end

    ##
    # Tracking files for reloading slows down boot, so it's only enabled in development
    # by default. Files loaded while it's disabled are never reloaded. To reload code in
    # other environments, set +Padrino::Reloader.enabled = true+ before +Padrino.load!+.
    #
    attr_writer :enabled

    def enabled?
      @enabled.nil? ? Padrino.env == :development : @enabled
    end

    ##
    # Specified constants can be excluded from the code unloading process.
    #
    def exclude_constants
      @_exclude_constants ||= Set.new
    end

    ##
    # Specified constants can be configured to be reloaded on every request.
    # Default included constants are: [none]
    #
    def include_constants
      @_include_constants ||= Set.new
    end

    ##
    # Reload apps and files with changes detected.
    #
    def reload!
      rotation do |file|
        next unless file_changed?(file)
        next skip_untracked(file) if untracked_files.include?(file)
        reload_special(file) || reload_regular(file)
      end
    end

    ##
    # Remove files and classes loaded with stat
    #
    def clear!
      MTIMES.clear
      untracked_files.clear
      Storage.clear!
    end

    ##
    # Returns true if any file changes are detected.
    #
    def changed?
      rotation do |file|
        break true if file_changed?(file)
      end
    end

    ##
    # We lock dependencies sets to prevent reloading of protected constants
    #
    def lock!
      klasses = Storage.send(:object_classes) do |klass|
        constant_name(klass)&.split('::')&.first
      end
      klasses |= Padrino.mounted_apps.map(&:app_class)
      exclude_constants.merge(klasses)
    end

    ##
    # A safe Kernel::require which issues the necessary hooks depending on results
    #
    def safe_load(file, options = {})
      began_at = Time.now
      file     = figure_path(file)
      return unless options[:force] || file_changed?(file)
      return skip_untracked(file) if untracked_files.include?(file)
      return require(file) if feature_excluded?(file)

      Storage.prepare(file) # might call #safe_load recursively
      logger.devel(file_new?(file) ? :loading : :reload, began_at, file)
      begin
        with_silence { require(file) }
        Storage.commit(file)
        update_modification_time(file)
        untracked_files.delete(file)
      rescue Exception => e
        unless options[:cyclic]
          logger.exception e, :short
          logger.error "Failed to load #{file}; removing partially defined constants"
        end
        Storage.rollback(file)
        raise
      end
    end

    ##
    # A Kernel::require for when tracking is disabled. Only the modification time is
    # recorded, so later changes are detected but the file is not reloaded.
    #
    def untracked_load(file)
      file = figure_path(file)
      features = $LOADED_FEATURES.dup
      begin
        with_silence { require(file) }
      rescue Exception
        rollback_untracked(file, $LOADED_FEATURES - features)
        raise
      end
      return if feature_excluded?(file) || !File.file?(file)
      update_modification_time(file)
      untracked_files << file
    end

    ##
    # Removes the specified class and constant.
    #
    def remove_constant(const)
      name = constant_name(const) || return
      return if constant_excluded?(const)
      base, _, object = name.rpartition('::')
      base = base.empty? ? Object : Inflections.constantize(base)
      return if base.autoload?(object, false) || !base.const_defined?(object, false)
      return unless base.const_get(object, false).equal?(const)
      base.send :remove_const, object
      logger.devel "Removed constant #{name} from #{constant_name(base)}"
    rescue NameError
      # no const to remove
    end

    ##
    # Clears the included and prepended blocks of an ActiveSupport::Concern, so that its file
    # can define them again. Its dependencies are reset by +extend ActiveSupport::Concern+.
    #
    def reset_concern(concern)
      return if constant_excluded?(concern)
      %i[@_included_block @_prepended_block].each do |ivar|
        concern.remove_instance_variable(ivar) if concern.instance_variable_defined?(ivar)
      end
      logger.devel "Reset concern #{constant_name(concern)}"
    end

    ##
    # Remove a feature from $LOADED_FEATURES so it can be required again.
    #
    def remove_feature(file)
      $LOADED_FEATURES.delete(file) unless feature_excluded?(file)
    end

    ##
    # Returns the list of special tracked files for Reloader.
    #
    def special_files
      @special_files ||= Set.new
    end

    ##
    # Sets the list of special tracked files for Reloader.
    #
    def special_files=(files)
      @special_files = Set.new(files)
    end

    private

    ##
    # Returns absolute path of the file.
    #
    def figure_path(file)
      return file if Pathname.new(file).absolute?
      $LOAD_PATH.each do |path|
        found = File.join(path, file)
        return File.expand_path(found) if File.file?(found)
      end
      file
    end

    ##
    # Files loaded while tracking was disabled.
    #
    def untracked_files
      @untracked_files ||= Set.new
    end

    ##
    # Like Storage.rollback, removes classes defined by a file that failed partway and by
    # the app files it required, so they can be required again. Only the failure pays for
    # walking Object.constants, which keeps boot as fast as a plain require.
    #
    def rollback_untracked(file, features)
      features = features.reject { |feature| feature_excluded?(feature) || untracked_files.include?(feature) }
      features.each { |feature| $LOADED_FEATURES.delete(feature) }
      files = Set.new(features << file)
      Object.constants.each do |name|
        next if Object.autoload?(name)
        next unless files.include?(Object.const_source_location(name)&.first)
        klass = Object.const_get(name)
        remove_constant(klass) if klass.is_a?(Class)
      end
    end

    ##
    # Warns that a changed file can't be reloaded because it was loaded without tracking.
    #
    def skip_untracked(file)
      logger.warn "Skipping reload of #{file}, it was loaded with Padrino::Reloader disabled. " \
                  'Set Padrino::Reloader.enabled = true before Padrino.load! to reload it'
      update_modification_time(file)
    end

    ##
    # Reloads the file if it's special. For now it's only I18n locale files.
    #
    def reload_special(file)
      return unless special_files.any? { |special_file| File.identical?(special_file, file) }
      if defined?(I18n)
        began_at = Time.now
        I18n.reload!
        update_modification_time(file)
        logger.devel :reload, began_at, file
      end
      true
    end

    ##
    # Reloads ruby file and applications dependent on it.
    #
    def reload_regular(file)
      apps = mounted_apps_of(file)
      if apps.empty?
        reloadable_apps.each do |app|
          app.app_obj.reload! if app.app_obj.dependencies.include?(file)
        end
        safe_load(file)
      else
        apps.each { |app| app.app_obj.reload! }
        update_modification_time(file)
      end
    end

    ###
    # Macro for mtime update.
    #
    def update_modification_time(file)
      MTIMES[file] = File.mtime(file)
    end

    ###
    # Returns true if the file is new or it's modification time changed.
    #
    def file_changed?(file)
      file_new?(file) || File.mtime(file) > MTIMES[file]
    end

    ###
    # Returns true if the file is new.
    #
    def file_new?(file)
      MTIMES[file].nil?
    end

    ##
    # Searches Ruby files in your +Padrino.load_paths+ , Padrino::Application.load_paths
    # and monitors them for any changes.
    #
    def rotation
      files_for_rotation.each do |file|
        file = File.expand_path(file)
        next if path_excluded?(file) || !File.file?(file)
        yield file
      end
      nil
    end

    ##
    # Creates an array of paths for use in #rotation.
    #
    def files_for_rotation
      files = Set.new
      Padrino.dependency_paths.each do |path|
        files += Dir.glob(path)
      end
      reloadable_apps.each do |app|
        files << app.app_file
        files += Dir.glob(app.app_obj.prerequisites)
        files += app.app_obj.dependencies
      end
      files + special_files
    end

    ##
    # Tells if a feature should be excluded from Reloader tracking.
    #
    def feature_excluded?(file)
      !path_inside?(file, Padrino.root) || path_excluded?(file)
    end

    ##
    # Tells if the file is in one of the excluded paths, or is one of them.
    #
    def path_excluded?(file)
      exclude.any? { |excluded_path| path_inside?(file, excluded_path) }
    end

    ##
    # Tells if the file is the path itself or inside it, so /app-gem isn't inside /app.
    #
    def path_inside?(file, path)
      file == path || file.start_with?(File.join(path, ''))
    end

    ##
    # Tells if a constant should be excluded from Reloader routines.
    #
    def constant_excluded?(const)
      return true if external_constant?(const)
      name = constant_name(const)
      (exclude_constants - include_constants).any? do |excluded|
        excluded = excluded.to_s
        name == excluded || name.start_with?("#{excluded}::")
      end
    end

    ##
    # Tells if a constant belongs to code the reloader doesn't track, so it's kept on reload.
    # Tracked code is in Padrino.root, outside the excluded paths or in an excluded file
    # that was run with +load+ (which runs it again, so its classes are removed).
    #
    # A constant whose name was first defined in untracked code is kept, even when tracked
    # files add methods to it: the untracked file isn't run again, so a removed class would
    # come back without its methods. A tracked file that reopens it runs again on reload,
    # so its edited and added methods apply, but the methods it deletes or renames stay
    # until the app restarts. Ruby records only the first definition of a name, so a class
    # that a tracked file defines before the untracked file that owns it counts as tracked.
    #
    # Otherwise a constant with a method that has no Ruby source (Struct and Data members,
    # an alias of a built-in method) is removed, unless its name has no Ruby source line
    # (C or Java code defined it).
    # Any other constant is kept only when it has methods and all of them were defined in
    # untracked code.
    #
    def external_constant?(const)
      file, line = constant_location(const)
      return true if file && untracked_source?(file)
      sources = object_sources(const)
      # C extensions define their constants at line 0 of the library file.
      return line.to_i < 1 if sources.delete?(nil)
      # consider methodless constants named in tracked code, or of unknown origin, not external
      return false if sources.empty?
      sources.all? { |source| untracked_source?(source) }
    end

    ##
    # Tells if a file holds code the reloader doesn't track: it's outside Padrino.root,
    # or in an excluded path and was required (a file run with +load+ runs again).
    #
    def untracked_source?(file)
      !path_inside?(file, Padrino.root) || (path_excluded?(file) && $LOADED_FEATURES.include?(file))
    end

    ##
    # Returns the file and line where the constant's name was defined, if known.
    #
    def constant_location(const)
      base, _, object = constant_name(const).to_s.rpartition('::')
      return if object.empty?
      base = base.empty? ? Object : Inflections.constantize(base)
      base.const_source_location(object)
    rescue NameError, ArgumentError # JRuby's Java packages raise ArgumentError
      nil
    end

    ##
    # Gets all the sources in which target class is defined, with nil for
    # a method that has no Ruby source.
    #
    # Note: Method#source_location is for Ruby 1.9.3+ only.
    #
    def object_sources(target)
      sources = Set.new
      target.methods.each do |method_name|
        next unless method_name.is_a?(Symbol)

        method_object = target.method(method_name)
        sources << method_object.source_location&.first if method_object.owner == target.singleton_class
      end

      target.instance_methods.each do |method_name|
        next unless method_name.is_a?(Symbol)

        method_object = target.instance_method(method_name)
        sources << method_object.source_location&.first if method_object.owner == target
      end
      sources
    end

    ##
    # Return the mounted_apps providing the app location.
    # Can be an array because in one app.rb we can define multiple Padrino::Application.
    #
    def mounted_apps_of(file)
      Padrino.mounted_apps.select { |app| File.identical?(file, app.app_file) }
    end

    ##
    # Return the apps that allow reloading.
    #
    def reloadable_apps
      Padrino.mounted_apps.select do |app|
        next unless path_inside?(app.app_file, Padrino.root)
        app.app_obj.respond_to?(:reload) && app.app_obj.reload?
      end
    end

    ##
    # Disables output, yields block, switches output back.
    #
    def with_silence
      verbosity_level, $-v = $-v, nil
      yield
    ensure
      $-v = verbosity_level
    end

    # Module#name as Ruby defines it, so a class that overrides +name+ is still found by its constant.
    MODULE_NAME = ::Module.instance_method(:name)
    private_constant :MODULE_NAME

    def constant_name(constant)
      MODULE_NAME.bind_call(constant)
    end
  end
end
