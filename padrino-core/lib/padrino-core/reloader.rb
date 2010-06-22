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
    # Default excluded directories at Padrino.root are: test, spec, features, tmp, config, lib, db and public
    #
    def self.exclude
      @_exclude ||= %w(test spec tmp features config lib public db).map { |path| Padrino.root(path) }
    end

    ##
    # Specified constants can be excluded from the code unloading process.
    # Default excluded constants are: Padrino, Sinatra
    #
    def self.exclude_constants
      @_exclude_constants ||= %w(Padrino::Application Sinatra::Application Sinatra::Base)
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
        CACHE                = {}
        MTIMES               = {}
        FILES_LOADED         = {}
        LOADED_CLASSES       = {}

        ##
        # Reload all files with changes detected.
        #
        def reload!
          rotation do |file, mtime|
            # Retrive the last modified time
            new_file = MTIMES[file].nil?
            previous_mtime = MTIMES[file] ||= mtime
            logger.debug "Detected a new file #{file}" if new_file
            # We skip to next file if it is not new and not modified
            next unless new_file || mtime > previous_mtime
            # If the file is related to their app (i.e. a controller/mailer/helper)
            if app = Padrino.mounted_apps.find { |a| file =~ /^#{File.dirname(a.app_file)}/ }
              # We need to reload their own app
              app.app_obj.reload!
              # App reloading will also perform safe_load of itself so we can go next
              if File.identical?(app.app_file, file)
                MTIMES[file] = mtime # This prevent a loop
                next
              end
            end
            # Now we can reload our file
            safe_load(file, mtime)
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
        # A safe Kernel::load which issues the necessary hooks depending on results
        #
        def safe_load(file, mtime=nil)
          reload = mtime && mtime > MTIMES[file]

          logger.debug "Reloading #{file}" if reload

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
              # Swich off for a while warnings expecially "already initialized constant" stuff
              begin
                verbosity = $-v
                $-v = nil
                require(fl)
              ensure
                $-v = verbosity
              end
            end
          end

          # And finally reload the specified file
          begin
            require(file)
          rescue SyntaxError => ex
            logger.error "Cannot require #{file} because of syntax error: #{ex.message}"
          ensure
            MTIMES[file] = mtime if mtime
          end

          # Store the file details after successful loading
          LOADED_CLASSES[file] = ObjectSpace.classes - klasses
          FILES_LOADED[file]   = $LOADED_FEATURES - files_loaded

          nil
        end

        ##
        # Removes the specified class and constant.
        #
        # Additionally this removes the specified class from the subclass list of every superclass that
        # tracks it's subclasses in an array returned by _subclasses_list. Classes that wish to use this
        # functionality are required to alias the reader for their list of subclasses
        # to _subclasses_list. Plugins for ORMs and other libraries should keep this in mind.
        #
        def remove_constant(const)
          return if Padrino::Reloader.exclude_constants.any? { |base| (const.to_s =~ /^#{base}/ || const.superclass.to_s =~ /^#{base}/) } &&
                   !Padrino::Reloader.include_constants.any? { |base| (const.to_s =~ /^#{base}/ || const.superclass.to_s =~ /^#{base}/) }

          superklass = const
          until (superklass = superklass.superclass).nil?
            if superklass.respond_to?(:_subclasses_list)
              superklass.send(:_subclasses_list).delete(klass)
              superklass.send(:_subclasses_list).delete(klass.to_s)
            end
          end

          parts = const.to_s.split("::")
          base = parts.size == 1 ? Object : Object.full_const_get(parts[0..-2].join("::"))
          object = parts[-1].to_s
          begin
            base.send(:remove_const, object)
          rescue NameError
          end

          nil
        end

        ##
        # Searches Ruby files in your +Padrino.root+ and monitors them for any changes.
        #
        def rotation
          paths = Dir[Padrino.root("*")].unshift(Padrino.root).reject { |path| !File.directory?(path) }

          files = paths.map { |path| Dir["#{path}/**/*.rb"] }.flatten

          files.map{ |file|
            next if Padrino::Reloader.exclude.any? { |base| file =~ /^#{base}/ }

            found, stat = figure_path(file, paths)
            next unless found && stat && mtime = stat.mtime

            CACHE[file] = found

            yield(found, mtime)
          }.compact
        end

        ##
        # Takes a relative or absolute +file+ name and a couple possible +paths+ that
        # the +file+ might reside in. Returns the full path and File::Stat for that path.
        #
        def figure_path(file, paths)
          found = CACHE[file]
          found = file if !found and Pathname.new(file).absolute?
          found, stat = safe_stat(found)
          return found, stat if found

          paths.find do |possible_path|
            path = ::File.join(possible_path, file)
            found, stat = safe_stat(path)
            return ::File.expand_path(found), stat if found
          end

          return false, false
        end

        def safe_stat(file)
          return unless file
          stat = ::File.stat(file)
          return file, stat if stat.file?
        rescue Errno::ENOENT, Errno::ENOTDIR
          CACHE.delete(file) and false
        end
      end # self
    end # Stat
  end # Reloader
end # Padrino