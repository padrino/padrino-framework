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
      @_exclude ||= Set.new %w(test spec tmp features config public db).map{ |path| Padrino.root(path) }
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
        reload_special(file) || reload_regular(file)
      end
    end

    ##
    # Remove files and classes loaded with stat
    #
    def clear!
      MTIMES.clear
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
        original_klass_name = constant_name(klass)
        original_klass_name.split('::').first if original_klass_name
      end
      klasses |= Padrino.mounted_apps.map(&:app_class)
      exclude_constants.merge(klasses)
    end

    ##
    # A safe Kernel::require which issues the necessary hooks depending on results
    #
    def safe_load(file, options={})
      began_at = Time.now
      file     = figure_path(file)
      return unless options[:force] || file_changed?(file)
      return require(file) if feature_excluded?(file)

      Storage.prepare(file) # might call #safe_load recursively
      logger.devel(file_new?(file) ? :loading : :reload, began_at, file)
      begin
        with_silence{ require(file) }
        Storage.commit(file)
        update_modification_time(file)
      rescue Exception => exception
        unless options[:cyclic]
          logger.exception exception, :short
          logger.error "Failed to load #{file}; removing partially defined constants"
        end
        Storage.rollback(file)
        raise
      end
    end

    ##
    # Removes the specified class and constant.
    #
    def remove_constant(const)
      return if constant_excluded?(const)
      base, _, object = const.to_s.rpartition('::')
      base = base.empty? ? Object : base.constantize
      base.send :remove_const, object
      logger.devel "Removed constant #{const} from #{base}"
    rescue NameError
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
    # Reloads the file if it's special. For now it's only I18n locale files.
    #
    def reload_special(file)
      return unless special_files.any?{ |special_file| File.identical?(special_file, file) }
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
        next if Reloader.exclude.any? { |base| file.start_with?(base) } || !File.file?(file)
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
      !file.start_with?(Padrino.root) || exclude.any?{ |excluded_path| file.start_with?(excluded_path) }
    end

    ##
    # Tells if a constant should be excluded from Reloader routines.
    #
    def constant_excluded?(const)
      external_constant?(const) || (exclude_constants - include_constants).any?{ |excluded_constant| constant_name(const).start_with?(excluded_constant) }
    end

    ##
    # Tells if a constant is defined only outside of Padrino project path.
    # If a constant has any methods defined inside of the project path it's
    # considered internal and will be included in further testing.
    #
    def external_constant?(const)
      sources = object_sources(const)
      # consider methodless constants not external
      return false if sources.empty?
      !sources.any?{ |source| source.start_with?(Padrino.root) }
    end

    ##
    # Gets all the sources in which target class is defined.
    #
    # Note: Method#source_location is for Ruby 1.9.3+ only.
    #
    def object_sources(target)
      sources = Set.new
      target.methods.each do |method_name|
        next unless method_name.kind_of?(Symbol)
        method_object = target.method(method_name)
        if method_object.owner == target.singleton_class
          sources << method_object.source_location.first
        end
      end
      target.instance_methods.each do |method_name|
        next unless method_name.kind_of?(Symbol)
        method_object = target.instance_method(method_name)
        if method_object.owner == target
          sources << method_object.source_location.first
        end
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
        next unless app.app_file.start_with?(Padrino.root)
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

    def constant_name(constant)
      constant._orig_klass_name
    rescue NoMethodError
      constant.name
    end
  end
end
