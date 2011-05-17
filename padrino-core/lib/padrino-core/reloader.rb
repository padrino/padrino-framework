require 'pathname'

module Padrino
  ##
  # High performance source code reloader middleware
  #
  module Reloader
    ##
    # This class acts as a Rack middleware to be added to the application stack. This middleware performs a
    # check and reload for source files at the start of each request, but also respects a specified cool down time
    # during which no further action will be taken.
    #
    class Rack
      def initialize(app, cooldown = 1)
        @app = app
        @cooldown = cooldown
        @last = (Time.now - cooldown)
      end

      def call(env)
        if @cooldown and Time.now > @last + @cooldown
          if Thread.list.size > 1
            Thread.exclusive { Padrino.reload! }
          else
            Padrino.reload!
          end

          @last = Time.now
        end

        @app.call(env)
      end
    end

    ##
    # Specified folders can be excluded from the code reload detection process.
    # Default excluded directories at Padrino.root are: test, spec, features, tmp, config, db and public
    #
    def self.exclude
      @_exclude ||= %w(test spec tmp features config public db).map { |path| Padrino.root(path) }
    end

    ##
    # Specified constants can be excluded from the code unloading process.
    #
    def self.exclude_constants
      @_exclude_constants ||= []
    end

    ##
    # Specified constants can be configured to be reloaded on every request.
    # Default included constants are: [none]
    #
    def self.include_constants
      @_include_constants ||= []
    end

    ##
    # This reloader is suited for use in a many environments because each file
    # will only be checked once and only one system call to stat(2) is made.
    #
    # Please note that this will not reload files in the background, and does so
    # only when explicitly invoked.
    #
    module Stat
      MTIMES               = {}
      FILES_LOADED         = {}
      LOADED_CLASSES       = {}

      class << self
        ##
        # Reload all files with changes detected.
        #
        def reload!
          # Detect changed files
          rotation do |file, mtime|
            # Retrive the last modified time
            new_file = MTIMES[file].nil?
            previous_mtime = MTIMES[file] ||= mtime
            logger.devel "Detected a new file #{file}" if new_file
            # We skip to next file if it is not new and not modified
            next unless new_file || mtime > previous_mtime
            # Now we can reload our file
            safe_load(file, :force => new_file)
            # Reload also apps
            Padrino.mounted_apps.each do |app|
              app.app_obj.reload! if app.app_obj.dependencies.include?(file)
            end
          end
        end

        ##
        # Remove files and classes loaded with stat
        #
        def clear!
          MTIMES.clear
          LOADED_CLASSES.each do |file, klasses|
            klasses.each { |klass| remove_constant(klass) }
            LOADED_CLASSES.delete(file)
          end
          FILES_LOADED.each do |file, dependencies|
            dependencies.each { |dependency| $LOADED_FEATURES.delete(dependency) }
            $LOADED_FEATURES.delete(file)
          end
        end

        ##
        # Returns true if any file changes are detected and populates the MTIMES cache
        #
        def changed?
          changed = false
          rotation do |file, mtime|
            new_file = MTIMES[file].nil?
            previous_mtime = MTIMES[file] ||= mtime
            changed = true if new_file || mtime > previous_mtime
          end
          changed
        end
        alias :run! :changed?

        ##
        # We lock dependencies sets to prevent reloading of protected constants
        #
        def lock!
          klasses = ObjectSpace.classes.map { |klass| klass.to_s.split("::")[0] }.uniq
          klasses = klasses | Padrino.mounted_apps.map { |app| app.app_class }
          Padrino::Reloader.exclude_constants.concat(klasses)
        end

        ##
        # A safe Kernel::require which issues the necessary hooks depending on results
        #
        def safe_load(file, options={})
          force = options.delete(:force)

          reload = MTIMES[file] && File.mtime(file) > MTIMES[file]
          return if !force && !reload && MTIMES[file]

          # Removes all classes declared in the specified file
          klasses = LOADED_CLASSES.delete(file)

          if klasses && !is_app?(file)
            klasses.each { |klass| remove_constant(klass) }
          end

          # Keeps track of which constants were loaded and the files
          # that have been added so that the constants can be removed
          # and the files can be removed from $LOADED_FEAUTRES
          if FILES_LOADED[file]
            FILES_LOADED[file].each do |fl|
              next if fl == file
              $LOADED_FEATURES.delete(fl)
            end
          end

          # Duplicate objects and loaded features in the file
          klasses = ObjectSpace.classes.dup
          files_loaded = $LOADED_FEATURES.dup

          # Load also their deps.
          if FILES_LOADED[file]
            begin
              verbosity, $-v = nil, $-v
              FILES_LOADED[file].each do |dep|
                logger.devel "Dependency #{dep} for #{file}"
              end
              Padrino.require_dependencies(FILES_LOADED[file], :force => true)
            ensure
              $-v = verbosity
            end
          end

          # And finally reload the specified file
          begin
            logger.devel "Loading #{file}#{' with force' if force}" if !reload
            logger.debug "Reloading #{file}" if reload
            $LOADED_FEATURES.delete(file)
            require(file)
            MTIMES[file] = File.mtime(file)
          rescue SyntaxError => ex
            logger.error "Cannot require #{file} because of syntax error: #{ex.message}"
          end

          # Store the file details after successful loading
          LOADED_CLASSES[file] ||= (ObjectSpace.classes - klasses).uniq
          # FILES_LOADED[file]   ||= ($LOADED_FEATURES - files_loaded).reject { |dep| dep == file || !in_root?(dep) }.uniq

          nil
        end

        ##
        # Returns true if the file is defined in our padrino root
        #
        def in_root?(file)
          return true if file =~ %r{^#{Padrino.root}}
          $:.find do |path|
            next unless File.expand_path(path) =~ %r{^#{Padrino.root}}
            File.exist?(Padrino.root(path, file))
          end
        end

        def is_app?(file)
          Padrino.mounted_apps.find { |app| File.identical?(file, app.app_file) }
        end

        ##
        # Removes the specified class and constant.
        #
        def remove_constant(const)
          return if Padrino::Reloader.exclude_constants.any? { |base| (const.to_s =~ %r{^#{base}}) } &&
                   !Padrino::Reloader.include_constants.any? { |base| (const.to_s =~ %r{^#{base}}) }
          begin
            parts  = const.to_s.split("::")
            base   = parts.size == 1 ? Object : parts[0..-2].join("::").constantize
            object = parts[-1].to_s
            logger.devel "Remove constant: #{const}"
            base.send(:remove_const, object)
          rescue NameError; end

          nil
        end

        ##
        # Searches Ruby files in your +Padrino.load_paths+ , Padrino::Application.load_paths
        # and monitors them for any changes.
        #
        def rotation
          files  = Padrino.load_paths.map { |path| Dir["#{path}/**/*.rb"] }.flatten
          files  = files | Padrino.mounted_apps.map { |app| app.app_file }
          files  = files | Padrino.mounted_apps.map { |app| app.app_obj.dependencies  }.flatten
          files.uniq.map { |file|
            file = File.expand_path(file)
            next if Padrino::Reloader.exclude.any? { |base| file =~ %r{^#{base}} } || !File.exist?(file)
            yield(file, File.mtime(file))
          }.compact
        end
      end # self
    end # Stat
  end # Reloader
end # Padrino