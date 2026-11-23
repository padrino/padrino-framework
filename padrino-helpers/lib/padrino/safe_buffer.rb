require 'cgi/escape'

module Padrino
  ##
  # Padrino::SafeBuffer is based on ActiveSupport::SafeBuffer
  #
  class SafeBuffer < String
    UNSAFE_STRING_METHODS = %w[
      capitalize chomp chop delete delete_prefix delete_suffix downcase encode
      gsub lstrip next reverse rstrip scrub slice squeeze strip sub succ
      swapcase tr tr_s unicode_normalize upcase
    ]

    alias original_concat concat
    private :original_concat

    class SafeConcatError < StandardError
      def initialize
        super 'Could not concatenate to the buffer because it is not html safe.'
      end
    end

    def [](*args)
      if args.size < 2
        super
      elsif html_safe?
        new_safe_buffer = super
        new_safe_buffer&.instance_variable_set :@html_safe, true
        new_safe_buffer
      else
        to_str[*args]
      end
    end

    def safe_concat(value)
      raise SafeConcatError unless html_safe?
      original_concat(value)
    end

    def initialize(str = '')
      @html_safe = true
      super
    end

    def initialize_copy(other)
      super
      @html_safe = other.html_safe?
    end

    def clone_empty
      self[0, 0]
    end

    def concat(value)
      super(html_escape_interpolated_argument(value))
    end
    alias << concat

    def prepend(value)
      super(html_escape_interpolated_argument(value))
    end

    def insert(index, value)
      super(index, html_escape_interpolated_argument(value))
    end

    def []=(*args)
      args[-1] = html_escape_interpolated_argument(args[-1]) unless args.empty?
      super(*args)
    end

    def replace(value)
      super(html_escape_interpolated_argument(value))
    end

    def setbyte(index, integer)
      @html_safe = false
      super
    end

    if String.method_defined?(:bytesplice)
      def bytesplice(*args)
        @html_safe = false
        super
      end
    end

    if String.method_defined?(:append_as_bytes)
      def append_as_bytes(*args)
        @html_safe = false
        super
      end
    end

    def +(other)
      dup.concat(other)
    end

    def %(other)
      escaped_args =
        case other
        when Hash
          other.transform_values { |arg| html_escape_interpolated_argument(arg) }
        else
          Array(other).map { |arg| html_escape_interpolated_argument(arg) }
        end

      self.class.new(super(escaped_args))
    end

    def html_safe?
      defined?(@html_safe) && @html_safe
    end

    def to_s
      self
    end

    def to_param
      to_str
    end

    def encode_with(coder)
      coder.represent_object nil, to_str
    end

    UNSAFE_STRING_METHODS.each do |unsafe_method|
      next unless unsafe_method.respond_to?(unsafe_method)

      class_eval <<~RUBY, __FILE__, __LINE__ + 1
        def #{unsafe_method}(...)        # def capitalize(...)
          to_str.#{unsafe_method}(...)   #   to_str.capitalize(...)
        end                              # end

        def #{unsafe_method}!(...)       # def capitalize!(...)
          @html_safe = false             #   @html_safe = false
          super(...)                     #   super(...)
        end                              # end
      RUBY
    end

    private

    def html_escape_interpolated_argument(arg)
      !html_safe? || arg.html_safe? ? arg : CGI.escapeHTML(arg.to_s)
    end
  end
end
