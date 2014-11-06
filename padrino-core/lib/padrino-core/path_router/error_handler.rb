module Padrino
  module PathRouter
    ##
    # The ErrorHandler class is to handle two exception codes.
    #
    class ErrorHandler < StandardError
      ##
      # Defines setting keys to refer from ErrorHandler#call.
      #
      ROADMAP = [:status, :headers, :body].freeze

      ##
      # Set value to the settings.
      #
      def self.set(key, value)
        settings[key] = value
      end

      ##
      # Returns a hash for the settings.
      #
      def self.settings
        @settings ||= {}
      end

      ##
      # Returns an array which is like rack-response style.
      # It is for use in Routing#route!.
      #
      def call
        roadmap.map.with_index do |key, index|
          settings[key] || default_response[index]
        end
      end

      private

      ##
      # @see PathRouter::ErrorHandler::ROADMAP.
      #
      def roadmap
        ROADMAP
      end

      ##
      # Returns default response value.
      #
      def default_response
        @default_response ||= [404, {'Content-Type' => 'text/html'}, ["Not Found"]]
      end

      ##
      # @see PathRouter::ErrorHandler.settings
      def settings
        self.class.settings
      end
    end

    ##
    # @see PathRouter::Router#path
    #
    InvalidRouteException = Class.new(ArgumentError)

    ##
    # This is for use in 404 error response.
    #
    NotFound = Class.new(ErrorHandler)
    

    ##
    # This is for use in 405 error response.
    #
    class MethodNotAllowed < ErrorHandler
      set :status, 405
      set :body, ["Method Not Allowed"]

      def initialize(verbs)
        default_response[1].merge!("Allow" => verbs.map{|verb| verb.upcase } * ", ")
      end
    end
  end
end
