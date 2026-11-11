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

    # Requests and reloads take turns through this gate (see #serve and #exclusively).
    @gate = Mutex.new
    @gate_changed = ConditionVariable.new
    @readers = 0
    @writers_waiting = 0
    @writing = false
    # Counts the reloads done, so the requests that saw the same changes reload them once.
    @generation = 0
    @max_wait = 3
    # Thread variables, which every fiber of a thread shares (on JRuby too, where each fiber has
    # its own Thread.current): the number of requests the thread is serving (nested calls, or
    # fibers), the number of its reloads waiting for their turn, and whether one of them runs.
    # A thread counts in @readers while it serves and neither reloads nor waits to.
    SERVING = :padrino_reloader_serving
    WAITING = :padrino_reloader_waiting
    RELOADING = :padrino_reloader_reloading
    private_constant :SERVING, :WAITING, :RELOADING

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
    # How long, in seconds, a reload waits for the requests in progress to finish (3 by default).
    # Past it, the reload goes ahead and logs a warning: a request paused in a debugger, or one
    # that waits for another request (calling its own server, say), can't hold up the server,
    # but the requests still running can see the reload in progress. +nil+ or +Float::INFINITY+
    # waits as long as it takes.
    #
    attr_reader :max_wait

    def max_wait=(seconds)
      unless seconds.nil? || (seconds.is_a?(Numeric) && seconds.real?)
        raise ArgumentError, "Padrino::Reloader.max_wait must be a number of seconds or nil, not #{seconds.inspect}"
      end
      @max_wait = seconds
    end

    ##
    # Runs the block as a request: requests run together, but not while a reload runs. A request
    # that arrives during a reload, or while one waits to start, waits for it. A call nested in
    # a request or a reload, from any fiber of its thread, runs at once. While reloading is
    # disabled, it just runs the block.
    #
    # ceiling: turns belong to threads, so under a fiber scheduler (one thread serving several
    # requests) a reload started by one of its requests doesn't wait for the others, and the
    # thread's requests don't wait for it. A reload from another of its fibers still waits for
    # the turn, and skips the changes reloaded meanwhile.
    #
    def serve(&block)
      return yield unless enabled?
      thread = Thread.current
      # Interrupts (Thread#raise, Timeout) wait until the turn is taken or given back.
      Thread.handle_interrupt(Object => :never) do
        take_serving_turn(thread)
        begin
          Thread.handle_interrupt(Object => :immediate, &block)
        ensure
          give_serving_turn(thread)
        end
      end
    end

    ##
    # Runs the block alone, if the code changed: once the requests in progress have finished, or
    # max_wait seconds have passed. Called from a request, the request gives up its turn while it
    # waits and takes it back afterwards. Returns without running the block if another thread
    # reloaded the changes meanwhile, so one edit causes one reload. While reloading is disabled,
    # it runs the block at once if the code changed.
    #
    def exclusively(&block)
      generation = @generation
      return unless changed?
      thread = Thread.current
      return yield if !enabled? || thread.thread_variable_get(RELOADING)
      Thread.handle_interrupt(Object => :never) do
        in_progress = wait_for_exclusive_turn(thread, generation)
        return unless in_progress
        reloaded = false
        begin
          warn_about_requests_in_progress(in_progress) if in_progress.positive?
          Thread.handle_interrupt(Object => :immediate, &block)
          reloaded = true
        ensure
          end_exclusive_turn(thread, reloaded)
        end
      end
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
      return require_excluded(file) if feature_excluded?(file)

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
      return if constant_excluded?(const)
      base, _, object = const.to_s.rpartition('::')
      base = base.empty? ? Object : Inflections.constantize(base)
      return if base.autoload?(object, false) || !base.const_defined?(object, false)
      return unless base.const_get(object, false).equal?(const)
      base.send :remove_const, object
      logger.devel "Removed constant #{const} from #{base}"
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
      logger.devel "Reset concern #{concern}"
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
    # Waits while a reload runs or waits to start, so a busy server can't keep a reload waiting,
    # unless the thread already holds a turn.
    #
    def take_serving_turn(thread)
      @gate.synchronize do
        unless thread.thread_variable_get(SERVING) || thread.thread_variable_get(RELOADING)
          wait_at_gate while @writing || @writers_waiting.positive?
        end
        change_turn(thread, SERVING, thread.thread_variable_get(SERVING).to_i + 1)
      end
    end

    def give_serving_turn(thread)
      @gate.synchronize do
        serving = thread.thread_variable_get(SERVING) - 1
        change_turn(thread, SERVING, (serving if serving.positive?))
        @gate_changed.broadcast if @readers.zero?
      end
    end

    ##
    # Waits until no request or other reload runs, or max_wait seconds have passed while only
    # requests run, then marks a reload as running and returns the number of requests still in
    # progress. Returns nil if another reload ends meanwhile. The thread gives up its own turn
    # while it waits.
    #
    def wait_for_exclusive_turn(thread, generation)
      @gate.synchronize do
        change_turn(thread, WAITING, thread.thread_variable_get(WAITING).to_i + 1)
        @writers_waiting += 1
        taken = false
        begin
          limit = max_wait
          deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + limit if limit&.finite?
          until @generation != generation
            left = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC) if deadline
            break taken = true unless @writing || (@readers.positive? && (left.nil? || left.positive?))
            wait_at_gate(@writing ? nil : left)
          end
          if taken
            @writing = true
            change_turn(thread, RELOADING, true)
          end
          @readers if taken
        ensure
          @writers_waiting -= 1
          waiting = thread.thread_variable_get(WAITING) - 1
          change_turn(thread, WAITING, (waiting if waiting.positive?))
          @gate_changed.broadcast
        end
      end
    end

    def end_exclusive_turn(thread, reloaded)
      @gate.synchronize do
        @writing = false
        @generation += 1 if reloaded
        change_turn(thread, RELOADING, nil)
        @gate_changed.broadcast
      end
    end

    ##
    # Waits for the gate to change, at most timeout seconds. Called holding @gate, with
    # interrupts deferred: they may stop the wait, before the caller changes anything.
    #
    def wait_at_gate(timeout = nil)
      Thread.handle_interrupt(Object => :immediate) { @gate_changed.wait(@gate, timeout) }
    end

    ##
    # Sets one of the thread's turn variables, keeping @readers in step. Called holding @gate.
    #
    def change_turn(thread, key, value)
      counted = counts_as_reader?(thread)
      thread.thread_variable_set(key, value)
      @readers += (counts_as_reader?(thread) ? 1 : 0) - (counted ? 1 : 0)
    end

    def counts_as_reader?(thread)
      thread.thread_variable_get(SERVING) && !thread.thread_variable_get(WAITING) &&
        !thread.thread_variable_get(RELOADING)
    end

    def warn_about_requests_in_progress(count)
      logger.warn "Reloading the code after waiting #{max_wait}s (Padrino::Reloader.max_wait) for the " \
                  "requests in progress to finish; #{count} still running"
    end

    ##
    # Requires a file the reloader doesn't reload, recording its modification time so that it
    # doesn't count as changed until it is edited.
    #
    def require_excluded(file)
      required = require(file)
      update_modification_time(file) if File.file?(file)
      required
    end

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
      !file.start_with?(Padrino.root) || exclude.any? { |excluded_path| file.start_with?(excluded_path) }
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
    # Tells if a constant is defined only outside of Padrino project path.
    # If a constant has any methods defined inside of the project path it's
    # considered internal and will be included in further testing.
    # A constant without methods (an exception class, say) is judged by
    # where its name was defined instead.
    #
    def external_constant?(const)
      sources = object_sources(const)
      sources = [constant_source(const)].compact if sources.empty?
      # consider methodless constants of unknown origin not external
      return false if sources.empty?
      sources.none? { |source| source.start_with?(Padrino.root) }
    end

    ##
    # Returns the file in which the constant's name was defined, if known.
    #
    def constant_source(const)
      base, _, object = constant_name(const).to_s.rpartition('::')
      return if object.empty?
      base = base.empty? ? Object : Inflections.constantize(base)
      base.const_source_location(object)&.first
    rescue NameError
      nil
    end

    ##
    # Gets all the sources in which target class is defined.
    #
    # Note: Method#source_location is for Ruby 1.9.3+ only.
    #
    def object_sources(target)
      sources = Set.new
      target.methods.each do |method_name|
        next unless method_name.is_a?(Symbol)

        method_object = target.method(method_name)
        sources << method_object.source_location.first if method_object.owner == target.singleton_class
      end

      target.instance_methods.each do |method_name|
        next unless method_name.is_a?(Symbol)

        method_object = target.instance_method(method_name)
        sources << method_object.source_location.first if method_object.owner == target
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
