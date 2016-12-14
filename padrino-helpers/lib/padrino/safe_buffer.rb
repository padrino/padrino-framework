module Padrino
    ##
    # Padrino::SafeBuffer is based on ActiveSupport::SafeBuffer
    #
    class SafeBuffer < String
        UNSAFE_STRING_METHODS = %w(
            capitalize chomp chop delete downcase gsub lstrip next reverse rstrip
            slice squeeze strip sub succ swapcase tr tr_s upcase
        ).freeze

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
            else
                if html_safe?
                    new_safe_buffer = super

                    if new_safe_buffer
                        new_safe_buffer.instance_variable_set :@html_safe, true
                    end

                    new_safe_buffer
                else
                    to_str[*args]
                end
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

        def +(other)
            dup.concat(other)
        end

        def %(args)
            case args
            when Hash
                escaped_args = Hash[args.map { |k, arg| [k, html_escape_interpolated_argument(arg)] }]
            else
                escaped_args = Array(args).map { |arg| html_escape_interpolated_argument(arg) }
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
            class_eval <<-EOT, __FILE__, __LINE__ + 1
          def #{unsafe_method}(*args, &block)       # def capitalize(*args, &block)
            to_str.#{unsafe_method}(*args, &block)  #   to_str.capitalize(*args, &block)
          end                                       # end

          def #{unsafe_method}!(*args)              # def capitalize!(*args)
            @html_safe = false                      #   @html_safe = false
            super                                   #   super
          end                                       # end
            EOT
        end

        private

        def html_escape_interpolated_argument(arg)
            !html_safe? || arg.html_safe? ? arg : CGI.escapeHTML(arg.to_s)
        end
    end
end
