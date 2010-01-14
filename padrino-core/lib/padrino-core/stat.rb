require 'pathname'

module Padrino
  # What makes it especially suited for use in a any environment is that
  # any file will only be checked once and there will only be made one system
  # call stat(2).
  #
  # Please note that this will not reload files in the background, it does so
  # only when actively called.
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

      # A safe Kernel::load, issuing the hooks depending on the results
      def safe_load(file, mtime)
        logger.debug "Reloading #{file}"
        load(file)
        file
      rescue LoadError, SyntaxError => ex
        $stderr.puts ex
      ensure
        MTIMES[file] = mtime
      end

      def rotation
        files = [$0, *$LOADED_FEATURES].uniq
        paths = ['./', *$LOAD_PATH].uniq

        files.map{ |file|
          next if file =~ /\.(so|bundle)$/                   # cannot reload compiled files
          found, stat = figure_path(file, paths)
          next unless found && stat && mtime = stat.mtime

          CACHE[file] = found

          yield(found, mtime)
        }.compact
      end

      # Takes a relative or absolute +file+ name, a couple possible +paths+ that
      # the +file+ might reside in. Returns the full path and File::Stat for the
      # path.
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
    end
  end
end
