module Padrino
  ##
  # Colors text for the shell with ANSI escape codes.
  #
  # @example
  #   Padrino::Colorizer.colorize('Hello', :red)        # => "\e[0;31mHello\e[0m"
  #   Padrino::Colorizer.colorize('Hello', :red, :bold) # => "\e[1;31mHello\e[0m"
  #
  module Colorizer
    # The color names and their ANSI codes.
    COLORS = {
      default: 9,
      black: 30,
      red: 31,
      green: 32,
      yellow: 33,
      blue: 34,
      magenta: 35,
      cyan: 36,
      white: 37
    }.freeze

    # The mode names and their ANSI codes.
    MODES = {
      default: 0,
      bold: 1
    }.freeze

    module_function

    ##
    # Returns a new string with +text+ wrapped in the codes for +color+ and +mode+.
    #
    # @param [#to_s] text
    #   The text to color.
    # @param [Symbol] color
    #   One of the {COLORS} names.
    # @param [Symbol] mode
    #   One of the {MODES} names; any other value uses +:default+.
    #
    # @return [String]
    #
    # @raise [KeyError] when +color+ (a Symbol or String) isn't one of the {COLORS} names.
    #
    def colorize(text, color, mode = :default)
      "\e[#{MODES[mode] || MODES[:default]};#{COLORS.fetch(color.is_a?(String) ? color.to_sym : color)}m#{text}\e[0m"
    end
  end
end
