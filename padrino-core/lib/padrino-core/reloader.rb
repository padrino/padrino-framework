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
        CACHE  = {}
        MTIMES = {}

        def reload!
          rotation do |file, mtime|
            previous_mtime = MTIMES[file] ||= mtime
            safe_load(file, mtime) if mtime > previous_mtime
          end
        end

        def changed?
          changed = false
          rotation do |file, mtime|
            previous_mtime = MTIMES[file] ||= mtime
            changed = true if mtime > MTIMES[file]
          end
          changed
        end

        ##
        # A safe Kernel::load, issuing the hooks depending on the results
        # 
        def safe_load(file, mtime)
          logger.debug "Reloading #{file}"
          load(file)
          file
        rescue LoadError, SyntaxError => ex
          logger.error ex
        ensure
          MTIMES[file] = mtime
        end

        ##
        # Search Ruby files in your +Padrino.root+ and monitor them for changes.
        # 
        def rotation
          paths = Dir[Padrino.root("*")].reject { |path| Padrino::Reloader.exclude.include?(path) || !File.directory?(path) }
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
