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

      # Returns text transformed into HTML using simple formatting rules. Two or more consecutive newlines(\n\n) are considered
      # as a paragraph and wrapped in <p> tags. One newline (\n) is considered as a linebreak and a <br /> tag is appended.
      # This method does not remove the newlines from the text.
      # simple_format("hello\nworld") # => "<p>hello<br/>world</p>"
      def simple_format(text, html_options={})
        start_tag = tag('p', html_options.merge(:open => true))
        text = text.to_s.dup
        text.gsub!(/\r\n?/, "\n")                    # \r\n and \r -> \n
        text.gsub!(/\n\n+/, "</p>\n\n#{start_tag}")  # 2+ newline  -> paragraph
        text.gsub!(/([^\n]\n)(?=[^\n])/, '\1<br />') # 1 newline   -> br
        text.insert 0, start_tag
        text << "</p>"
      end

      # Attempts to pluralize the singular word unless count is 1. If plural is supplied, it will use that when count is > 1,
      # otherwise it will use the Inflector to determine the plural form
      # pluralize(2, 'person') => '2 people'
      def pluralize(count, singular, plural = nil)
        "#{count || 0} " + ((count == 1 || count == '1') ? singular : (plural || singular.pluralize))
      end

      # Truncates a given text after a given :length if text is longer than :length (defaults to 30).
      # The last characters will be replaced with the :omission (defaults to "…") for a total length not exceeding :length.
      # truncate("Once upon a time in a world far far away", :length => 8) => "Once upon..."
      def truncate(text, *args)
        options = args.extract_options!
        options.reverse_merge!(:length => 30, :omission => "...")
        if text
          len = options[:length] - options[:omission].length
          chars = text
          (chars.length > options[:length] ? chars[0...len] + options[:omission] : text).to_s
        end
      end

      # Wraps the text into lines no longer than line_width width.
      # This method breaks on the first whitespace character that does not exceed line_width (which is 80 by default).
      # word_wrap('Once upon a time', :line_width => 8) => "Once upon\na time"
      def word_wrap(text, *args)
        options = args.extract_options!
        unless args.blank?
          options[:line_width] = args[0] || 80
        end
        options.reverse_merge!(:line_width => 80)

        text.split("\n").collect do |line|
          line.length > options[:line_width] ? line.gsub(/(.{1,#{options[:line_width]}})(\s+|$)/, "\\1\n").strip : line
        end * "\n"
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
