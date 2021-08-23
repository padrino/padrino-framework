require 'pathname'

# Defines the log level for a Padrino project.
PADRINO_LOG_LEVEL = ENV['PADRINO_LOG_LEVEL'] unless defined?(PADRINO_LOG_LEVEL)

# Defines the logger used for a Padrino project.
PADRINO_LOGGER = ENV['PADRINO_LOGGER'] unless defined?(PADRINO_LOGGER)

module Padrino
  ##
  # @return [Padrino::Logger]
  #
  # @example
  #   logger.debug "foo"
  #   logger.warn "bar"
  #
  def self.logger
    Padrino::Logger.logger
  end

  ##
  # Set the padrino logger.
  #
  # @param [Object] value
  #   an object that respond to <<, write, puts, debug, warn, devel, etc..
  #
  # @return [Object]
  #   The given value.
  #
  # @example using ruby default logger
  #   require 'logger'
  #   new_logger = ::Logger.new(STDOUT)
  #   new_logger.extend(Padrino::Logger::Extensions)
  #   Padrino.logger = new_logger
  #
  # @example using ActiveSupport
  #   require 'active_support/buffered_logger'
  #   Padrino.logger = Buffered.new(STDOUT)
  #
  # @example using custom logger class
  #   require 'logger'
  #   class CustomLogger < ::Logger
  #     include Padrino::Logger::Extensions
  #   end
  #   Padrino.logger = CustomLogger.new(STDOUT)
  #
  def self.logger=(value)
    Padrino::Logger.logger = value
  end

  ##
  # Padrinos internal logger, using all of Padrino log extensions.
  #
  class Logger
    ##
    # Ruby (standard) logger levels:
    #
    # :fatal:: An not handleable error that results in a program crash
    # :error:: A handleable error condition
    # :warn:: A warning
    # :info:: generic (useful) information about system operation
    # :debug:: low-level information for developers
    # :devel:: Development-related information that is unnecessary in debug mode
    #
    Levels = {
      :fatal =>  4,
      :error =>  3,
      :warn  =>  2,
      :info  =>  1,
      :debug =>  0,
      :devel => -1,
    } unless defined?(Levels)

    module Extensions
      ##
      # Generate the logging methods for {Padrino.logger} for each log level.
      #
      Padrino::Logger::Levels.each_pair do |name, number|
        define_method(name) do |*args|
          return if number < level
          if args.size > 1
            bench(args[0], args[1], args[2], name)
          else
            if location = resolve_source_location(caller(1).shift)
              args.unshift(location)
            end if enable_source_location?
            push(args * '', name)
          end
        end

        define_method(:"#{name}?") do
          number >= level
        end
      end

      SOURCE_LOCATION_REGEXP = /^(.*?):(\d+?)(?::in `.+?')?$/.freeze

      ##
      # Returns true if :source_location is set to true.
      #
      def enable_source_location?
        respond_to?(:source_location?) && source_location?
      end

      ##
      # Resolves a filename and line-number from caller.
      #
      def resolve_source_location(message)
        path, line = *message.scan(SOURCE_LOCATION_REGEXP).first
        return unless path && line
        root = Padrino.root
        path = File.realpath(path) if Pathname.new(path).relative?
        if path.start_with?(root) && !path.start_with?(Padrino.root("vendor"))
          "[#{path.gsub("#{root}/", "")}:#{line}] "
        end
      end

      ##
      # Append a to development logger a given action with time.
      #
      # @param [string] action
      #   The action.
      #
      # @param [float] time
      #   Time duration for the given action.
      #
      # @param [message] string
      #   The message that you want to log.
      #
      # @example
      #   logger.bench 'GET', started_at, '/blog/categories'
      #   # => DEBUG - GET (0.0056s) - /blog/categories
      #
      def bench(action, began_at, message, level=:debug, color=:yellow)
        @_pad  ||= 8
        @_pad    = action.to_s.size if action.to_s.size > @_pad
        duration = Time.now - began_at
        color    = :red if duration > 1
        action   = colorize(action.to_s.upcase.rjust(@_pad), color)
        duration = colorize('%0.4fs' % duration, color, :bold)
        push "#{action} (#{duration}) #{message}", level
      end

      ##
      # Appends a message to the log. The methods yield to an optional block and
      # the output of this block will be appended to the message.
      #
      # @param [String] message
      #   The message that you want write to your stream.
      #
      # @param [String] level
      #   The level one of :debug, :warn etc. ...
      #
      #
      def push(message = nil, level = nil)
        add(Padrino::Logger::Levels[level], format(message, level))
      end

      ##
      # Formats the log message. This method is a noop and should be implemented by other
      # logger components such as {Padrino::Logger}.
      #
      # @param [String] message
      #   The message to format.
      #
      # @param [String,Symbol] level
      #   The log level, one of :debug, :warn ...
      def format(message, level)
        message
      end

      ##
      # The debug level, with some style added. May be reimplemented.
      #
      # @example
      #   stylized_level(:debug) => DEBUG
      #
      # @param [String,Symbol] level
      #   The log level.
      #
      def stylized_level(level)
        level.to_s.upcase.rjust(7)
      end

      ##
      # Colorizes a string for colored console output. This is a noop and can be reimplemented
      # to colorize the string as needed.
      #
      # @see
      #   ColorizedLogger
      #
      # @param [string]
      #   The string to be colorized.
      #
      # @param [Array<Symbol>]
      #   The colors to use. Should be applied in the order given.
      def colorize(string, *colors)
        string
      end

      ##
      # Turns a logger with LoggingExtensions into a logger with colorized output.
      #
      # @example
      #   Padrino.logger = Logger.new($stdout)
      #   Padrino.logger.colorize!
      #   Padrino.logger.debug("Fancy Padrino debug string")
      def colorize!
        self.extend(Colorize)
      end

      ##
      # Logs an exception.
      #
      # @param [Exception] exception
      #   The exception to log
      #
      # @param [Symbol] verbosity
      #   :short or :long, default is :long
      #
      # @example
      #   Padrino.logger.exception e
      #   Padrino.logger.exception(e, :short)
      def exception(boom, verbosity = :long, level = :error)
        return unless Levels.has_key?(level)
        text = ["#{boom.class} - #{boom.message}:"]
        trace = boom.backtrace
        case verbosity
        when :long
          text += trace
        when :short
          text << trace.first
        end if trace.kind_of?(Array)
        send level, text.join("\n ")
      end
    end

    module Colorize
      # Colors for levels
      ColoredLevels = {
        :fatal => [:bold, :red],
        :error => [:default, :red],
        :warn  => [:default, :yellow],
        :info  => [:default, :green],
        :debug => [:default, :cyan],
        :devel => [:default, :magenta]
      } unless defined?(ColoredLevels)

      ##
      # Colorize our level.
      #
      # @param [String, Symbol] level
      #
      # @see Padrino::Logging::ColorizedLogger::ColoredLevels
      #
      def colorize(string, *colors)
        string.colorize(:color => colors[0], :mode => colors[1])
      end

      def stylized_level(level)
        style = "\e[%d;%dm" % ColoredLevels[level].map{|color| String::Colorizer.modes[color] || String::Colorizer.colors[color] }
        [style, super, "\e[0m"] * ''
      end
    end

    include Extensions

    attr_accessor :auto_flush, :level, :log_static
    attr_reader   :buffer, :colorize_logging, :init_args, :log

    ##
    # Configuration for a given environment, possible options are:
    #
    # :log_level:: Once of [:fatal, :error, :warn, :info, :debug]
    # :stream:: Once of [:to_file, :null, :stdout, :stderr] our your custom stream
    # :log_path:: Defines log file path or directory if :stream is :to_file
    #   If it's a file, its location is created by mkdir_p.
    #   If it's a directory, it must exist. In this case log name is '<env>.log'
    # :log_level::
    #   The log level from, e.g. :fatal or :info. Defaults to :warn in the
    #   production environment and :debug otherwise.
    # :auto_flush::
    #   Whether the log should automatically flush after new messages are
    #   added. Defaults to true.
    # :format_datetime:: Format of datetime. Defaults to: "%d/%b/%Y %H:%M:%S"
    # :format_message:: Format of message. Defaults to: ""%s - - [%s] \"%s\"""
    # :log_static:: Whether or not to show log messages for static files. Defaults to: false
    # :colorize_logging:: Whether or not to colorize log messages. Defaults to: true
    #
    # @example
    #   Padrino::Logger::Config[:development] = { :log_level => :debug, :stream => :to_file }
    #   # or you can edit our defaults
    #   Padrino::Logger::Config[:development][:log_level] = :error
    #   # or change log file path
    #   Padrino::Logger::Config[:development][:log_path] = 'logs/app-development.txt'
    #   # or change log file directory
    #   Padrino::Logger::Config[:development][:log_path] = '/var/logs/padrino'
    #   # or you can use your stream
    #   Padrino::Logger::Config[:development][:stream] = StringIO.new
    #
    # Defaults are:
    #
    #   :production  => { :log_level => :warn, :stream => :to_file }
    #   :development => { :log_level => :debug, :stream => :stdout }
    #   :test        => { :log_level => :fatal, :stream => :null }
    #
    # In some cases, configuring the loggers before loading the framework is necessary.
    # You can do so by setting PADRINO_LOGGER:
    #
    #   PADRINO_LOGGER = { :staging => { :log_level => :debug, :stream => :to_file }}
    #
    Config = {
      :production  => { :log_level => :warn,  :stream => :to_file },
      :development => { :log_level => :debug, :stream => :stdout, :format_datetime => '' },
      :test        => { :log_level => :debug, :stream => :null }
    }
    Config.merge!(PADRINO_LOGGER) if PADRINO_LOGGER

    @@mutex = Mutex.new
    def self.logger
      (@_logger ||= nil) || setup!
    end

    def self.logger=(logger)
      unless logger.class.ancestors.include?(Padrino::Logger::Extensions)
        warn <<-EOT
WARNING! `Padrino.logger = new_logger` no longer extends it with #colorize! and other features.
          To do it with a custom logger you have to manually `new_logger.extend(Padrino::Logger::Extensions)`
          before passing to `Padrino.logger = new_logger`.
        EOT
      end
      @_logger = logger
    end

    ##
    # Setup a new logger.
    #
    # @return [Padrino::Logger]
    #   A {Padrino::Logger} instance
    #
    def self.setup!
      config_level = (PADRINO_LOG_LEVEL || Padrino.env || :test).to_sym # need this for PADRINO_LOG_LEVEL
      config = Config[config_level]

      unless config
        warn("No logging configuration for :#{config_level} found, falling back to :production")
        config = Config[:production]
      end

      stream = case config[:stream]
        when :to_file
          if filename = config[:log_path]
            filename = Padrino.root(filename) unless Pathname.new(filename).absolute?
            if File.directory?(filename)
              filename = File.join(filename, "#{Padrino.env}.log")
            else
              FileUtils.mkdir_p(File.dirname(filename))
            end
            File.new(filename, 'a+')
          else
            FileUtils.mkdir_p(Padrino.root('log')) unless File.exist?(Padrino.root('log'))
            File.new(Padrino.root('log', "#{Padrino.env}.log"), 'a+')
          end
        when :null   then StringIO.new
        when :stdout then $stdout
        when :stderr then $stderr
        else config[:stream] # return itself, probabilly is a custom stream.
      end

      new_logger = Padrino::Logger.new(config.merge(:stream => stream))
      new_logger.extend(Padrino::Logger::Extensions)
      self.logger = new_logger
    end

    ##
    # To initialize the logger you create a new object, proxies to set_log.
    #
    # @param [Hash] options
    #
    # @option options [Symbol] :stream ($stdout)
    #   Either an IO object or a name of a logfile. Defaults to $stdout
    #
    # @option options [Symbol] :log_level (:production in the production environment and :debug otherwise)
    #   The log level from, e.g. :fatal or :info.
    #
    # @option options [Symbol] :auto_flush (true)
    #   Whether the log should automatically flush after new messages are
    #   added. Defaults to true.
    #
    # @option options [Symbol] :format_datetime (" [%d/%b/%Y %H:%M:%S] ")
    #   Format of datetime.
    #
    # @option options [Symbol] :format_message ("%s -%s%s")
    #    Format of message.
    #
    # @option options [Symbol] :log_static (false)
    #   Whether or not to show log messages for static files.
    #
    # @option options [Symbol] :colorize_logging (true)
    #   Whether or not to colorize log messages. Defaults to: true.
    #
    # @option options [Symbol] :sanitize_encoding (false)
    #   Logger will replace undefined or broken characters with
    #   “uFFFD” for Unicode and “?” otherwise.
    #   Can be an encoding, false or true.
    #   If it's true, logger sanitizes to Encoding.default_external.
    #
    def initialize(options={})
      @buffer           = []
      @auto_flush       = options.has_key?(:auto_flush) ? options[:auto_flush] : true
      @level            = options[:log_level] ? Padrino::Logger::Levels[options[:log_level]] : Padrino::Logger::Levels[:debug]
      @log              = options[:stream]  || $stdout
      @log.sync         = true
      @format_datetime  = options[:format_datetime] || "%d/%b/%Y %H:%M:%S"
      @format_message   = options[:format_message]  || "%s - %s %s"
      @log_static       = options.has_key?(:log_static) ? options[:log_static] : false
      @colorize_logging = options.has_key?(:colorize_logging) ? options[:colorize_logging] : true
      @source_location  = options[:source_location]
      @sanitize_encoding = options[:sanitize_encoding] || false
      @sanitize_encoding = Encoding.default_external if @sanitize_encoding == true
      colorize! if @colorize_logging
    end

    def source_location?
      !!@source_location
    end

    ##
    # Flush the entire buffer to the log object.
    #
    def flush
      return unless @buffer.size > 0
      @@mutex.synchronize do
        @buffer.each do |line|
          line.encode!(@sanitize_encoding, :invalid => :replace, :undef => :replace) if @sanitize_encoding
          @log.write(line)
        end
        @buffer.clear
      end
    end

    ##
    # Close and remove the current log object.
    #
    # @return [NilClass]
    #
    def close
      flush
      @log.close if @log.respond_to?(:close) && !@log.tty?
      @log = nil
    end

    ##
    # Adds a message to the log - for compatibility with other loggers.
    #
    def add(level, message = nil)
      write(message)
    end

    ##
    # Directly append message to the log.
    #
    # @param [String] message
    #   The message
    #
    def <<(message = nil)
      message << "\n" unless message[-1] == ?\n
      @@mutex.synchronize {
        @buffer << message
      }
      flush if @auto_flush
      message
    end
    alias :write :<<

    def format(message, level)
      @format_message % [stylized_level(level), colorize(Time.now.strftime(@format_datetime), :yellow), message.to_s.strip]
    end

    ##
    # Padrino::Logger::Rack forwards every request to an +app+ given, and
    # logs a line in the Apache common log format to the +logger+, or
    # rack.errors by default.
    #
    class Rack
      def initialize(app, uri_root)
        @app = app
        @uri_root = uri_root.sub(/\/$/,"")
      end

      def call(env)
        env['rack.logger'] = Padrino.logger
        began_at = Time.now
        status, header, body = @app.call(env)
        log(env, status, header, began_at) if logger.debug?
        [status, header, body]
      end

      private

      def log(env, status, header, began_at)
        return if env['sinatra.static_file'] && (!logger.respond_to?(:log_static) || !logger.log_static)
        logger.bench(
          env["REQUEST_METHOD"],
          began_at,
          [
            @uri_root.to_s,
            env["PATH_INFO"],
            env["QUERY_STRING"].empty? ? "" : "?" + env["QUERY_STRING"],
            ' - ',
            logger.colorize(status.to_s[0..3], :default, :bold),
            ' ',
            code_to_name(status)
          ] * '',
          :debug,
          :magenta
        )
      end

      def code_to_name(status)
        ::Rack::Utils::HTTP_STATUS_CODES[status.to_i] || ''
      end
    end
  end
end

module Kernel
  ##
  # Define a logger available every where in our app
  #
  def logger
    Padrino.logger
  end
end
