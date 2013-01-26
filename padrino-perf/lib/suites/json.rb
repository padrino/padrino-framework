module PadrinoPerf
  module JSON
    def self.registered_libs
      @registered_libs ||= {}
    end

    def self.loaded_libs
      @loaded_libs ||= {}
    end

    def self.setup_capture!(lib)
      suite_path = File.dirname(__FILE__)
      registered_libs[lib] = File.join(suite_path, lib)
      $LOAD_PATH.unshift registered_libs[lib]
    end

    def self.setup_captures!(*libs)
      libs.map { |l| setup_capture!(l) }
    end

    def self.loaded_lib!(lib)
      #remove our shim from the load_path before requiring again
      $LOAD_PATH.delete(registered_libs[lib])
      require lib

      loaded_libs[lib] = caller

      if loaded_libs.size >= 2
        warn <<-WARN
Concurring json libraries have been loaded. This incurs an
unneccessary memory overhead at should be avoided. Consult the
following call stacks to see who loaded the offending libraries
and contact the authors if necessary:"
WARN
        loaded_libs.each do |name, stack|
          $stderr.puts "============"
          $stderr.puts "libname: " + name
          $stderr.puts "============"
          $stderr.puts caller
        end
      end
    end

    def self.infect_load_path!
      def $LOAD_PATH.unshift(arg = nil, recurse = true)
        return super(arg) unless recurse
        return self unless arg
        mine = self.grep(/padrino-perf/)
        mine.each { |m| self.delete(m) }
        super(arg)
        mine.each { |m| self.unshift(m, false) }
      end
    end

    infect_load_path!
    setup_captures!("json", "yajl")
  end
end