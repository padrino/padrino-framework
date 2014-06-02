module Padrino
  module PathRouter
    class ErrorHandler < StandardError

      def self.set(key, value)
        settings[key] = value
      end

      def self.settings
        @settings ||= {}
      end

      def call
        roadmap.map.with_index do |key, index|
          settings[key] || default_response[index]
        end
      end

      private

      def roadmap
        [:status, :headers, :body]
      end

      def default_response
        @default_response ||= [404, {'Content-Type' => 'text/html'}, ["Not Found"]]
      end

      def settings
        self.class.settings
      end
    end

    InvalidRouteException = Class.new(ArgumentError)
    NotFound              = Class.new(ErrorHandler)
    
    class MethodNotAllowed < ErrorHandler
      set :status, 405
      set :body, ["MethodNotAllowed"]

      def initialize(verbs)
        default_response[1].merge!("Allow" => verbs.map{|verb| verb.upcase } * ", ")
      end
    end

    class BadRequest < ErrorHandler
      set :status, 400
      set :body, ["Bad Request"]
    end
  end
end
