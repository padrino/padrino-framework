module Padrino
  module Mailer
    ##
    # Handles MIME type declarations for mail delivery.
    #
    module Mime
      ##
      # Returns Symbol with mime type if found, otherwise use +fallback+.
      # +mime+ should be the content type like "text/plain"
      # +fallback+ may be any symbol.
      #
      # Also see the documentation for {MIME_TYPES}.
      #
      # @param [String] mime
      #   The mime alias to fetch (i.e 'text/plain').
      # @param [Symbol] fallback
      #   The fallback mime to use if +mime+ doesn't exist.
      #
      # @example
      #   Padrino::Mailer::Mime.mime_type('text/plain')
      #   # => :plain
      #   Padrino::Mailer::Mime.mime_type('text/html')
      #   # => :html
      #
      # This is a shortcut for:
      #
      #   Padrino::Mailer::Mime::MIME_TYPES.fetch('text/plain', :plain)
      #
      def self.mime_type(mime, fallback=:plain)
        MIME_TYPES.fetch(mime.to_s.split(';').first.to_s.downcase, fallback)
      end

      ##
      # List of common mime-types, selected from various sources
      # according to their usefulness for an email scope.
      #
      # You can add your own mime types like:
      #
      #   Padrino::Mailer::Mime::MIME_TYPES.merge!("text/xml" => :xml)
      #
      MIME_TYPES = {
        "text/html"  => :html,
        "text/plain" => :plain,
        "text/xml"   => :xml
      }
    end
  end
end
