# frozen_string_literal: true
require 'padrino/core_ext/output_safety'

module Padrino
  module Rendering
    class FastSafeErbEngine
      ESCAPE_KEYS = /[&<>"']/.freeze
      ESCAPE_MAP = {'&' => '&amp;', '<' => '&lt;', '>' => '&gt;', '"' => '&quot;', "'" => '&#039;'}.freeze

      def self.h(string)
        string.to_s.gsub(ESCAPE_KEYS, ESCAPE_MAP)
      end

      PREAMBLE = "# frozen_string_literal: true
__in_erb_template = true
begin
  __original_outvar = @_out_buf if defined?(@_out_buf)
  @_out_buf = SafeBuffer.new
".freeze

      POSTAMBLE = "  @_out_buf
ensure
  @_out_buf = __original_outvar
end
".freeze

      SCAN_REGEXP = /<%(={1,2}|-|%|\#)?(.*?)([-=])?%>([ \t]*\r?\n)?/m.freeze

      def self.compile(data)
        compiled = PREAMBLE.dup
        buffer = String.new

        pos = 0
        data.scan(SCAN_REGEXP) do |indicator, code, tailch, rspace|
          match = Regexp.last_match
          len = match.begin(0) - pos
          text = data[pos, len]
          pos = match.end(0)

          if indicator == '-'
            text.clear if text =~ /\A[ \t]+\Z/
            text.gsub!(/\n[ \t]+\Z/, "\n")
          end

          buffer << text.gsub(/[`\#\\]/, '\\\\\&')

#            compiled << "# #{indicator} MATCH: #{match.inspect}\n"
#            compiled << "# #{indicator} DATA, POS: #{data.inspect}, #{zpo}\n"
#            compiled << "# #{indicator} DATA[POS..-1]: #{data[zpo..-1].inspect}\n"
#            compiled << "# #{indicator} RSPACE: #{rspace.inspect}\n"
#            compiled << "# #{indicator} CODE: #{code.inspect}\n"
#            compiled << "# #{indicator} TEXT: #{text.inspect}\n"
#            compiled << "# #{indicator} BUFFR: #{buffer.inspect}\n"

          case indicator
          when '=' # <%=
            rspace = nil if tailch
#2.44            buffer << "\#{\n    @__in_ruby_literal = true\n    result = (#{code})\n    @__in_ruby_literal = false\n    result.html_safe? ? result.to_s : Padrino::Rendering::FastSafeErbEngine.h(result)\n  }#{rspace}"
#2.18 !#1785vvvvvv
            buffer << "\#{\n    result = (#{code})\n    result.html_safe? ? result.to_s : Padrino::Rendering::FastSafeErbEngine.h(result)\n  }#{rspace}"
          when '==' # <%==
            rspace = nil if tailch
#2.44            buffer << "\#{\n    @__in_ruby_literal = true\n    result = (#{code})\n    @__in_ruby_literal = false\n    result.to_s\n  }#{rspace}"
#2.18 !#1785vvvvvv
            buffer << "\#{\n    (#{code}).to_s\n  }#{rspace}"
          when nil, '-' # <%, <%-
            unless buffer.empty?
              compiled << "  @_out_buf.safe_concat(%%Q`%s`)\n" % buffer
              buffer.clear
            end
            compiled << " #{code}#{rspace}\n"
            if rspace && !tailch
              buffer << rspace
            end
          when '%' # <%%
            unless buffer.empty?
              compiled << "  @_out_buf.safe_concat(%%Q`%s`)\n" % buffer
              buffer.clear
            end
            rspace = nil if tailch
            compiled << "  @_out_buf.safe_concat(%%Q`%s`)\n" % "<%#{code.chomp('%')}%>#{rspace}"
          when '#' # <%#
            if rspace && !tailch
              compiled << "  @_out_buf.safe_concat(%%Q`%s`)\n" % rspace
            end
          else
            fail match.inspect
          end
        end

        buffer << data[pos..-1].gsub(/[`\#\\]/, '\\\\\&')
        compiled << "  @_out_buf.safe_concat(%%Q`%s`)\n" % buffer unless buffer.empty?
        compiled << "\n" unless compiled.end_with?("\n")
        compiled << POSTAMBLE
      end
    end
  end
end
