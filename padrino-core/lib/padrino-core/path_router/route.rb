module Padrino
  module PathRouter
    class Route
      ##
      # The accessors are useful to access from PathRouter::Router
      #
      attr_accessor :name, :capture, :order, :options, :index, :regexp

      ##
      # A reader for compile option
      #
      attr_reader :verb, :block

      ##
      # The router will be treated in this class
      #
      attr_writer :router

      ##
      # The accessors will be used in other classes
      #
      attr_accessor :action, :cache, :cache_key, :cache_expires,
                    :parent, :use_layout, :controller, :user_agent, :path_for_generation, :default_values
  
      ##
      # Constructs an instance of PathRouter::Route.
      #
      def initialize(path, verb, options = {}, &block)
        @path = path
        @verb = verb
        @capture = {}
        @order   = 0
        @block   = block if block_given?
        merge_with_options!(options)
      end
  
      ##
      # Calls the route block with arguments.
      #
      def call(app, *args)
        @block.call(app, *args)
      end
  
      ##
      # Returns the route's verb as an array.
      #
      def request_methods
        [verb.to_s.upcase]
      end
  
      ##
      # Returns the original path.
      #
      def original_path
        @path
      end
  
      SIGNIFICANT_VARIABLES_REGEX = /(^|[^\\])[:\*]([a-zA-Z0-9_]+)/.freeze

      ##
      # Returns signficant variable names.
      #
      def significant_variable_names
        @significant_variable_names ||=
          if @path.is_a?(String)
            @path.scan(SIGNIFICANT_VARIABLES_REGEX).map(&:last)
          elsif @path.is_a?(Regexp) and @path.respond_to?(:named_captures)
            @path.named_captures.keys
          else
            []
          end
      end
  
      ##
      # Returns an instance of PathRouter::Matcher that is associated with the route.
      #
      def matcher
        @matcher ||= Matcher.new(@path, :capture => @capture, :default_values => default_values)
      end

      ##
      # @see PathRouter::Matcher#match
      #
      def match(pattern)
        matcher.match(pattern)
      end
  
      ##
      # Associates a block with the route, and increments current order of the router.
      #
      def to(&block)
        @block = block if block_given?
        @order = @router.current_order
        @router.increment_order
      end
  
      ##
      # Expands the path by using parameters.
      # @see PathRouter::Matcher#expand
      #
      def path(*args)
        return @path if args.empty?
        params = args[0].dup
        params.delete(:captures)
        matcher.expand(params) if matcher.mustermann?
      end

      ##
      # Overwrites path value by passing new path string.
      #
      def path=(pattern)
        @path = pattern
        @matcher = nil
        @significant_variable_names = nil
      end

      ##
      # Returns parameters which is created by the matcher.
      #
      def params_for(pattern, others = {})
        matcher.params_for(pattern, others)
      end
  
      ##
      # Returns before_filters as an array.
      #
      def before_filters(&block)
        @_before_filters ||= []
        @_before_filters << block if block_given?
        @_before_filters
      end

      ##
      # Returns after_filters as an array.
      #
      def after_filters(&block)
        @_after_filters ||= []
        @_after_filters << block if block_given?
        @_after_filters
      end
  
      ##
      # Returns custom_conditions as an array.
      #
      def custom_conditions(&block)
        @_custom_conditions ||= []
        @_custom_conditions << block if block_given?
        @_custom_conditions
      end

      ##
      # Returns block parameter length.
      #
      def block_parameter_length
        matcher.capture_length
      end

      private
  
      ##
      # Set value to accessor if option name has been defined as an accessora.
      #
      def merge_with_options!(options)
        @options ||= {}
        options.each_pair do |key, value|
          accessor?(key) ? __send__("#{key}=", value) : (@options[key] = value)
        end
      end
  
      ##
      # Returns true if name has been defined as an accessor.
      #
      def accessor?(key)
        respond_to?("#{key}=") && respond_to?(key)
      end
    end
  end
end
