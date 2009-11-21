module Padrino
  module Helpers
    module FormatHelpers

      # Returns escaped text to protect against malicious content
      def escape_html(text)
        Rack::Utils.escape_html(text)
      end
      alias h escape_html
      alias sanitize_html escape_html

      # Returns escaped text to protect against malicious content
      # Returns blank if the text is empty
      def h!(text, blank_text = '&nbsp;')
        return blank_text if text.nil? || text.empty?
        h text
      end


      # Smart time helper which returns relative text representing times for recent dates
      # and absolutes for dates that are far removed from the current date
      # time_in_words(10.days.ago) => '10 days ago'
      def time_in_words(date)
        date = date.to_date
        date = Date.parse(date, true) unless /Date.*/ =~ date.class.to_s
        days = (date - Date.today).to_i

        return 'today'     if days >= 0 and days < 1
        return 'tomorrow'  if days >= 1 and days < 2
        return 'yesterday' if days >= -1 and days < 0

        return "in #{days} days"      if days.abs < 60 and days > 0
        return "#{days.abs} days ago" if days.abs < 60 and days < 0

        return date.strftime('%A, %B %e') if days.abs < 182
        return date.strftime('%A, %B %e, %Y')
      end
      alias time_ago time_in_words

      # Returns relative time in words referencing the given date
      # relative_time_ago(Time.now) => 'about a minute ago'
      def relative_time_ago(from_time)
        distance_in_minutes = (((Time.now - from_time.to_time).abs)/60).round
        case distance_in_minutes
          when 0..1 then 'about a minute'
          when 2..44 then "#{distance_in_minutes} minutes"
          when 45..89 then 'about 1 hour'
          when 90..1439 then "about #{(distance_in_minutes.to_f / 60.0).round} hours"
          when 1440..2879 then '1 day'
          when 2880..43199 then "#{(distance_in_minutes / 1440).round} days"
          when 43200..86399 then 'about 1 month'
          when 86400..525599 then "#{(distance_in_minutes / 43200).round} months"
          when 525600..1051199 then 'about 1 year'
          else "over #{(distance_in_minutes / 525600).round} years"
        end
      end

      # Used in xxxx.js.erb files to escape html so that it can be passed to javascript from Padrino
      # js_escape_html("<h1>Hey</h1>")
      def js_escape_html(html_content)
        return '' unless html_content
        javascript_mapping = { '\\' => '\\\\', '</' => '<\/', "\r\n" => '\n', "\n" => '\n' }
        javascript_mapping.merge("\r" => '\n', '"' => '\\"', "'" => "\\'")
        escaped_string = html_content.gsub(/(\\|<\/|\r\n|[\n\r"'])/) { javascript_mapping[$1] }
        "\"#{escaped_string}\""
      end

      alias escape_javascript js_escape_html
      alias escape_for_javascript js_escape_html

    end
  end
end
