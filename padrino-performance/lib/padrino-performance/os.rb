module Padrino
  module Performance
    # OS detection useful for targeting CLI commands
    # Source: http://stackoverflow.com/questions/170956/how-can-i-find-which-operating-system-my-ruby-program-is-running-on
    module OS
      def self.windows?
        (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
      end

      def self.mac?
       (/darwin/ =~ RUBY_PLATFORM) != nil
      end

      def self.unix?
        !self.windows?
      end

      def self.linux?
        self.unix? and not self.mac?
      end
    end # OS
  end # Performance
end # Padrino
