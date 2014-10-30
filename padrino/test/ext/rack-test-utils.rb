# This monkey patch is because rack-test gem looks abandoned
module Rack
  module Test
    module Utils # :nodoc:
      def build_nested_query(value, prefix = nil)
        case value
        when Array
          value.map do |v|
            unless unescape(prefix) =~ /\[\]$/
              prefix = "#{prefix}[]"
            end
            build_nested_query(v, "#{prefix}")
          end.join("&")
        when Hash
          value.map do |k, v|
            build_nested_query(v, prefix ? "#{prefix}[#{escape(k)}]" : escape(k))
          end.join("&")
        when NilClass
          prefix.to_s
        else
          # prefix should be escaped to conform rfc3986
          # was: "#{prefix}=#{escape(value)}"
          "#{escape(prefix)}=#{escape(value)}"
        end
      end
    end
  end
end
