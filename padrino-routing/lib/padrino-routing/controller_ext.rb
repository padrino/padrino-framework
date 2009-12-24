if defined?(Padrino::Application) # Extends padrino application if being used
  module Padrino
    module ControllerNamespacing
      # Makes the routes defined in the block and in the Modules given
      # in `extensions` available to the application
      def controllers_with_namespaces(*args, &block)
        return controllers_without_namespaces(*args, &block) unless args.all? { |a| a.kind_of?(Symbol) }
        namespace(*args) { instance_eval(&block) } if block_given?
      end

      # Makes the routing urls defined in this block and in the Modules given
      # in `extensions` available to the application
      def urls(*extensions, &block)
        instance_eval(&block) if block_given?
        include(*extensions)  if extensions.any?
      end
    end

    class Application
      extend Padrino::ControllerNamespacing
      class << self
        alias_method_chain :controllers, :namespaces
      end
    end
  end
end
