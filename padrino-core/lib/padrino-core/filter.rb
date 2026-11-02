module Padrino
  class Filter
    PATH_OPTIONS = %i[path path_info].freeze
    # The env keys that hold the forms of the request's path_info and path (path_entry), and route_cuts.
    PATH_FORMS_KEYS = { path_info: 'padrino.decoded_path_info'.freeze, path: 'padrino.decoded_path'.freeze }.freeze
    ROUTE_CUTS_KEY = 'padrino.route_cuts'.freeze
    MAX_FORMAT_DELIMITER = 3 # ceiling: a longer delimiter before an optional format is not cut; raise it if a route needs one
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

    # +settings+, the settings of the app running the request, decide how its routes answer a
    # format they don't provide (format_cuts).
    def apply?(request, settings = nil)
      detect = match_with_arguments?(request, settings) || match_with_options?(request, settings)
      detect ^ !@mode
    end

    def to_proc
      return block if @args.empty? && @options.empty?

      filter = self
      proc { filter.apply?(request, settings) ? instance_eval(&filter.block) : SKIPPED }
    end

    private

    def scoped_controller_name
      @scoped_controller_name ||= Array(@scoped_controller).join('_')
    end

    def match_with_arguments?(request, settings)
      route = request.route_obj
      @args.any? do |argument|
        if argument.instance_of?(Symbol)
          next unless route
          name = route.name
          argument == name || name == [scoped_controller_name, argument].join(' ').to_sym
        else
          entry = path_entry(request)
          match_path?(argument, request, settings, @mode ? [route_path(entry)] : all_paths(entry), entry)
        end
      end
    end

    # +paths+ holds the forms the mode compares. A filter runs if one of them, or one of its route
    # cuts, matches: the path as the router matched it ('%2F' stays inside its segment), and for
    # the path and path_info options the path as given too. An :except filter is skipped only if
    # every decoded form, and for the options the path as given, matches exactly, and none has a
    # newline. +info+ is the path_entry of path_info, when the caller has it.
    def match_path?(argument, request, settings, paths, info = nil)
      return paths.all? { |path| !path.include?("\n") && argument === path } unless @mode
      return true if paths.any? { |path| argument === path }

      cuts = route_cuts(request, settings, info || path_entry(request))
      paths.any? { |path| path_match?(argument, path, cuts) }
    end

    # Each cut is a suffix of the path and what replaces it (route_cuts); it applies to any
    # compared path that ends with that suffix, such as the path option of a mounted app. With no
    # route, the path also counts without its trailing slashes.
    def path_match?(argument, path, cuts)
      return Routing.without_extra_slashes(path).any? { |form| argument === form } unless cuts

      cuts.any? { |suffix, rest| path.end_with?(suffix) && argument === "#{path.delete_suffix(suffix)}#{rest}" }
    end

    # The other forms of the path the route being run serves, as cuts, once per route, path and
    # Routing.treat_format_as_accept? setting for the request: without its format (format_cuts), and without the one trailing slash the router
    # drops when the route doesn't match the path with it ('/posts/' from a '/posts' route,
    # PathRouter::Compiler#match?). nil without a route.
    def route_cuts(request, settings, entry)
      route = request.route_obj
      return unless route

      accept = Routing.treat_format_as_accept?(settings)
      store = ((request.env[ROUTE_CUTS_KEY] ||= {})[accept] ||= {}.compare_by_identity)
      memo(store, route, entry[:path]) do
        form = route_path(entry)
        cuts = format_cuts(route, form, accept)
        cuts << ['/', ''] if form != '/' && form.end_with?('/') && !route.matcher.whole_regexp.match(form)
        cuts
      end
    end

    # For a route whose only capture is a format that it captured at the end of +form+, before
    # slashes only, and that it serves (provided?): +form+ cut at the longest prefix, from the start
    # of the format back to MAX_FORMAT_DELIMITER characters before it, that the same route matches
    # without a format, and that prefix with one slash if the route matches that too. None for a
    # route that requires its format, a route with another param or splat, and a Regexp route.
    def format_cuts(route, form, accept)
      matcher = route.matcher
      return [] unless matcher.mustermann? && matcher.names == ['format']

      match = route.match(form)
      from, to = match.offset('format') if match
      return [] unless from && from < to && form[to..].count('^/').zero? && provided?(route, match['format'], accept)

      at = from.downto([from - MAX_FORMAT_DELIMITER, 0].max).find { |cut| without_format?(route, form[0, cut]) }
      return [] unless at

      suffix = form[at..]
      without_format?(route, "#{form[0, at]}/") ? [[suffix, ''], [suffix, '/']] : [[suffix, '']]
    end

    # Whether the route matches +path+ as the router does, also without one trailing slash, with no format.
    def without_format?(route, path)
      match = route.match(path)
      match && match['format'].nil?
    end

    # Whether the route serves +format+, as captured from the path the router matches: each of its
    # provides conditions accepts it as route params receive it (provides_format?), or the app
    # answers 406 for it itself instead of handing the request on (+accept+,
    # Routing.treat_format_as_accept?).
    def provided?(route, format, accept)
      return true if accept

      format = Routing.decode_path(format).scrub.to_sym
      Array(route.provided_formats).all? { |types| Routing.provided_format?(types, format) }
    end

    # The memo of the request's path_info or path (+name+) that the forms below are kept in, once
    # per request, and again if the path changes (a mounted app sees its own).
    def path_entry(request, name = :path_info)
      path = request.send(name)
      memo(request.env, PATH_FORMS_KEYS.fetch(name), path) { |stored| { path: stored } }
    end

    # The path as the router matches it.
    def route_path(entry)
      entry[:route] ||= decoded_route_path(entry).scrub
    end

    # Every decoded form of the path, router form first (Routing.path_forms).
    def all_paths(entry)
      entry[:all] ||= Routing.path_forms(entry[:path], decoded_route_path(entry))
    end

    # The path as given, scrubbed.
    def raw_path(entry)
      entry[:raw] ||= entry[:path].dup.force_encoding(Encoding::UTF_8).scrub
    end

    def decoded_route_path(entry)
      entry[:decoded] ||= Routing.decode_route_path(entry[:path])
    end

    # The block's value for +key+ in +store+, computed once for each +path+. The block gets the
    # copy of +path+ the memo keeps.
    def memo(store, key, path)
      cached = store[key]
      return cached[1] if cached && cached[0] == path

      stored = path.dup
      value = yield(stored)
      store[key] = [stored, value]
      value
    end

    def match_with_options?(request, settings)
      user_agent = request.user_agent
      @options.any? do |name, value|
        next value === user_agent if name == :agent
        next value === request.send(name) unless PATH_OPTIONS.include?(name)

        entry = path_entry(request, name)
        paths = @mode ? [route_path(entry)] : all_paths(entry)
        match_path?(value, request, settings, [raw_path(entry), *paths].uniq, name == :path_info ? entry : nil)
      end
    end
  end
end
