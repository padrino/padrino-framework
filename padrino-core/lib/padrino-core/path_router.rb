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
        @named_routes = nil
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
        candidates = named_routes[name]
        raise InvalidRouteException unless candidates
        route = candidates.first
        # Candidates that all take the same params (a GET and its HEAD) rank in their order.
        unless candidates.all? { |candidate| candidate.matcher.names == route.matcher.names }
          keys = params.keys.map(&:to_s)
          # Tries to find the route that matches more, but with fewer names, in stable order
          route = candidates.each_with_index.min_by do |candidate, i|
            [(keys - candidate.matcher.names).length, candidate.matcher.names.size, i]
          end.first
        end
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
        @named_routes = nil
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
        @named_routes = nil
      end

      ##
      # Forgets the routes by name, after a route was added, sorted or renamed.
      #
      # @api private
      def named_routes_changed!
        @named_routes = nil
      end

      private

      ##
      # The routes by name, in the order of +routes+.
      #
      def named_routes
        @named_routes ||= @routes.group_by(&:name)
      end

      ##
      # Returns true if the router has been prepared.
      #
      def prepared?
        !!@prepared
      end
    end
  end
end
