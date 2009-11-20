module Padrino
  module Tasks
    module Adapter

      class << self

        ADAPTERS = %w[thin mongrel webrick]

        # Start for the given options a rackup handler
        def start(options)

          ENV["PADRINO_ENV"] = options.environment.to_s

          boot = options.chdir ? File.join(options.chdir, options.boot) : options.boot
          unless File.exist?(boot)
            puts "=> Could not find boot file: #{boot.inspect} !!!"
            exit
          end
          require boot

          puts "=> Padrino/#{Padrino.version} has taken the stage #{options.environment} on port #{options.port}"

          if options.daemonize?
            unless fork
              puts "=> Daemonized mode is not supported on your platform." 
              exit 
            end

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
                at_exit { File.delete(pid) if File.exist?(pid) }
              end

              run_app(options)

            end
          else
            run_app(options)
          end
        end

        # Method that run the Padrino.application
        def run_app(options)

          handler_name = options.adapter.to_s.capitalize

          begin
            handler = Rack::Handler.get(handler_name.downcase)
          rescue
            puts "#{handler_name} not supported yet, available adapters are: #{ADAPTERS.inspect}"
            exit
          end
          
          handler.run Padrino.application, :Host => options.host, :Port => options.port do |server|
            trap(:INT) do
              # Use thins' hard #stop! if available, otherwise just #stop
              server.respond_to?(:stop!) ? server.stop! : server.stop
              puts "<= Padrino has ended his set (crowd applauds)"
            end
          end
        rescue Errno::EADDRINUSE
          puts "=> Someone is already performing on port #{options.port}!"
        end

        # Method that stop (if exist) a running Padrino.application
        def stop
          if File.exist?("tmp/pids/server.pid")
            pid = File.read("tmp/pids/server.pid").to_i
            print "=> Sending SIGTERM to process with pid #{pid} wait "
            Process.kill(15, pid) rescue nil
            1.step(5) { |i| sleep i; print "."; $stdout.flush }
            puts " done."
          end
        end

      end
    end
  end
end