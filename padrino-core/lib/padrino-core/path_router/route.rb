module Padrino
  module PathRouter
    class Route
      attr_accessor :name, :capture, :order, :options

      attr_reader :verb, :block

      attr_writer :router

      attr_accessor :action, :cache, :cache_key, :cache_expires,
                    :parent, :use_layout, :controller, :user_agent, :path_for_generation
  
  
      def initialize(path, verb, **options, &block)
        @path, @verb = path, verb
        @capture = {}
        @order   = 0
        @block   = block if block_given?
        merge_with_options!(options)
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
                                        :default_values => options[:default_values])
      end

      def match(pattern)
        matcher.match(pattern)
      end
  
      def to(&block)
        @block = block if block_given?
        @order = @router.current_order
        @router.increment_order
      end
  
      def path(*args)
        return @path if args.empty?
        params = args[0]
        params.delete(:captures)
        matcher.expand(params) if matcher.mustermann?
      end

      def params_for(pattern, **parameters)
        match_data, params = match(pattern), {}
        if match_data.names.empty?
          params.merge!(:captures => match_data.captures) unless match_data.captures.empty?
          params
        else
          params = matcher.handler.params(pattern, :captures => match_data) || params
          params.with_indifferent_access.merge(parameters){|key, old, new| old || new }
        end
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

      private
  
      def merge_with_options!(options)
        @options = {} unless @options
        options.each_pair do |key, value|
          accessor?(key) ? __send__("#{key}=", value) : (@options[key] = value)
        end
      end
  
      def accessor?(key)
        respond_to?("#{key}=") && respond_to?(key)
      end
    end
  end
end
