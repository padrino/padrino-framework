module Padrino
  module ControllerNamespacing
    # Makes the routes defined in the block and in the Modules given
    # in `extensions` available to the application
    def controllers_with_namespaces(*namespace, &block)
      controllers_without_namespaces unless namespace.size == 1 && namespace.first.is_a?(Symbol)
      namespace(namespace.first) { instance_eval(&block) } if block_given?
        self.reset_routes! if reload?
    end
  end

  class Application
    extend Padrino::ControllerNamespacing
    class << self
      alias_method_chain :controllers, :namespaces
    end
  end if defined?(Padrino::Application)
end
