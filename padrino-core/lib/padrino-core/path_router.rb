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
        @prepare_lock = Mutex.new
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
        prepared_engine.call_by_request(request, &block)
      end

      ##
      # Returns all routes which are matched with the condition without block
      #
      def recognize(request_or_env)
        prepared_engine.find_by(request_or_env)
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
      # Recognizes route and expanded params from a path, or returns nil when no route matches it.
      #
      def recognize_path(path_info)
        route, params = prepared_engine.recognize_path(path_info)
        [route.name, params] if route
      end

      ##
      # Resets all routes, current order and preparation.
      #
      def reset!
        @prepare_lock.synchronize do
          @named_routes = nil
          @routes = []
          @current_order = 0
          @engine = nil
          @prepared = nil
        end
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
        @prepare_lock.synchronize { prepare_unlocked! }
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
      # The routes by name, in the order of +routes+, rebuilt when +routes+ changes size so
      # that a route added to or deleted from +routes+ directly is seen.
      # ceiling: a direct edit that keeps the size (one route swapped for another) isn't seen,
      # nor is a rename of a route this router shares with, or took from, another router;
      # rebuild on every call if that has to work.
      #
      def named_routes
        size = @routes.size
        memo = @named_routes
        return memo[1] if memo && memo[0] == size

        # A route pushed onto +routes+ directly has no router; give it this one, so that
        # renaming it clears this index.
        @routes.each { |route| route.adopt(self) }
        by_name = @routes.group_by(&:name).freeze
        @named_routes = [size, by_name].freeze
        by_name
      end

      ##
      # Returns the compiled engine, preparing and compiling once under @prepare_lock.
      #
      def prepared_engine
        return @engine if @prepared

        @prepare_lock.synchronize do
          prepare_unlocked! unless @prepared
          @engine
        end
      end

      def prepare_unlocked!
        unless @current_order.zero?
          @routes.sort_by!(&:order)
          @named_routes = nil
        end
        engine = Compiler.new(@routes)
        engine.compile!
        @engine = engine
        @prepared = true
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
