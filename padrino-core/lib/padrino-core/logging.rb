module Padrino
  ##
  # @return [Padrino::Logger]
  #
  # @example
  #   logger.debug "foo"
  #   logger.warn "bar"
  #
  def self.logger
    Padrino::Logger.setup! if Thread.current[:padrino_logger].nil?
    Thread.current[:padrino_logger]
  end

  ##
  # Set the padrino logger
  #
  # @param [Object] value
  #   an object that respond to <<, write, puts, debug, warn etc..
  #
  # @return [Object]
  #   the given value
  #
  # @example using ruby default logger
  #   require 'logger'
  #   Padrino.logger = Logger.new(STDOUT)
  #
  # @example using ActiveSupport
  #   require 'active_support/buffered_logger'
  #   Padrino.logger = Buffered.new(STDOUT)
  #
  def self.logger=(value)
    value.extend(Padrino::Logging::LoggingExtensions) unless (Padrino::Logging::LoggingExtensions === value)
    Thread.current[:padrino_logger] = value
  end

  module Logging
    ##
    # Ruby (standard) logger levels:
    #
    # :fatal:: An unhandleable error that results in a program crash
    # :error:: A handleable error condition
    # :warn:: A warning
    # :info:: generic (useful) information about system operation
    # :debug:: low-level information for developers
    # :devel:: Development-related information that is unnecessary in debug mode
    #
    Levels = {
      :fatal =>  7,
      :error =>  6,
      :warn  =>  4,
      :info  =>  3,
      :debug =>  0,
      :devel => -1,
    } unless const_defined?(:Levels)

    module LoggingExtensions

      ##
      # Generate the logging methods for {Padrino.logger} for each log level.
      #
      Padrino::Logging::Levels.each_pair do |name, number|
        define_method(name) do |*args|
          return if number < level
          if args.size > 1
            bench(*args)
          else
            push(args * '', name)
          end
        end

        define_method(:"#{name}?") do
          number >= level
        end
      end

      ##
      # Append a to development logger a given action with time
      #
      # @param [string] action
      #   The action
      #
      # @param [float] time
      #   Time duration for the given action
      #
      # @param [message] string
      #   The message that you want to log
      #
      # @example
      #   logger.bench 'GET', started_at, '/blog/categories'
      #   # => DEBUG - GET (0.056ms) - /blog/categories
      #
      def bench(action, began_at, message, level=:debug, color=:yellow)
        @_pad  ||= 8
        @_pad    = action.to_s.size if action.to_s.size > @_pad
        duration = Time.now - began_at
        color    = :red if duration > 1
        push "%s (" % colorize(action.to_s.upcase.rjust(@_pad), color) + colorize("%0.4fms", :bold, color) % duration + ") %s" % message.to_s, level
      end

      ##
      # Appends a message to the log. The methods yield to an optional block and
      # the output of this block will be appended to the message.
      #
      # @param [String] message
      #   The message that you want write to your stream
      #
      # @param [String] level
      #   The level one of :debug, :warn etc...
      #
      #
      def push(message = nil, level = nil)
        add(Levels[level], format(message, level))
      end

      ##
      # Formats the log message. This method is a noop and should be implemented by other
      # logger components such as {Padrino::Logger}.
      #
      # @param [String] message
      #   The message to format
      #
      # @param [String,Symbol] level
      #   The log level, one of :debug, :warn...
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
      #   The log level
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
        self.extend(ColorizedLogger)
      end
    end

    module ColorizedLogger
      # Colors for levels
      ColoredLevels = {
        :fatal => [:bold, :red],
        :error => [:red],
        :warn  => [:yellow],
        :info  => [:green],
        :debug => [:cyan],
        :devel => [:magenta]
      } unless defined?(ColoredLevels)

      ##
      # Colorize our level
      #
      # @param [String, Symbol] level
      #
      # @see Padrino::Logging::ColorizedLogger::ColoredLevels
      #
      def colorize(string, *colors)
        colors.each do |c|
          string = string.send(c)
        end
        string
      end

      def stylized_level(level)
        style = ColoredLevels[level].map { |c| "\e[%dm" % String.colors[c] } * ''
        [style, super, "\e[0m"] * ''
      end
    end
  end
end

module Kernel # @private
  ##
  # Define a logger available every where in our app
  #
  def logger
    Padrino.logger
  end
end # Kernel