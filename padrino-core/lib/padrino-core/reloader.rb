require 'pathname'

module Padrino
  ##
  # High performant source reloader
  #
  module Reloader
    ##
    # This class acts as Rack middleware.
    #
    # It is performing a check/reload cycle at the start of every request, but
    # also respects a cool down time, during which nothing will be done.
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
    # You can exclude some folders from reload its contents.
    # Defaults excluded directories of Padrino.root are: test, spec, features, tmp, config, lib, db and public
    #
    def self.exclude
      @_exclude ||= %w(test spec tmp features config lib public db).map { |path| Padrino.root(path) }
    end

    ##
    # What makes it especially suited for use in a any environment is that
    # any file will only be checked once and there will only be made one system
    # call stat(2).
    #
    # Please note that this will not reload files in the background, it does so
    # only when actively called.
    #
    module Stat
      class << self
        CACHE                = {}
        MTIMES               = {}
        FILES_LOADED         = {}
        LOADED_CLASSES       = {}

        ##
        # Reload changed files
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
              app.app_object.reload!
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
        # Return true if some thing changed and in the meanwhile fill MTIMES cache
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
        # A safe Kernel::load, issuing the hooks depending on the results
        #
        def safe_load(file, mtime=nil)
          reload = mtime && mtime > MTIMES[file]

          logger.debug "Reloading #{file}" if reload

          # We remove all classes declared in the specified file
          if klasses = LOADED_CLASSES.delete(file)
            klasses.each { |klass| remove_constant(klass) }
          end

          # We track of what constants were loaded and what files
          # have been added, so that the constants can be removed
          # and the files can be removed from $LOADED_FEAUTRES
          if FILES_LOADED[file]
            FILES_LOADED[file].each do |fl|
              next if fl == file
              $LOADED_FEATURES.delete(fl)
              require(fl)
            end
          end

          klasses = ObjectSpace.classes.dup
          files_loaded = $LOADED_FEATURES.dup

          # Now we can reload the file ignoring syntax errors
          $LOADED_FEATURES.delete(file)

          begin
            require(file)
          rescue SyntaxError => ex
            logger.error "Cannot require #{file} because of syntax error: #{ex.message}"
          ensure
            MTIMES[file] = mtime if mtime
          end

          # Store off the details after the file has been loaded
          LOADED_CLASSES[file] = ObjectSpace.classes - klasses
          FILES_LOADED[file]   = $LOADED_FEATURES - files_loaded

          nil
        end

        ##
        # Removes the specified class.
        #
        # Additionally, removes the specified class from the subclass list of every superclass that
        # tracks it's subclasses in an array returned by _subclasses_list. Classes that wish to use this
        # functionality are required to alias the reader for their list of subclasses
        # to _subclasses_list. Plugins for ORMs and other libraries should keep this in mind.
        #
        def remove_constant(const)
          return if const.superclass.to_s =~ /Padrino::Application|Sinatra::Application|Sinatra::Base/

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
        # Search Ruby files in your +Padrino.root+ and monitor them for changes.
        #
        def rotation
          paths = Dir[Padrino.root("*")].unshift(Padrino.root).reject { |path| Padrino::Reloader.exclude.include?(path) || !File.directory?(path) }

          files = paths.map { |path| Dir["#{path}/**/*.rb"] }.flatten

          files.map{ |file|
            found, stat = figure_path(file, paths)
            next unless found && stat && mtime = stat.mtime

            CACHE[file] = found

            yield(found, mtime)
          }.compact
        end

        ##
        # Takes a relative or absolute +file+ name, a couple possible +paths+ that
        # the +file+ might reside in. Returns the full path and File::Stat for the
        # path.
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