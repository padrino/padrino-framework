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
      class << self
        MTIMES               = {}
        FILES_LOADED         = {}
        LOADED_CLASSES       = {}

        ##
        # Reload all files with changes detected.
        #
        def reload!
          # Detect changed files
          rotation do |file, mtime|
            # Retrive the last modified time
            new_file = MTIMES[file].nil?
            previous_mtime = MTIMES[file] ||= mtime
            logger.debug "Detected a new file #{file}" if new_file
            # We skip to next file if it is not new and not modified
            next unless new_file || mtime > previous_mtime
            # Reload also apps
            Padrino.mounted_apps.each { |app| app.app_obj.reload! if app.app_obj.respond_to?(:reload!) }
            # Now we can reload our file
            safe_load(file)
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
          Padrino::Reloader.exclude_constants.concat(klasses)
        end

        ##
        # A safe Kernel::require which issues the necessary hooks depending on results
        #
        def safe_load(file, options={})
          force, nodeps = options.delete(:force), options.delete(:nodeps)

          reload = MTIMES[file] && File.mtime(file) > MTIMES[file]
          return if !force && !reload && MTIMES[file]

          unless nodeps
            # Removes all classes declared in the specified file
            if klasses = LOADED_CLASSES.delete(file)
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

            # Now reload the file ignoring any syntax errors
            $LOADED_FEATURES.delete(file)

            # Duplicate objects and loaded features in the file
            klasses = ObjectSpace.classes.dup
            files_loaded = $LOADED_FEATURES.dup

            # Start to re-require old dependencies
            #
            # Why we need to reload the dependencies i.e. of a model?
            #
            # In some circumstances (i.e. with MongoMapper) reloading a model require:
            #
            # 1) Clean objectspace
            # 2) Reload model dependencies
            #
            # We need to clean objectspace because for example we don't need to apply two times validations keys etc...
            #
            # We need to reload MongoMapper dependencies for re-initialize them.
            #
            # In other cases i.e. in a controller (specially with dependencies that uses autoload) reload stuff like sass
            # is not really necessary... but how to distinguish when it is (necessary) since it is not?
            #
            if FILES_LOADED[file]
              FILES_LOADED[file].each do |fl|
                next if fl == file
                # Swich off for a while warnings expecially for "already initialized constant" stuff
                begin
                  verbosity, $-v = nil, $-v
                  require(fl)
                ensure
                  $-v = verbosity
                end
              end
            end
          end

          # And finally reload the specified file
          begin
            require(file)
            logger.debug "#{reload ? 'Rel' : 'L'}oaded #{file}#{' with force' if force}"
            MTIMES[file] = File.mtime(file)
          rescue SyntaxError => ex
            logger.error "Cannot require #{file} because of syntax error: #{ex.message}"
          end

          unless nodeps
            # Store the file details after successful loading
            LOADED_CLASSES[file] ||= (ObjectSpace.classes - klasses)
            FILES_LOADED[file]   ||= ($LOADED_FEATURES - files_loaded)
          end

          nil
        end

        ##
        # Removes the specified class and constant.
        #
        def remove_constant(const)
          return if Padrino::Reloader.exclude_constants.any? { |base| (const.to_s =~ /^#{base}/) } &&
                   !Padrino::Reloader.include_constants.any? { |base| (const.to_s =~ /^#{base}/) }

          parts  = const.to_s.split("::")
          base   = parts.size == 1 ? Object : Object.full_const_get(parts[0..-2].join("::"))
          object = parts[-1].to_s
          begin
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
          files.uniq.map { |file|
            file = File.expand_path(file)
            next if Padrino::Reloader.exclude.any? { |base| file =~ /^#{Regexp.escape(base)}/ }
            yield(file, File.mtime(file))
          }.compact
        end
      end # self
    end # Stat
  end # Reloader
end # Padrino