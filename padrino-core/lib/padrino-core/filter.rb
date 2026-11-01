module Padrino
  class Filter
    attr_reader :block

    def initialize(mode, scoped_controller, options, args, &block)
      @mode = mode
      @scoped_controller = scoped_controller
      @options = options
      @args = args
      @block = block
    end

    def apply?(request)
      detect = match_with_arguments?(request) || match_with_options?(request)
      detect ^ !@mode
    end

    def to_proc
      if @args.empty? && @options.empty?
        block
      else
        filter = self
        proc { instance_eval(&filter.block) if filter.apply?(request) }
      end
    end

    private

    def scoped_controller_name
      @scoped_controller_name ||= Array(@scoped_controller).join('_')
    end

    def match_with_arguments?(request)
      route = request.route_obj
      @args.any? do |argument|
        if argument.instance_of?(Symbol)
          next unless route
          name = route.name
          argument == name || name == [scoped_controller_name, argument].join(' ').to_sym
        else
          # A filter runs if either decoded form matches; an :except filter is skipped only if both do.
          paths = decoded_paths(request)
          @mode ? paths.any? { |path| path_match?(argument, path) } : paths.all? { |path| path_match?(argument, path) }
        end
      end
    end

    # The router also serves '/posts/' from a '/posts' route (PathRouter::Compiler#match?).
    def path_match?(argument, path)
      argument === path || (argument.is_a?(String) && path.end_with?('/') && argument === path[0..-2])
    end

    # The request path as the router matches it ('%2F' stays inside its segment) and fully decoded
    # (as a splat or param receives it), scrubbed so a Regexp can match invalid UTF-8. Decoded once
    # per request, and again if PATH_INFO changes (a mounted app sees its own).
    def decoded_paths(request)
      path_info = request.path_info
      cached = request.env['padrino.decoded_paths']
      return cached[1] if cached && cached[0] == path_info

      paths = [Routing.decode_route_path(path_info).scrub, Routing.decode_path(path_info).scrub].uniq
      request.env['padrino.decoded_paths'] = [path_info.dup, paths]
      paths
    end

    def match_with_options?(request)
      user_agent = request.user_agent
      @options.any? { |name, value| value === (name == :agent ? user_agent : request.send(name)) }
    end
  end
end
