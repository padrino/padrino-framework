require 'win32console' if RUBY_PLATFORM =~ /(win|m)32/      # ruby color support for win

##
# Add colors
#
class String
  # colorize(:red)
  def colorize(color)
    Colorizer.send(color, self)
  end

  # Used to colorize strings for the shell
  class Colorizer
    # Returns colors integer mapping
    def self.colors
      @_colors ||= {
        :clear   => 0,
        :bold    => 1,
        :black   => 30,
        :red     => 31,
        :green   => 32,
        :yellow  => 33,
        :blue    => 34,
        :magenta => 35,
        :cyan    => 36,
        :white   => 37
      }
    end

    # Defines class level color methods
    # i.e  Colorizer.red("hello")
    class << self
      Colorizer.colors.each do |color, value|
        define_method(color) do |target|
          "\e[#{value}m" << target << "\e[0m"
         end
      end
    end
  end
end
