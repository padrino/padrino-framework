module Padrino
  module PathRouter
    class Recognizer
      def initialize(routes)
        @routes = routes
      end
  
      def call(request)
        pattern, verb, params = parse_request(request)
        raise_exception(400) unless valid_verb?(verb)
        fetch(pattern, verb){|route| [route, route.params_for(pattern, params)] }
      end
  
      private
  
      def valid_verb?(verb)
        PathRouter::Base::HTTP_VERBS.include?(verb.downcase.to_sym)
      end
  
      def fetch(pattern, verb)
        _routes = @routes.select{|route| route.match(pattern) }
        raise_exception(404) if _routes.empty?
        result = _routes.map{|route| yield(route) if verb == route.verb }.compact
        raise_exception(405, verbs: _routes.map(&:verb)) if result.empty?
        result
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
  
      def raise_exception(error_code, **options)
        raise ->(error_code) {
          case error_code
          when 400
            BadRequest
          when 404
            NotFound
          when 405
            MethodNotAllowed.new(options[:verbs])
          end
        }.call(error_code)
      end
    end
  end
end
