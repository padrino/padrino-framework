module Padrino
  module PathRouter
    class Route
      attr_accessor :block, :capture, :router, :name, :order,
                    :default_values, :path_for_generation, :verb
      attr_accessor :action, :cache, :cache_key, :cache_expires,
                    :parent, :use_layout, :controller, :user_agent
  
  
      def initialize(path, &block)
        @path    = path
        @capture = {}
        @order   = 0
        @block   = block if block_given?
      end
  
      def before_filters(&block)
        @_before_filters ||= []
        @_before_filters << block if block_given?
        @_before_filters
      end

      def after_filters(&block)
        @_after_filters ||= []
        @_after_filters << block if block_given?
        @_after_filters
      end
  
      def custom_conditions(&block)
        @_custom_conditions ||= []
        @_custom_conditions << block if block_given?
        @_custom_conditions
      end
  
      def call(app, *args)
        @block.call(app, *args)
      end
  
      def request_methods
        [verb.to_s.upcase]
      end
  
      def original_path
        @path
      end
  
      def significant_variable_names
        @significant_variable_names ||= if @path.is_a?(String)
          @path.scan(/(^|[^\\])[:\*]([a-zA-Z0-9_]+)/).map{|p| p.last.to_sym}
        elsif @path.is_a?(Regexp) and @path.respond_to?(:named_captures)
          @path.named_captures.keys.map(&:to_sym)
        else
          []
        end
      end
  
      def matcher
        @matcher ||= Matcher.new(@path, :capture => @capture,
                                        :default_values => @default_values)
      end
  
      def to(&block)
        @block = block if block_given?
        @order = @router.current_order
        @router.increment_order
      end
      alias block= to
  
      def path(*args)
        return @path if args.empty?
        params = args[0]
        params.delete(:captures)
        matcher.expand(params) if matcher.mustermann?
      end
    end
  end
end
