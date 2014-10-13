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
      @scoped_controller_name ||= Array(@scoped_controller).join("_")
    end

    def match_with_arguments?(request)
      route = request.route_obj
      path = request.path_info
      @args.any? do |argument|
        if argument.instance_of?(Symbol)
          next unless route
          name = route.name
          argument == name || name == [scoped_controller_name, argument].join(" ").to_sym
        else
          argument === path
        end
      end
    end

    def match_with_options?(request)
      user_agent = request.user_agent
      @options.any?{|name, value| value === (name == :agent ? user_agent : request.send(name)) }
    end
  end
end
