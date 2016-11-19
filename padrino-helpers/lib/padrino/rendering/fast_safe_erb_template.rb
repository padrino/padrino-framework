require 'tilt/template'

module Padrino
  module Rendering
    class FastSafeErbTemplate < Tilt::Template
      ESCAPE_MAP = {'&' => '&amp;'.freeze, '<' => '&lt;'.freeze, '>' => '&gt;'.freeze, '"' => '&quot;'.freeze, "'" => '&#039;'.freeze}.freeze
      ESCAPE_REGEXP = Regexp.union(*ESCAPE_MAP.keys).freeze

      def self.h(string)
        string.to_s.gsub(ESCAPE_REGEXP) { |char| ESCAPE_MAP[char] }
      end

      SCAN_REGEXP = /<%(={1,2}|-|%|\#)?(.*?)([-=])?%>([ \t]*\r?\n)?/m.freeze

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

      def prepare; end

      def precompiled_template(locals)
        compiled = PREAMBLE.dup
        buffer = String.new

        pos = 0
        data.scan(SCAN_REGEXP) do |indicator, code, tailch, rspace|
          match = Regexp.last_match
          len = match.begin(0) - pos
          text = data[pos, len]
          zpo = pos
          pos = match.end(0)

          if indicator == '-'
            text.clear if text =~ /\A[ \t]+\Z/
            text.gsub!(/\n[ \t]+\Z/, "\n")
          end
          buffer << text.gsub(/[`\#\\]/, '\\\\\&') 

          case indicator
          when '=' # <%=
            rspace = nil if tailch
            buffer << "\#{\n    @__in_ruby_literal = true\n    result = (#{code}).to_s\n    @__in_ruby_literal = false\n    result.html_safe? ? result : Padrino::Rendering::FastSafeErbTemplate.h(result)\n  }#{rspace}"
          when '==' # <%==
            rspace = nil if tailch
            buffer << "\#{\n    @__in_ruby_literal = true\n    result = (#{code}).to_s\n    @__in_ruby_literal = false\n    result\n  }#{rspace}"
          when nil, '-' # <%, <%-
#            compiled << "# - MATCH: #{match.inspect}\n"
#            compiled << "# - DATA, POS: #{data.inspect}, #{zpo}\n"
#            compiled << "# - DATA[POS..-1]: #{data[zpo..-1].inspect}\n"
#            compiled << "# - RSPACE: #{rspace.inspect}\n"
#            compiled << "# - CODE: #{code.inspect}\n"
#            compiled << "# - TEXT: #{text.inspect}\n"
#            compiled << "# - BUFFR: #{buffer.inspect}\n"
            unless buffer.empty?
              compiled << "  @_out_buf.safe_concat(%Q`#{buffer}`)\n"
              buffer.clear
            end
            compiled << " #{code}#{rspace}\n"
            if rspace && !tailch
              compiled << "  @_out_buf.safe_concat(%Q`#{rspace}`)\n"
            end
          when '%' # <%%
            unless buffer.empty?
              compiled << "  @_out_buf.safe_concat(%Q`#{buffer}`)\n"
              buffer.clear
            end
            rspace = nil if tailch
            compiled << "  @_out_buf.safe_concat(%Q`<%#{code.chomp('%')}%>#{rspace}`)\n"
          when '#' # <%#
            if rspace && !tailch
              compiled << "  @_out_buf.safe_concat(%Q`#{rspace}`)\n"
            end
          else
            fail match.inspect
          end
        end

        buffer << data[pos..-1].gsub(/[`\#\\]/, '\\\\\&')
        compiled << "  @_out_buf.safe_concat(%Q`#{buffer}`)\n" unless buffer.empty?
        compiled << "\n" unless compiled[-1] == "\n"
        compiled << POSTAMBLE
      end
    end
  end
end

Tilt.register(Padrino::Rendering::FastSafeErbTemplate, :erb)
