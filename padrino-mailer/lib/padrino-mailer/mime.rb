module Padrino
  module Mailer
    module Mime

      ##
      # Returns Symbol with mime type if found, otherwise use +fallback+.
      # +mime+ should be the content type like "text/plain"
      # +fallback+ may be any symbol
      #
      # Also see the documentation for MIME_TYPES
      #
      # ==== Examples
      #
      #   => :plain
      #   Padrino::Mailer::Mime.mime_type('text/plain')
      #   => :html
      #   Padrino::Mailer::Mime.mime_type('text/html')
      #
      # This is a shortcut for:
      #
      #   Padrino::Mailer::Mime::MIME_TYPES.fetch('text/plain', :plain)
      #
      def self.mime_type(mime, fallback=:plain)
        MIME_TYPES.fetch(mime.to_s.downcase, fallback)
      end

      # List of most common mime-types, selected various sources
      # according to their usefulness in a emailg scope for Ruby
      # users.
      #
      # You can add your own mime types like:
      #
      #   Padrino::Mailer::MIME_TYPES.merge!("text/xml" => :xml)
      #
      MIME_TYPES = {
        "text/html"  => :html,
        "text/plain" => :plain,
        "text/xml"   => :xml
      }
    end # Mime
  end # Mailer
end # Padrino