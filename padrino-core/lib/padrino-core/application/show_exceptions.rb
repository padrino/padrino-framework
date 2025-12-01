module Padrino
  ##
  # This module extend Sinatra::ShowExceptions adding Padrino as "Framework".
  #
  # @private
  class ShowExceptions < Sinatra::ShowExceptions
    private

    def frame_class(frame)
      if frame.filename =~ %r{lib/sinatra.*\.rb|lib/padrino.*\.rb}
        'framework'
      elsif (defined?(Gem) && frame.filename.include?(Gem.dir)) || frame.filename =~ %r{/bin/(\w+)$|Ruby/Gems}
        'system'
      else
        'app'
      end
    end
  end
end
