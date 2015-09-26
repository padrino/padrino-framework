module Padrino
  module Performance
    module JSON
      module InfectedRequire
        def require(*args)
          lib = args.first
          JSON.loaded_lib!(lib) if JSON.registered_libs.include? lib
          super
        end
      end # InfectedRequire

      def self.registered_libs
        @registered_libs ||= []
      end

      def self.loaded_libs
        @loaded_libs ||= {}
      end

      def self.setup_captures!(*libs)
        @registered_libs = libs
      end

      def self.loaded_lib!(lib)
        loaded_libs[lib] = caller

        if loaded_libs.size >= 2
          warn <<-WARN
Concurring json libraries have been loaded. This incurs an
unneccessary memory overhead at should be avoided. Consult the
following call stacks to see who loaded the offending libraries
and contact the authors if necessary:"
WARN
          loaded_libs.each do |name, stack|
            $stderr.puts "=================="
            $stderr.puts "libname: " + name
            $stderr.puts "=================="
            $stderr.puts caller
          end
        end
      end

      def self.infect_require!
        Object.send(:include, InfectedRequire)
      end

      infect_require!
      setup_captures!("json", "json_pure", "yajl-ruby", "oj", "crack")
    end # JSON
  # Performance
  end
  # Padrino
end
