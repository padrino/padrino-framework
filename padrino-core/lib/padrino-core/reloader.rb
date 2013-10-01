require 'pathname'
require 'padrino-core/reloader/rack'

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
    MTIMES          = {}
    # The list of files loaded as part of a project.
    LOADED_FILES    = {}
    # The list of object constants and classes loaded as part of the project.
    LOADED_CLASSES  = {}

    ##
    # Specified folders can be excluded from the code reload detection process.
    # Default excluded directories at Padrino.root are: test, spec, features, tmp, config, db and public
    #
    def exclude
      @_exclude ||= %w(test spec tmp features config public db).map { |path| Padrino.root(path) }
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
        logger.devel "Detected a new file #{file}" if file_new?(file)
        apps = mounted_apps_of(file)
        if apps.present?
          apps.each { |app| app.app_obj.reload! }
          update_modification_time(file)
        else
          safe_load(file)
          Padrino.mounted_apps.each do |app|
            app.app_obj.reload! if app.app_obj.dependencies.include?(file)
          end
        end
      end
    end

    ##
    # Remove files and classes loaded with stat
    #
    def clear!
      clear_modification_times
      clear_loaded_classes
      clear_loaded_files_and_features
    end

    ##
    # Returns true if any file changes are detected and populates the MTIMES cache
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
      klasses = ObjectSpace.classes do |klass|
        klass._orig_klass_name.split('::')[0]
      end

      klasses = klasses | Padrino.mounted_apps.map { |app| app.app_class }
      Padrino::Reloader.exclude_constants.merge(klasses)
    end

    ##
    # A safe Kernel::require which issues the necessary hooks depending on results
    #
    def safe_load(file, options={})
      began_at = Time.now
      file     = figure_path(file)

      return unless options[:force] || file_changed?(file)

      remove_loaded_file_classes(file)
      remove_loaded_file_features(file)

      # Duplicate objects and loaded features before load file
      klasses  = ObjectSpace.classes
      features = Set.new($LOADED_FEATURES.dup)
      reload_deps_of_file(file)
      $LOADED_FEATURES.delete(file) if features.include?(file)

      logger.debug(file_new?(file) ? :loading : :reload,  began_at, file)
      begin
        loaded = false
        with_silence{ require(file) }
      rescue Exception => e
        logger.error "#{e.class}: #{e.message}; #{e.backtrace.first}"
        logger.error "Failed to load #{file}; removing partially defined constants"
        raise
      else
        loaded = true
        update_modification_time(file)
      ensure
        new_classes = ObjectSpace.new_classes(klasses)
        if loaded
          process_loaded_file(file, new_classes, features)
        else
          unload_constants(new_classes)
        end
      end
    end

    ##
    # Returns true if the file is defined in our padrino root.
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
    # Removes the specified class and constant.
    #
    def remove_constant(const)
      return if exclude_constants.any? { |c| const._orig_klass_name.index(c) == 0 } &&
               !include_constants.any? { |c| const._orig_klass_name.index(c) == 0 }
      begin
        parts  = const.to_s.sub(/^::(Object)?/, 'Object::').split('::')
        object = parts.pop
        base   = parts.empty? ? Object : Inflector.constantize(parts * '::')
        base.send :remove_const, object
        logger.devel "Removed constant: #{const} from #{base}"
      rescue NameError
      end
    end

    private

    ##
    # Removes all classes declared in the specified file.
    #
    def remove_loaded_file_classes(file)
      if klasses = LOADED_CLASSES[file]
        klasses.each { |klass| remove_constant(klass) }
      end
    end

    ##
    # Remove all loaded fatures with our file.
    #
    def remove_loaded_file_features(file)
      if features = LOADED_FILES[file]
        features.each { |feature| $LOADED_FEATURES.delete(feature) }
      end
    end

    def clear_loaded_classes
      LOADED_CLASSES.each do |file, klasses|
        klasses.each { |klass| remove_constant(klass) }
        LOADED_CLASSES.delete(file)
      end
    end

    def clear_loaded_files_and_features
      LOADED_FILES.each do |file, features|
        features.each { |feature| $LOADED_FEATURES.delete(feature) }
        $LOADED_FEATURES.delete(file)
      end
    end

    ###
    # Clear instance variables that keep track of # loaded features/files/mtimes.
    #
    def clear_modification_times
      MTIMES.clear
    end

    ###
    # Macro for mtime query.
    #
    def modification_time(file)
      MTIMES[file]
    end

    ###
    # Macro for mtime update.
    #
    def update_modification_time(file)
      MTIMES[file] = File.mtime(file)
    end

    ###
    # Tracks loaded file features/classes/constants:
    #
    def process_loaded_file(file, klasses, features)
      # Store the file details
      LOADED_CLASSES[file] = klasses
      LOADED_FILES[file]   = Set.new($LOADED_FEATURES) - features - [file]

      # Track only features in our Padrino.root
      LOADED_FILES[file].select! { |feature| in_root?(feature) }
    end

    ###
    # Unloads all constants in new_constants.
    #
    def unload_constants(new_constants)
      new_constants.each { |klass| remove_constant(klass) }
    end

    ###
    # Safe load dependencies of the file.
    #
    def reload_deps_of_file(file)
      if features = LOADED_FILES.delete(file)
        features.each { |feature| safe_load(feature, :force => true) }
      end
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
    # Return the mounted_apps providing the app location.
    # Can be an array because in one app.rb we can define multiple Padrino::Application.
    #
    def mounted_apps_of(file)
      file = figure_path(file)
      Padrino.mounted_apps.select { |app| File.identical?(file, app.app_file) }
    end

    ##
    # Returns true if file is in our Padrino.root.
    #
    def in_root?(file)
      # This is better but slow:
      #   Pathname.new(Padrino.root).find { |f| File.identical?(Padrino.root(f), figure_path(file)) }
      figure_path(file).index(Padrino.root) == 0
    end

    ##
    # Searches Ruby files in your +Padrino.load_paths+ , Padrino::Application.load_paths
    # and monitors them for any changes.
    #
    def rotation
      files_for_rotation.uniq.map do |file|
        file = File.expand_path(file)
        next if Padrino::Reloader.exclude.any? { |base| file.index(base) == 0 } || !File.file?(file)
        yield file
      end
      nil
    end

    ##
    # Creates an array of paths for use in #rotation.
    #
    def files_for_rotation
      files = Padrino.load_paths.map { |path| Dir["#{path}/**/*.rb"] }.flatten
      files = files | Padrino.mounted_apps.map { |app| app.app_file }
      files = files | Padrino.mounted_apps.map { |app| app.app_obj.dependencies }.flatten
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
  end
end
