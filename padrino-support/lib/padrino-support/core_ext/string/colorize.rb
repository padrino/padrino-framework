require 'padrino-support/colorizer'

##
# Add colors
#
class String
  # colorize(:red)
  #
  # @deprecated Use {Padrino::Colorizer.colorize}; String#colorize will be removed in Padrino 1.0.
  def colorize(args)
    Colorizer.deprecated
    case args
    when Symbol
      Padrino::Colorizer.colorize(self, args)
    when Hash
      Padrino::Colorizer.colorize(self, args[:color], args[:mode])
    end
  end

  # Used to colorize strings for the shell
  #
  # @deprecated Use {Padrino::Colorizer}; String::Colorizer will be removed in Padrino 1.0.
  class Colorizer
    # Returns colors integer mapping
    def self.colors
      deprecated
      Padrino::Colorizer::COLORS
    end

    # Returns modes integer mapping
    def self.modes
      deprecated
      Padrino::Colorizer::MODES
    end

    # Defines class level color methods
    # i.e  Colorizer.red("hello")
    Padrino::Colorizer::COLORS.each_key do |color|
      define_singleton_method(color) do |target, mode_name = :default|
        deprecated
        Padrino::Colorizer.colorize(target, color, mode_name)
      end
    end

    # Warns the first time a process uses String#colorize or String::Colorizer, naming the
    # caller of the deprecated method.
    # @api private
    def self.deprecated
      return if Padrino.instance_variable_defined?(:@_string_colorize_warned)

      Padrino.instance_variable_set(:@_string_colorize_warned, true)
      location = caller_locations(2, 1).first
      # Warning.warn prints even while $VERBOSE is nil, as it is while the reloader loads app files.
      Warning.warn 'WARNING! String#colorize and String::Colorizer are deprecated and will be removed in Padrino 1.0. ' \
                   "Use Padrino::Colorizer.colorize(text, color, mode) instead (first used at #{location.path}:#{location.lineno}).\n"
    end
  end
end
