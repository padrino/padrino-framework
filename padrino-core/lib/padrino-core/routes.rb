module Padrino

  ##
  # Example:
  #
  #   module AdminRoutes
  #     include Padrino::Routes
  #
  #     get '/admin' do
  #       ...
  #     end
  #   end
  #
  #   class App < Padrino::Application
  #     include AdminRoutes
  #
  #     get '/' do
  #       ...
  #     end
  #   end
  #
  module Routes

    def self.included(base)
      unless base.respond_to?(:routes)
        base.extend(ClassMethods)
        base.reset_routes!
      end
      super
    end

    module ClassMethods
      attr_reader :conditions, :routes, :filters

      def included(base)
        unless base.respond_to?(:routes)
          base.extend(ClassMethods)
          base.reset_routes!
        end

        routes.each { |k,v| base.routes[k].concat v }
        base.conditions.concat conditions
        filters.each { |k,v| base.filters[k].concat v }
        super
      end

      def reset_routes!
        @conditions = []
        @routes     = Hash.new { |h,k| h[k] = [] }
        @filters    = { before: [], after: [] }
      end

      # Define a before filter; runs before all requests within the same
      # context as route handlers and may access/modify the request and
      # response.
      def before(path = nil, options = {}, &block)
        add_filter(:before, path, options, &block)
      end

      # Define an after filter; runs after all requests within the same
      # context as route handlers and may access/modify the request and
      # response.
      def after(path = nil, options = {}, &block)
        add_filter(:after, path, options, &block)
      end

      # add a filter
      def add_filter(type, path = nil, options = {}, &block)
        path, options = //, path if path.respond_to?(:each_pair)
        filters[type] << compile!(type, path || //, block, options)
      end

      # Add a route condition. The route is considered non-matching when the
      # block returns false.
      def condition(name = "#{caller.first[/`.*'/]} condition", &block)
        conditions << generate_method(name, &block)
      end

      # Condition for matching host name. Parameter might be String or Regexp.
      def host_name(pattern)
        condition { pattern === request.host }
      end
      alias :host :host_name

      # Condition for matching user agent. Parameter should be Regexp.
      # Will set params[:agent].
      def user_agent(pattern)
        condition do
          if request.user_agent.to_s =~ pattern
            @params[:agent] = $~[1..-1]
            true
          else
            false
          end
        end
      end
      alias :agent :user_agent

      # Condition for matching mimetypes. Accepts file extensions.
      def provides(*types)
        types.map! { |t| mime_types(t) }
        types.flatten!
        condition do
          if type = response['Content-Type']
            types.include? type or types.include? type[/^[^;]+/]
          elsif type = request.preferred_type(types)
            content_type(type)
            true
          else
            false
          end
        end
      end

      def desc(text)
        @desc = text
      end

      def path(value)
        @path = value
      end

      # Defining a `GET` handler also automatically defines
      # a `HEAD` handler.
      def get(*args, &block)
        conditions_was = conditions.dup
        desc, path     = @desc, @path
        route(*['GET', *args], &block)

        @conditions  = conditions_was
        @desc, @path = desc, path
        route(*['HEAD', *args], &block)
      end

      def put      *args, &blk; route(*['PUT',     *args], &blk); end
      def post     *args, &blk; route(*['POST',    *args], &blk); end
      def delete   *args, &blk; route(*['DELETE',  *args], &blk); end
      def head     *args, &blk; route(*['HEAD',    *args], &blk); end
      def patch    *args, &blk; route(*['PATCH',   *args], &blk); end
      def options  *args, &blk; route(*['OPTIONS', *args], &blk); end

      def route(*args, &block)
        options = args.extract_options!

        name = args.delete_if { |a| Symbol === a }
        verb, path = args.values_at(0, 1)
        path ||= @path

        raise ArgumentError if path.blank? or verb.blank?

        signature = compile!(verb, path, block, options)
        routes[verb] << signature
        invoke_hook(:route_added, verb, path, block)
        signature
      ensure
        @desc, @path = nil, nil
      end

      def invoke_hook(name, *args)
        # extensions.each { |e| e.send(name, *args) if e.respond_to?(name) }
      end

      def generate_method(method_name, &block)
        define_method(method_name, &block)
        method = instance_method method_name
        remove_method method_name
        method
      end

      def compile!(verb, path, block, options = {})
        options.each_pair { |option, args| send(option, *args) }
        method_name             = "#{verb} #{path}"
        unbound_method          = generate_method(method_name, &block)
        pattern, keys           = compile(path)
        conditions, @conditions = @conditions, []

        [
          pattern, keys, conditions, block.arity != 0 ?
            -> a, p { unbound_method.bind(a).call(*p) } :
            -> a, p { unbound_method.bind(a).call }
        ]
      end

      def compile(path)
        keys = []
        if path.respond_to? :to_str
          ignore  = ''
          pattern = path.to_str.gsub(/[^\?\%\\\/\:\*\w]/) do |c|
            ignore << escaped(c).join if c.match(/[\.@]/)
            encoded(c)
          end
          pattern.gsub!(/((:\w+)|\*)/) do |match|
            if match == "*"
              keys << 'splat'
              '(.*?)'
            else
              keys << $2[1..-1]
              "([^#{ignore}/?#]+)"
            end
          end
          [/\A#{pattern}\/?\z/, keys]
        elsif path.respond_to?(:keys) && path.respond_to?(:match)
          [path, path.keys]
        elsif path.respond_to?(:names) && path.respond_to?(:match)
          [path, path.names]
        elsif path.respond_to? :match
          [path, keys]
        else
          raise TypeError, path
        end
      end

      URI = ::URI.const_defined?(:Parser) ? ::URI::Parser.new : ::URI

      def encoded(char)
        enc = URI.escape(char)
        enc = "(?:#{escaped(char, enc).join('|')})" if enc == char
        enc = "(?:#{enc}|#{encoded('+')})" if char == " "
        enc
      end

      def escaped(char, enc = URI.escape(char))
        [Regexp.escape(enc), URI.escape(char, /./)]
      end

    end # ClassMethods
  end # Routes
end # Padrino
