module Padrino
  module Cli
    module Adapter
      class << self
        # Start for the given options a rackup handler
        def start(options)
          if options.daemonize?
            stop # Need to stop a process if it exists
            fork do
              Process.setsid
              exit if fork
              File.umask 0000
              puts "=> Padrino server has been daemonized with pid #{Process.pid}"
              STDIN.reopen "/dev/null"
              STDOUT.reopen "/dev/null", "a"
              STDERR.reopen STDOUT

              FileUtils.mkdir_p("tmp/pids") unless File.exist?("tmp/pids")
              pid = "tmp/pids/server.pid"

              if pid
                File.open(pid, 'w'){ |f| f.write("#{Process.pid}") }
              end

              Padrino.run!(options.symbolize_keys)
              exit
            end
          else
            Padrino.run!(options.symbolize_keys)
          end
        end

        # Method that stop (if exist) a running Padrino.application
        def stop
          if File.exist?("tmp/pids/server.pid")
            pid = File.read("tmp/pids/server.pid").to_i
            print "=> Sending SIGTERM to process with pid #{pid} wait "
            Process.kill(15, pid) rescue nil
            1.step(5) { |i| sleep i; print "."; $stdout.flush }
            File.delete("tmp/pids/server.pid")
            puts " done."
          end
        end
      end # self
    end # Adapter
  end # Cli
end # Padrino