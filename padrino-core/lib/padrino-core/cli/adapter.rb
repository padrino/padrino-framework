module Padrino
  module Cli
    module Adapter
      class << self
        # Start for the given options a rackup handler
        def start(options)
          Padrino.run!(options.symbolize_keys)
        end

        # Method that stop (if exist) a running Padrino.application
        def stop(options)
          options.symbolize_keys!
          if File.exist?(options[:pid])
            pid = File.read(options[:pid]).to_i
            puts "=> Sending INT to process with pid #{pid}"
            begin
              Process.kill(2, pid)
            rescue Errno::ESRCH, RangeError => error
              puts error.message
              exit
            rescue Errno::EPERM => error
              puts error.message
              abort
            end
          else
            puts "=> #{options[:pid]} not found!"
            abort
          end
        end
      end
    end
  end
end
