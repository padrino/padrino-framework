module Padrino
  unless defined?(PADRINO_IGNORE_CALLERS)
    # List of callers in a Padrino application that should be ignored as part of a stack trace.
    PADRINO_IGNORE_CALLERS = [
      *Sinatra::Base.callers_to_ignore,                            # Inherit Sinatra's default ignore patterns
      Regexp.new(Regexp.escape(RbConfig::CONFIG['rubylibdir'])),   # Ignore the Ruby standard lib path
      %r{lib/padrino-.*$},
      %r{/padrino-.*/(lib|bin)},
      %r{/bin/padrino$},
      %r{lib/rack.*\.rb$},
      %r{lib/mongrel.*\.rb$},
      %r{lib/shotgun.*\.rb$},
      %r{bin/shotgun$},
      %r{shoulda/context\.rb$},
      %r{mocha/integration},
      %r{test/unit},
      /rake_test_loader\.rb/,
      /custom_require\.rb$/,
      %r{/thor}
    ]

    ##
    # Add rubinius (and hopefully other VM implementations) ignore patterns ...
    #
    PADRINO_IGNORE_CALLERS.concat(RUBY_IGNORE_CALLERS) if defined?(RUBY_IGNORE_CALLERS)
  end

  ##
  # The filename for the file that is the direct caller (first caller).
  #
  # @return [String]
  #   The file the caller method exists in.
  #
  def self.first_caller
    caller_files.first
  end

  #
  # Like +Kernel#caller+ but excluding certain magic entries and without
  # line / method information; the resulting array contains filenames only.
  #
  # @return [Array<String>]
  #   The files of the calling methods.
  #
  def self.caller_files
    caller(1).each_with_object([]) do |line, result|
      file, _ = line.split(/:(?=\d|in )/)[0, 2]
      result << file unless PADRINO_IGNORE_CALLERS.any? { |pattern| file =~ pattern }
    end
  end
end
