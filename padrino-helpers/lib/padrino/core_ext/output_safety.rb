if defined?(ActiveSupport::SafeBuffer)
  module Padrino
    SafeBuffer = ActiveSupport::SafeBuffer
  end
else
  require 'padrino/safe_buffer'

  class String
    def html_safe
      Padrino::SafeBuffer.new(self)
    end
  end

  class Object
    def html_safe?
      false
    end
  end

  class Numeric
    def html_safe?
      true
    end
  end
end

# The top-level SafeBuffer is deprecated: the file warns on first use, then defines it.
Object.autoload(:SafeBuffer, File.expand_path('top_level_safe_buffer.rb', __dir__)) unless Object.const_defined?(:SafeBuffer, false)
