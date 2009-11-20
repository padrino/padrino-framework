if defined?(Padrino::Application) # Extends padrino application if being used
  module Padrino
    module ControllerNamespacing
      # Makes the routes defined in the block and in the Modules given
      # in `extensions` available to the application
      def controllers_with_namespaces(*namespace, &block)
        must_use_namespaces = namespace.size == 1 and namespace.first.is_a?(Symbol)
        return controllers_without_namespaces(*namespace, &block) unless must_use_namespaces
        self.reset_routes! if reload?
        namespace(namespace.first) { instance_eval(&block) } if block_given?
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
