module Padrino
  # The request object. See Rack::Request for more info:
  # http://rack.rubyforge.org/doc/classes/Rack/Request.html
  class Request < Rack::Request
    # Returns an array of acceptable media types for the response
    def accept
      @env['padrino.accept'] ||= begin
        entries = @env['HTTP_ACCEPT'].to_s.split(',')
        entries.map { |e| accept_entry(e) }.sort_by(&:last).map(&:first)
      end
    end

    def preferred_type(*types)
      return accept.first if types.empty?
      types.flatten!
      accept.detect do |pattern|
        type = types.detect { |t| File.fnmatch(pattern, t) }
        return type if type
      end
    end

    alias accept? preferred_type
    alias secure? ssl?

    def forwarded?
      @env.include? "HTTP_X_FORWARDED_HOST"
    end

    def safe?
      get? or head? or options? or trace?
    end

    def idempotent?
      safe? or put? or delete?
    end

    private
    def accept_entry(entry)
      type, *options = entry.delete(' ').split(';')
      quality = 0 # we sort smallest first
      options.delete_if { |e| quality = 1 - e[2..-1].to_f if e.start_with? 'q=' }
      [type, [quality, type.count('*'), 1 - options.size]]
    end
  end # Request
end # Padrino
