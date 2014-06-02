require 'padrino-core/path_router/error_handler'
require 'padrino-core/path_router/route'
require 'padrino-core/path_router/matcher'
require 'padrino-core/path_router/recognizer'

module Padrino
  module PathRouter
    def self.new
      Base.new
    end

    class Base
      attr_reader :current_order, :routes

      HTTP_VERBS       = [:get, :post, :delete, :put, :head]

      def initialize
        reset!
      end

      def add(verb, path, options = {}, &block)
        route = Route.new(path, verb, options, &block)
        route.router = self
        @routes << route
        route
      end

      def call(env)
        request = Rack::Request.new(env)
        return bad_request unless HTTP_VERBS.include?(request.request_method.downcase.to_sym)
        matched_routes = recognize(request)
        [200, {}, matched_routes]
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
        prepare! unless prepared?
        @engine.call(request)
      end

      def recognize_path(path_info)
        route, params = recognize(Rack::MockRequest.env_for(path_info)).first
        [route.name, params]
      end

      def reset!
        @routes = []
        @current_order = 0
        @prepared = nil
      end

      def increment_order
        @current_order += 1
      end

      private

      def prepared?
        !!@prepared
      end

      def prepare!
        @engine = Recognizer.new(@routes)
        @prepared = true
        return if @current_order.zero?
        @routes.sort!{|a, b| a.order <=> b.order }
      end
    end
  end
end
