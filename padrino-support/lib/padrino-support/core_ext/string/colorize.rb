##
# Add colors
#
class String
  # colorize(:red)
  def colorize(args)
    case args
    when Symbol
      Colorizer.send(args, self)
    when Hash
      Colorizer.send(args[:color], self, args[:mode])
    end
  end

  # Used to colorize strings for the shell
  class Colorizer
    # Returns colors integer mapping
    def self.colors
      @_colors ||= {
        :default => 9,
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

    # Returns modes integer mapping
    def self.modes
      @_modes ||= {
        :default => 0,
        :bold    => 1
      }
    end

    # Defines class level color methods
    # i.e  Colorizer.red("hello")
    class << self
      Colorizer.colors.each do |color, value|
        define_method(color) do |target, mode_name = :default|
          mode = modes[mode_name] || modes[:default]
          "\e[#{mode};#{value}m" << target << "\e[0m"
         end
      end
    end
  end
end
