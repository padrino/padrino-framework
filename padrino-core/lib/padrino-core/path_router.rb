require 'padrino-core/path_router/error_handler'
require 'padrino-core/path_router/route'
require 'padrino-core/path_router/matcher'
require 'padrino-core/path_router/compiler'

module Padrino
  ##
  # Provides an HTTP router for use in path routing.
  #
  module PathRouter
    ##
    # Constructs an instance of PathRouter::Router.
    #
    def self.new
      Router.new
    end

    class Router
      attr_reader :current_order, :routes, :engine

      ##
      # Constructs an instance of PathRouter::Router.
      #
      def initialize
        reset!
      end

      ##
      # Adds a new route to routes.
      #
      def add(verb, path, options = {}, &block)
        route = Route.new(path, verb, options, &block)
        route.router = self
        @routes << route
        route
      end

      ##
      # Returns all routes which are matched with the condition
      #
      def call(request, &block)
        prepare! unless prepared?
        @engine.call_by_request(request, &block)
      end

      ##
      # Returns all routes which are matched with the condition without block
      #
      def recognize(request_or_env)
        prepare! unless prepared?
        @engine.find_by(request_or_env)
      end

      ##
      # Finds a path which is matched with conditions from arguments
      #
      def path(name, *args)
        params = args.last.is_a?(Hash) ? args.pop : {}
        candidates = @routes.select { |route| route.name == name }
        fail InvalidRouteException if candidates.empty?
        route = candidates.sort_by! { |route|
          (params.keys.map(&:to_s) - route.matcher.names).length }.shift
        matcher = route.matcher
        params_for_expand = params.dup
        if !args.empty? && matcher.mustermann?
          matcher.names.each_with_index do |matcher_name, index|
            params_for_expand[matcher_name.to_sym] ||= args[index]
          end
        end
        matcher.mustermann? ? matcher.expand(params_for_expand) : route.path_for_generation
      end

      ##
      # Recognizes route and expanded params from a path.
      #
      def recognize_path(path_info)
        prepare! unless prepared?
        route = @engine.find_by_pattern(path_info).first
        [route.name, route.params_for(path_info, {})]
      end

      ##
      # Resets all routes, current order and preparation.
      #
      def reset!
        @routes = []
        @current_order = 0
        @prepared = nil
      end

      ##
      # Increments the order.
      #
      def increment_order
        @current_order += 1
      end

      ##
      # Constructs an instance of PathRouter::Compiler,
      # and sorts all routes by using the order.
      #
      def prepare!
        @engine = Compiler.new(@routes)
        @prepared = true
        return if @current_order.zero?
        @routes.sort_by!(&:order)
      end

      private

      ##
      # Returns true if the router has been prepared.
      #
      def prepared?
        !!@prepared
      end
    end
  end
end
