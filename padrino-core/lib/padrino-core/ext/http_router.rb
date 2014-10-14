require 'http_router' unless defined?(HttpRouter)

class HttpRouter
  def rewrite_partial_path_info(env, request); end
  def rewrite_path_info(env, request); end

  def process_destination_path(path, env)
    Thread.current['padrino.instance'].instance_eval do
      request.route_obj = path.route
      @_response_buffer = nil
      @route    = path.route
      @params ||= {}
      @params.update(env['router.params'])
      @block_params = if match_data = env['router.request'].extra_env['router.regex_match']
        params_list = match_data.to_a
        params_list.shift
        @params[:captures] = params_list
        params_list
      else
        env['router.request'].params
      end
      # Provide access to the current controller to the request
      # Now we can eval route, but because we have "throw halt" we need to be
      # (en)sure to reset old layout and run controller after filters.
      original_params = @params
      parent_layout   = @layout
      successful      = false
      begin
        filter! :before
        (@route.before_filters - settings.filters[:before]).each { |block| instance_eval(&block) }
        @layout = path.route.use_layout if path.route.use_layout
        @route.custom_conditions.each { |block| pass if block.bind(self).call == false }
        halt_response     = catch(:halt) { route_eval { @route.dest[self, @block_params] } }
        @_response_buffer = halt_response.is_a?(Array) ? halt_response.last : halt_response
        successful        = true
        halt halt_response
      ensure
        (@route.after_filters - settings.filters[:after]).each { |block| instance_eval(&block) } if successful
        @layout = parent_layout
        @params = original_params
      end
    end
  end

  class Route
    VALID_HTTP_VERBS.replace %w[GET POST PUT PATCH DELETE HEAD OPTIONS LINK UNLINK]

    attr_accessor :use_layout, :controller, :action, :cache, :cache_key, :cache_expires, :parent

    def before_filters(&block)
      @_before_filters ||= []
      @_before_filters << block if block_given?

      @_before_filters
    end

    def after_filters(&block)
      @_after_filters ||= []
      @_after_filters << block if block_given?

      @_after_filters
    end

    def custom_conditions(&block)
      @_custom_conditions ||= []
      @_custom_conditions << block if block_given?

      @_custom_conditions
    end

    def significant_variable_names
      @significant_variable_names ||= if @original_path.is_a?(String)
        @original_path.scan(/(^|[^\\])[:\*]([a-zA-Z0-9_]+)/).map{|p| p.last.to_sym}
      elsif @original_path.is_a?(Regexp) and @original_path.respond_to?(:named_captures)
        @original_path.named_captures.keys.map(&:to_sym)
      else
        []
      end
    end

    def to(dest = nil, &dest_block)
      @dest = dest || dest_block || raise("you didn't specify a destination")

      @router.current_order ||= 0
      @order = @router.current_order
      @router.current_order += 1

      if @dest.respond_to?(:url_mount=)
        urlmount = UrlMount.new(@path_for_generation, @default_values || {}) # TODO url mount should accept nil here.
        urlmount.url_mount = @router.url_mount if @router.url_mount
        @dest.url_mount = urlmount
      end
      self
    end

    attr_accessor :order

  end

  attr_accessor :current_order

  def sort!
    @routes.sort!{ |a, b| a.order <=> b.order }
  end

  class Node::Glob
    def to_code
      id = root.next_counter
      "request.params << (globbed_params#{id} = [])
       until request.path.empty?
         globbed_params#{id} << request.path.shift
         #{super}
       end
       request.path[0,0] = globbed_params#{id}
       request.params.pop"
    end
  end

  class Node::SpanningRegex
    def to_code
      params_count = @ordered_indicies.size
      whole_path_var = "whole_path#{root.next_counter}"
      "#{whole_path_var} = request.joined_path
      if match = #{@matcher.inspect}.match(#{whole_path_var}) and match.begin(0).zero?
        _#{whole_path_var} = request.path.dup
        " << param_capturing_code << "
        remaining_path = #{whole_path_var}[match[0].size + (#{whole_path_var}[match[0].size] == ?/ ? 1 : 0), #{whole_path_var}.size]
        request.path = remaining_path.split('/')
        #{node_to_code}
        request.path = _#{whole_path_var}
        request.params.slice!(#{-params_count}, #{params_count})
      end
      "
    end
  end

  # Monkey patching the Request class. Using Rack::Utils.unescape rather than
  # URI.unescape which can't handle utf-8 chars
  class Request
    def initialize(path, rack_request)
      @rack_request = rack_request
      @path = path.split(/\//).map{|part| Rack::Utils.unescape(part) }
      @path.shift if @path.first == ''
      @path.push('') if path[-1] == ?/
      @extra_env = {}
      @params = []
      @acceptable_methods = Set.new
    end
  end

  class Node::Path
    def to_code
      path_ivar = inject_root_ivar(self)
      "#{"if !callback && request.path.size == 1 && request.path.first == '' && (request.rack_request.head? || request.rack_request.get?) && request.rack_request.path_info[-1] == ?/
        catch(:pass) do
          response = ::Rack::Response.new
          response.redirect(request.rack_request.path_info[0, request.rack_request.path_info.size - 1], 302)
          return response.finish
        end
      end" if router.redirect_trailing_slash?}

      #{"if request.#{router.ignore_trailing_slash? ? 'path_finished?' : 'path.empty?'}" unless route.match_partially}
        catch(:pass) do
          if callback
            request.called = true
            callback.call(Response.new(request, #{path_ivar}))
          else
            env = request.rack_request.dup.env
            env['router.request'] = request
            env['router.params'] ||= {}
            #{"env['router.params'].merge!(Hash[#{param_names.inspect}.zip(request.params)])" if dynamic?}
            env['router.params'] = env['router.params'].with_indifferent_access
            @router.rewrite#{"_partial" if route.match_partially}_path_info(env, request)
            response = @router.process_destination_path(#{path_ivar}, env)
            return response unless router.pass_on_response(response)
          end
        end
      #{"end" unless route.match_partially}"
    end
  end

  class Node::FreeRegex
    def to_code
      id = root.next_counter
      "whole_path#{id} = \"/\#{request.joined_path}\"
      if match = #{matcher.inspect}.match(whole_path#{id}) and match[0].size == whole_path#{id}.size
        request.extra_env['router.regex_match'] = match
        old_path = request.path
        request.path = ['']
        " << (use_named_captures? ?
        "match.names.size.times{|i| request.params << match[i + 1]} if match.respond_to?(:names) && match.names" : "") << "
        #{super}
        request.path = old_path
        request.extra_env.delete('router.regex_match')
        " << (use_named_captures? ?
        "request.params.slice!(-match.names.size, match.names.size)" : ""
        ) << "
      end"
    end
  end
end
