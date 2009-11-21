module Padrino
  PADRINO_IGNORE_CALLERS = [
    /\/padrino-.*$/,            # all padrino code
    /\/sinatra/,                # all sinatra code
    /lib\/tilt.*\.rb$/,         # all tilt code
    /\(.*\)/,                   # generated code
    /custom_require\.rb$/,      # rubygems require hacks
    /active_support/,           # active_support require hacks
    /\/thor/,                   # thor require hacks
  ]

  # add rubinius (and hopefully other VM impls) ignore patterns ...
  PADRINO_IGNORE_CALLERS.concat(RUBY_IGNORE_CALLERS) if defined?(RUBY_IGNORE_CALLERS)

  # Returns the filename for the file that is the direct caller (first caller)
  def self.first_caller
    caller_files.first
  end

  # Like Kernel#caller but excluding certain magic entries and without
  # line / method information; the resulting array contains filenames only.
  def self.caller_files
    caller_locations.map { |file,line| file }
  end

  def self.caller_locations
    caller(1).
      map    { |line| line.split(/:(?=\d|in )/)[0,2] }.
      reject { |file,line| PADRINO_IGNORE_CALLERS.any? { |pattern| file =~ pattern } }
  end
end
