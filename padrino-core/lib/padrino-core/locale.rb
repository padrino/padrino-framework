module Padrino
  module Locale

    def self.extended(base)
      base.send(:include, ClassMethods)
    end

    module ClassMethods

      # Parse HTTP_ACCEPT_LANGUAGE and return array of user locales
      def languages
        langs = @env['HTTP_ACCEPT_LANGUAGE']
        return [] if langs.nil?
        locales = langs.split(',')
        locales.map! do |locale|
          locale = locale.split ';q='
          if 1 == locale.size
            [locale[0], 1.0]
          else
            [locale[0], locale[1].to_f]
          end
        end
        locales.sort! { |a, b| b[1] <=> a[1] }
        locales.map! { |i| i[0].split("-").first }
      end

    end
  end
end