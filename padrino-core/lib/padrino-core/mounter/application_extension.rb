module Padrino
  class Mounter
    module ApplicationExtension
      attr_accessor :uri_root, :mounter_options
      attr_writer :public_folder

      def dependencies
        @__dependencies ||= Dir["#{root}/**/*.rb"]
      end

      def prerequisites
        @__prerequisites ||= []
      end

      def app_file
        return @__app_file if @__app_file
        @__app_file = trace_method(:app_file) { |app_file| app_file || mounter_options[:app_file] }
      end

      def root
        return @__root if @__root
        @__root = trace_method(:root) { |root| root || File.expand_path("#{app_file}/../")  }
      end

      def public_folder
        return @public_folder if @public_folder
        @public_folder = trace_method(:public_folder) { |public_folder| public_folder || ""  }
      end

      def app_name
        @__app_name ||= mounter_options[:app_name] || self.to_s.underscore.to_sym
      end

      def setup_application!
        @configured ||=
          begin
            $LOAD_PATH.concat(prerequisites)
            Padrino.require_dependencies(dependencies, :force => true) if root.start_with?(Padrino.root)
            true
          end
      end

      private

      def trace_method(method_name, &block)
        value = (baseclass == self || !baseclass.respond_to?(method_name)) ? nil : baseclass.send(method_name)
        block.call(value)
      end

      def baseclass
        @__baseclass ||= respond_to?(:superclass) ? superclass : self
      end
    end
  end
end
