module Padrino
  class Mounter
    module ApplicationExtension
      attr_accessor :uri_root, :mounter_options, :cascade
      attr_writer :public_folder

      def dependencies
        @__dependencies ||= Dir.glob("#{root}/**/*.rb").delete_if { |path| path == app_file }
      end

      def prerequisites
        @__prerequisites ||= []
      end

      def app_file
        @__app_file ||= trace_method(:app_file) { mounter_options[:app_file] }
      end

      def root
        @__root ||= trace_method(:root) { File.expand_path("#{app_file}/../") }
      end

      def public_folder
        @public_folder ||= trace_method(:public_folder) { "" }
      end

      def app_name
        @__app_name ||= mounter_options[:app_name] || self.to_s.underscore.to_sym
      end

      def setup_application!
        @configured ||= trace_method(:setup_application!) do
          $LOAD_PATH.concat(prerequisites)
          require_dependencies if root.start_with?(Padrino.root)
          true
        end
      end

      private

      def require_dependencies
        Padrino.require_dependencies(dependencies, :force => true)
      end

      def trace_method(method_name)
        value = baseclass.send(method_name) if baseclass != self && baseclass.respond_to?(method_name)
        value || yield
      end

      def baseclass
        @__baseclass ||= respond_to?(:superclass) ? superclass : self
      end
    end
  end
end
