module Padrino

  # Setup a new logger
  def self.setup_logger!
    case Padrino.env
      when :production
        FileUtils.mkdir_p("#{Padrino.root}/log") unless File.exists?("#{Padrino.root}/log")
        log = File.new("#{Padrino.root}/log/#{PADRINO_ENV.downcase}.log", "a+")
        Thread.current[:padrino_logger] = Padrino::Logger.new(:log_level => :error, :stream => log)
      else
        Thread.current[:padrino_logger] = Padrino::Logger.new
    end
    Thread.current[:padrino_logger]
  end

  class Logger

    attr_accessor :level
    attr_accessor :auto_flush
    attr_reader   :buffer
    attr_reader   :log
    attr_reader   :init_args

    # ==== Notes
    # Ruby (standard) logger levels:
    # 
    # :fatal:: An unhandleable error that results in a program crash
    # :error:: A handleable error condition
    # :warn:: A warning
    # :info:: generic (useful) information about system operation
    # :debug:: low-level information for developers
    Levels = {
      :fatal => 7,
      :error => 6,
      :warn  => 4,
      :info  => 3,
      :debug => 0
    } unless const_defined?(:Levels)

    @@mutex = {}

    public

    # To initialize the logger you create a new object, proxies to set_log.
    #
    # ==== Options can be:
    # 
    # :stream:: Either an IO object or a name of a logfile. Defaults to $stdout
    # :log_level::
    #   The log level from, e.g. :fatal or :info. Defaults to :debug in the
    #   production environment and :debug otherwise.
    # :auto_flush::
    #   Whether the log should automatically flush after new messages are
    #   added. Defaults to true.
    # :format_datetime:: Format of datetime. Defaults to: "%d/%b/%Y %H:%M:%S"
    # :format_message:: Format of message. Defaults to: ""%s - - [%s] \"%s\"""
    def initialize(options={})
      @buffer            = []
      @auto_flush        = options.has_key?(:auto_flush) ? options[:auto_flush] : true
      @level             = options[:log_level] ? Levels[options[:log_level]] : Levels[:debug]
      @log               = options[:stream]  || $stdout
      @log.sync          = true
      @mutex             = @@mutex[@log] ||= Mutex.new
      @format_datetime   = options[:format_datetime] || "%d/%b/%Y %H:%M:%S"
      @format_message    = options[:format_message] || "%s - [%s] \"%s\""
    end

    # Flush the entire buffer to the log object.
    def flush
      return unless @buffer.size > 0
      @mutex.synchronize do
        @log.write(@buffer.slice!(0..-1).join(''))
      end
    end

    # Close and remove the current log object.
    def close
      flush
      @log.close if @log.respond_to?(:close) && !@log.tty?
      @log = nil
    end

    # Appends a message to the log. The methods yield to an optional block and
    # the output of this block will be appended to the message.
    #
    # ==== Parameters
    # message:: The message to be logged. Defaults to nil.
    #
    # ==== Returns
    # message:: The resulting message added to the log file.
    def push(message = nil, level = nil)
      self << @format_message % [level.to_s.upcase, Time.now.strftime(@format_datetime), message.to_s]
    end

    def <<(message = nil)
      message << "\n" unless message[-1] == ?\n
      @buffer << message
      flush if @auto_flush
      message
    end

    # Generate the logging methods for Padrino.logger for each log level.
    Levels.each_pair do |name, number|
      class_eval <<-LEVELMETHODS, __FILE__, __LINE__

      # Appends a message to the log if the log level is at least as high as
      # the log level of the logger.
      #
      # ==== Parameters
      # message:: The message to be logged. Defaults to nil.
      #
      # ==== Returns
      # self:: The logger object for chaining.
      def #{name}(message = nil)
        if #{number} >= level
          message = block_given? ? yield : message
          self.push(message, :#{name}) if #{number} >= level
        end
        self
      end

      # Appends a message to the log if the log level is at least as high as
      # the log level of the logger. The bang! version of the method also auto
      # flushes the log buffer to disk.
      #
      # ==== Parameters
      # message:: The message to be logged. Defaults to nil.
      #
      # ==== Returns
      # self:: The logger object for chaining.
      def #{name}!(message = nil)
        if #{number} >= level
          message = block_given? ? yield : message
          self.push(message, :#{name}) if #{number} >= level
          flush if #{number} >= level
        end
        self
      end

      # ==== Returns
      # Boolean:: True if this level will be logged by this logger.
      def #{name}?
        #{number} >= level
      end
      LEVELMETHODS
    end

  end
  
  # RackLogger forwards every request to an +app+ given, and
  # logs a line in the Apache common log format to the +logger+, or
  # rack.errors by default.
  class RackLogger
    # Common Log Format: http://httpd.apache.org/docs/1.3/logs.html#common
    # "lilith.local - - GET / HTTP/1.1 500 -"
    #  %{%s - %s %s %s%s %s - %d %s %0.4f}
    FORMAT = %{%s - %s %s %s%s %s - %d %s %0.4f}

    def initialize(app, logger=nil)
      @app = app
      @logger = logger
    end

    def call(env)
      began_at = Time.now
      status, header, body = @app.call(env)
      log(env, status, header, began_at)
      [status, header, body]
    end

    private

    def log(env, status, header, began_at)
      now = Time.now
      length = extract_content_length(header)

      logger = @logger || env['rack.errors']
      logger.debug FORMAT % [
        env['HTTP_X_FORWARDED_FOR'] || env["REMOTE_ADDR"] || "-",
        env["REMOTE_USER"] || "-",
        env["REQUEST_METHOD"],
        env["PATH_INFO"],
        env["QUERY_STRING"].empty? ? "" : "?"+env["QUERY_STRING"],
        env["HTTP_VERSION"],
        status.to_s[0..3],
        length,
        now - began_at ]
    end

    def extract_content_length(headers)
      headers.each do |key, value|
        if key.downcase == 'content-length'
          return value.to_s == '0' ? '-' : value
        end
      end
      '-'
    end
  end
end

# Define a logger aviable every where in our app
def logger
  Thread.current[:padrino_logger] ||= Padrino::setup_logger!
end