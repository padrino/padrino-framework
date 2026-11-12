require 'cgi/escape'

module Padrino
  module Utils
    module_function

    ##
    # Builds an URI query from a Hash or any Object.
    #
    # Examples (~ marks here that output is actually escaped by CGI):
    #
    #   Utils.build_uri_query(a: 1, b: 2)           # => 'a=1&b=2'
    #   Utils.build_uri_query(a: [1, 2])            # => ~'a[]=1&a[]=2'
    #   Utils.build_uri_query([1, 2], 'namespace')  # => ~'namespace[]=1&namespace[]=2'
    #   Utils.build_uri_query(a: { d: 2 }, b: 3)    # => ~'a[d]=2&b=3'
    #
    def build_uri_query(object, namespace = nil)
      case object
      when Hash
        object.map do |key, value|
          next if [{}, []].include?(value)
          build_uri_query(value, namespace ? "#{namespace}[#{key}]" : key)
        end.compact.join('&')
      when Array
        raise ArgumentError, 'namespace is missing' unless namespace
        (object.empty? ? [''] : object).map do |value|
          build_uri_query(value, "#{namespace}[]")
        end.join('&')
      else
        raise ArgumentError, 'namespace is missing' unless namespace
        "#{CGI.escape(namespace.to_s)}=#{CGI.escape(object.to_s)}"
      end
    end

    ##
    # Recursively duplicates the passed object.
    #
    def deep_dup(object)
      case object
      when Array
        object.map { |value| deep_dup(value) }
      when Hash
        object.each_with_object(object.dup.clear) do |(key, value), new_hash|
          new_hash[deep_dup(key)] = deep_dup(value)
        end
      when NilClass, FalseClass, TrueClass, Symbol, Numeric, Method
        object
      else
        begin
          object.dup
        rescue TypeError
          object
        end
      end
    end

    ##
    # Returns a Hash with keys turned into symbols.
    #
    def symbolize_keys(hash)
      result = hash.class.new
      hash.each_key do |key|
        result[(key.to_sym rescue key)] = hash[key]
      end
      result
    end

    DEPRECATIONS_LOCK = Mutex.new
    private_constant :DEPRECATIONS_LOCK

    ##
    # Warns, once per process, that +subject+ will be removed in Padrino 1.0, followed by
    # +advice+ and, when given, the location of the first use.
    #
    # @api private
    def warn_deprecated(subject, advice, location = nil)
      # Marked before warning, so a Warning.warn that raises (warnings as errors) still warns once.
      first = DEPRECATIONS_LOCK.synchronize do
        warned = (@warned_deprecations ||= {})
        !warned[subject] && (warned[subject] = true)
      end
      return unless first

      first_use = " (first used at #{location.path}:#{location.lineno})" if location
      # Warning.warn prints even while $VERBOSE is nil, as it is while the reloader loads app files.
      Warning.warn "WARNING! #{subject} is deprecated and will be removed in Padrino 1.0. #{advice}#{first_use}.\n"
    end
  end
end
