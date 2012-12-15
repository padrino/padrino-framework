module Padrino
  # The response object. See Rack::Response and Rack::ResponseHelpers for
  # more info:
  # http://rack.rubyforge.org/doc/classes/Rack/Response.html
  # http://rack.rubyforge.org/doc/classes/Rack/Response/Helpers.html
  class Response < Rack::Response
    def body=(value)
      value = value.body while Rack::Response === value
      @body = String === value ? [value.to_str] : value
    end

    def each
      block_given? ? super : enum_for(:each)
    end

    def finish
      if status.to_i / 100 == 1
        headers.delete "Content-Length"
        headers.delete "Content-Type"
      elsif Array === body and not [204, 304].include?(status.to_i)
        headers["Content-Length"] = body.inject(0) { |l, p| l + Rack::Utils.bytesize(p) }.to_s
      end

      # Rack::Response#finish sometimes returns self as response body. We don't want that.
      status, headers, result = super
      result = body if result == self
      [status, headers, result]
    end
  end # Response
end # Padrino
