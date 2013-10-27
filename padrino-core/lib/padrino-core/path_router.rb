require 'mustermann'
require 'rack'

module Padrino
  module PathRouter
    class InvalidRouteException < StandardError; end

    class NotFound < StandardError
      def response
        [404, {}, ["Not Found"]]
      end
    end

    class MethodNotAllowed < StandardError
      def initialize(accepts)
        @accepts = accepts
      end

      def response
        headers = {}
        headers['Allow'] = @accepts
        [405, headers, ["MethodNotAllowed"]]
      end
    end

    def self.new
      Base.new
    end

    class Base
      attr_reader :current_order, :routes
      HTTP_VERBS       = [:get, :post, :delete, :put, :head]
      RESPONSE_HEADERS = {
        :bad_request        => 400,
        :not_found          => 404,
        :method_not_allowed => 405,
        :server_error       => 500
      }

      def initialize
        reset!
      end

      def add(verb, path, options = {}, &block)
        route = Route.new(path, &block)
        route.verb = verb.downcase.to_sym
        route.router = self
        route.path_for_generation = options[:path_for_generation] if options[:path_for_generation]
        @routes << route
        route
      end

      def call(env)
        request = Request.new(env)
        return bad_request unless HTTP_VERBS.include?(request.request_method.downcase.to_sym)
        compile unless compiled?
        matched_routes = recognize(request)
        [200, {}, matched_routes]
      end

      def compiled?
        @compiled
      end

      def compile
        @compiled = true
        return if @current_order.zero?
        @routes.sort!{|a, b| a.order <=> b.order }
      end

      def path(name, *args)
        params = args.delete_at(args.last.is_a?(Hash) ? -1 : 0) || {}
        saved_args = args.dup
        @routes.each do |route|
          next unless route.name == name
          matcher = route.matcher
          if !args.empty? and matcher.mustermann?
            matcher_names = matcher.names
            params_for_expand = Hash[matcher_names.map{|matcher_name|
              [matcher_name.to_sym, (params[matcher_name.to_sym] || args.shift)]
            }]
            params_for_expand.merge!(Hash[params.select{|k, v| !matcher_names.include?(name.to_sym) }])
            args = saved_args.dup
          else
            params_for_expand = params.dup
          end
          return matcher.mustermann? ? matcher.expand(params_for_expand) : route.path_for_generation
        end
        raise InvalidRouteException
      end

      def recognize(request)
        path_info, verb, request_params = parse_request(request)
        ignore_slash_path_info = path_info
        ignore_slash_path_info = path_info[0..-2] if path_info != "/" and path_info[-1] == "/"

        matched_routes = scan_routes(path_info, ignore_slash_path_info)
        raise NotFound if matched_routes.empty?
  
        result = matched_routes.map{|route|
          next unless verb == route.verb
          params, matcher = {}, route.matcher
          match_data = matcher.match(matcher.mustermann? ? ignore_slash_path_info : path_info)
          if match_data.names.empty?
            params[:captures] = match_data.captures
          else
            params.merge!(match_data.names.inject({}){|result, name|
              result[name.to_sym] = match_data[name] ? Rack::Utils.unescape(match_data[name]) : nil
              result
            }).merge!(request_params){|key, self_value, new_value| self_value || new_value }
          end
          [route, params.with_indifferent_access]
        }.compact

        result.empty? ? (raise MethodNotAllowed.new(matched_routes.map(&:verb))) : result
      end

      def recognize_path(path_info)
        response = recognize(Rack::MockRequest.env_for(path_info))
        route, params = response.first
        [route.name, params]
      end

      def reset!
        @routes = []
        @current_order = 0
      end

      def increment_order
        @current_order += 1
      end

      private

      def scan_routes(path_info, ignore_slash_path_info)
        @routes.select do |route|
          matcher = route.matcher
          matcher.match(matcher.mustermann? ? ignore_slash_path_info : path_info)
        end
      end

      def parse_request(request)
        if request.is_a?(Hash)
          [request['PATH_INFO'], request['REQUEST_METHOD'].downcase.to_sym, {}]
        else
          [request.path_info, request.request_method.downcase.to_sym, parse_request_params(request.params)]
        end
      end

      def parse_request_params(params)
        params.inject({}) do |result, entry|
          result[entry[0].to_sym] = entry[1]
          result
        end
      end
    end

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
  
    class Matcher
      def initialize(path, options = {})
        @path = path.is_a?(String) && path.empty? ? "/" : path
        @capture = options.delete(:capture)
        @default_values = options.delete(:default_values)
      end
  
      def match(pattern)
        handler.match(pattern)
      end
  
      def expand(params)
        params = params.dup
        query = params.keys.inject({}) do |result, key|
          result[key] = params.delete(key) if !handler.names.include?(key.to_s)
          result
        end
        params.merge!(@default_values) if @default_values.is_a?(Hash)
        expanded_path = handler.expand(params)
        expanded_path = expanded_path + "?" + query.map{|k,v| "#{k}=#{v}" }.join("&") unless query.empty?
        expanded_path
      end
  
      def mustermann?
        handler.class == Mustermann::Rails
      end
  
      def handler
        @handler ||= case @path
        when String
          Mustermann.new(@path, :type => :rails, :capture => @capture)
        when Regexp
          /^(?:#{@path})$/
        end
      end
  
      def to_s
        handler.to_s
      end
  
      def names
        handler.names.map(&:to_sym)
      end
    end
  
    class Request < Rack::Request
      attr_accessor :acceptable_methods
    end
  end
end
