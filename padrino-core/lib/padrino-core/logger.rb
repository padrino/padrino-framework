require 'logger'
module Padrino
  class Logger < Logger

    # Logging date-time format (string passed to strftime)
    # Default: "%d/%b/%Y %H:%M:%S"
    def self.format_datetime=(format)
      @_format_datetime = format
    end

    # Format of message
    # Default: "%s - - [%s] \"%s\"\n"
    def self.format_message=(format)
      @_format_message = format
    end

    # Return a formatted (like rack commonlogger) 
    # Example:
    #   INFO - - [23/Nov/2009 12:02:29] "My Message"
    #   # logger.info "My Message"
    def format_message(severity, datetime, progname, msg)
      @_format_message  ||= "%s - - [%s] \"%s\"\n"
      @_format_datetime ||= "%d/%b/%Y %H:%M:%S"
      @_format_message % [ severity, datetime.strftime(@_format_datetime), msg ]
    end
  end
end