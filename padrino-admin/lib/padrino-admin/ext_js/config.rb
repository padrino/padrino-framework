require 'rubygems'
require 'yaml'
require 'erb'
require 'json/pure' unless defined?(JSON) || defined?(JSON::Pure)

module Padrino
  module ExtJs

    class ConfigError < RuntimeError; end

    # This class it's used for JSON variables.
    # Normally if we convert this { :function => "alert('Test')" } will be:
    # 
    #   { "function": "alert('Test')" }
    # 
    # But if in our javascript need to "eval" this function is not possible because
    # it's a string.
    # 
    # Using Padrino::ExtJs::Variable the result will be:
    # 
    #   { "function" : alert('Test') }
    # 
    # Normally an ExtJs Variable can be handled with ExtJs Config like:
    # 
    #   function: !js alert('Test')
    # 
    class Variable < String
      yaml_as "tag:yaml.org,2002:js"

      def to_json(*a) #:nodoc:
        self
      end
    end

    # Json Pretty Printer.
    # Thanks to http://github.com/techcrunch/json_printer
    class JsonPrinter
      attr_reader :buf, :indent

      # ==== Arguments
      # obj<Object>::
      #   The object to be rendered into JSON.  This object and all of its 
      #   associated objects must be either nil, true, false, a String, a Symbol,
      #   a Numeric, an Array, or a Hash.
      #
      # ==== Returns
      # <String>::
      #   The pretty-printed JSON ecoding of the given <i>obj</i>.  This string
      #   can be parsed by any compliant JSON parser without modification.
      #
      # ==== Examples
      # See <tt>JsonPrinter</tt> docs.
      #
      def self.render(obj, indent=1)
        indent = " "*indent
        new(obj, indent).buf
      end


      private
        # Execute the JSON rendering of <i>obj</i>, storing the result in the 
        # <tt>buf</tt>.
        #
        def initialize(obj, indent="")
          @buf = ""
          @indent = indent
          render(obj)
        end

        # Increase the indentation level.
        #
        def indent_out
          @indent << " "
        end

        # Decrease the indendation level.
        #
        def indent_in
          @indent.slice!(-1, 1)
        end

        # Append the given <i>str</i> to the <tt>buf</tt>.
        #
        def print(str)
          @buf << str
        end

        # Recursive rendering method.  Primitive values, like nil, true, false, 
        # numbers, symbols, and strings are converted to JSON and appended to the
        # buffer.  Enumerables are treated specially to generate pretty whitespace.
        #
        def render(obj)
          # We can't use a case statement here becuase "when Hash" doesn't work for
          # ActiveSupport::OrderedHash - respond_to?(:values) is a more reliable
          # indicator of hash-like behavior.
          if NilClass === obj
            print("null")

          elsif TrueClass === obj
            print("true")

          elsif FalseClass === obj
            print("false")

          elsif String === obj
            print(escape_json_string(obj))

          elsif Symbol === obj
            print("\"#{obj}\"")

          elsif Numeric === obj
            print(obj.to_s)

          elsif Time === obj
            print(obj.to_s)

          elsif obj.respond_to?(:keys)
            print("{")
            indent_out
            last_key = obj.keys.last
            obj.each do |(key, val)|
              render(key)
              case val
              when Hash, Array
                indent_out
                print(":\n#{indent}")
                render(val)
                indent_in
              else
                print(": ")
                render(val)
              end
              print(",\n#{indent}") unless key == last_key
            end
            indent_in
            print("}")

          elsif Array === obj
            print("[")
            indent_out
            last_index = obj.size - 1
            obj.each_with_index do |elem, index|
              render(elem)
              print(",\n#{indent}") unless index == last_index
            end
            indent_in
            print("]")

          else
            raise "unrenderable object: #{obj.inspect}"
          end
        end

        # Special JSON character escape cases.
        ESCAPED_CHARS = {
          "\010" =>  '\b',
          "\f"   =>  '\f',
          "\n"   =>  '\n',
          "\r"   =>  '\r',
          "\t"   =>  '\t',
          '"'    =>  '\"',
          '\\'   =>  '\\\\',
          '>'    =>  '\u003E',
          '<'    =>  '\u003C',
          '&'    =>  '\u0026'}

        # String#to_json extracted from ActiveSupport, using interpolation for speed.
        #
        def escape_json_string(str)
          begin
            "\"#{
            str.gsub(/[\010\f\n\r\t"\\><&]/) { |s| ESCAPED_CHARS[s] }.
                gsub(/([\xC0-\xDF][\x80-\xBF]|
                       [\xE0-\xEF][\x80-\xBF]{2}|
                       [\xF0-\xF7][\x80-\xBF]{3})+/nx) do |s|
                  s.unpack("U*").pack("n*").unpack("H*")[0].gsub(/.{4}/, '\\\\u\&')
                end
            }\""
          rescue Encoding::CompatibilityError
            rawbytes = str.dup.force_encoding 'ASCII-8BIT'
            escape_json_string(rawbytes)
          end
      end
    end
  end
end