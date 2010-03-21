module Padrino
  ##
  # This module extend Sinatra::ShowExceptions adding Padrino as "Framework"
  #
  module ShowExceptions

    def self.included(base)
      base.alias_method_chain :frame_class, :padrino
    end

    def frame_class_with_padrino(frame)
      if frame.filename =~ /lib\/sinatra.*\.rb|lib\/padrino.*\.rb/
        "framework"
      elsif (defined?(Gem) && frame.filename.include?(Gem.dir)) ||
            frame.filename =~ /\/bin\/(\w+)$/ ||
            frame.filename =~ /Ruby\/Gems/
        "system"
      else
        "app"
      end
    end
  end # ShowExceptions
end # Padrino

Sinatra::ShowExceptions.send(:include, Padrino::ShowExceptions)