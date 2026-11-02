module Padrino
  class Filter
    PATH_OPTIONS = %i[path path_info].freeze
    NOT_FORMAT_DELIMITER = %r{[^./]}.freeze
    # What a filter's proc returns when it doesn't apply to the route, so it is decided again.
    SKIPPED = Object.new.freeze

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
      return block if @args.empty? && @options.empty?

      filter = self
      proc { filter.apply?(request) ? instance_eval(&filter.block) : SKIPPED }
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
          match_path?(argument, decoded_paths(request), request)
        end
      end
    end

    # A filter runs if any decoded form matches; an :except filter is skipped only if all forms
    # match exactly, with no trailing-slash or format fallback, and none has a newline.
    def match_path?(argument, paths, request)
      return paths.all? { |path| !path.include?("\n") && argument === path } unless @mode

      suffixes = format_suffixes(request)
      paths.any? { |path| path_match?(argument, path, suffixes) }
    end

    # The router also serves '/posts/' from a '/posts' route (PathRouter::Compiler#match?), and
    # '/posts.json' from a route that captures a format.
    def path_match?(argument, path, suffixes)
      forms = [path, *suffixes.map { |suffix| path.delete_suffix(suffix) }]
      forms += forms.flat_map { |form| without_extra_slashes(form) }
      forms.any? { |form| argument === form }
    end

    # A path with trailing slashes also counts with none and with one.
    def without_extra_slashes(form)
      stripped = Routing.strip_trailing(form)
      stripped == form ? [] : [stripped, "#{stripped}/"]
    end

    # What each form of the path has after what the route being run takes as the format-less path.
    def format_suffixes(request)
      route = request.route_obj
      return [] unless route

      decoded_paths(request).filter_map do |form|
        match = route.match(form)
        format_suffix(form, match) if match.respond_to?(:names) && match.names.include?('format')
      end
    end

    # A format ends the path, and a slash before it starts another segment, not a format. A route
    # with an optional format can leave its dot behind without one.
    def format_suffix(form, match)
      offset = match.begin('format')
      return suffix_after(form, form) unless offset

      before = form[0...offset]
      return if before.end_with?('/') || !form[match.end('format')..].delete('/').empty?

      suffix_after(form, before)
    end

    # What +form+ has after +before+ without its delimiters, keeping one slash in the path.
    def suffix_after(form, before)
      size = Routing.strip_trailing(before, NOT_FORMAT_DELIMITER).size
      form[size] == '/' ? form[(size + 1)..] : form[size..]
    end

    # Routing.path_forms of the request path, once per request, and again if PATH_INFO changes
    # (a mounted app sees its own).
    def decoded_paths(request)
      path_info = request.path_info
      cached = request.env['padrino.decoded_paths']
      return cached[1] if cached && cached[0] == path_info

      paths = Routing.path_forms(path_info)
      request.env['padrino.decoded_paths'] = [path_info.dup, paths]
      paths
    end

    def match_with_options?(request)
      user_agent = request.user_agent
      @options.any? do |name, value|
        next value === user_agent if name == :agent
        next value === request.send(name) unless PATH_OPTIONS.include?(name)

        path = request.send(name)
        match_path?(value, [path.scrub, *Routing.path_forms(path)].uniq, request)
      end
    end
  end
end
