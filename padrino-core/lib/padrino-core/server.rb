module Padrino
  ##
  # Runs the Padrino apps as a self-hosted server using:
  # thin, mongrel, or webrick in that order.
  #
  # @example
  #   Padrino.run! # with these defaults => host: "localhost", port: "3000", adapter: the first found
  #   Padrino.run!("localhost", "4000", "mongrel") # use => host: "0.0.0.0", port: "3000", adapter: "mongrel"
  #
  def self.run!(options={})
    print 'Preloading Padrino ... '
    Padrino.preload!
    puts 'DONE!'

    loop do
      @int       = false
      @first_run = true
      @pid       = fork do
        puts '>> Load application dependencies ... '
        Padrino.load!
        Server.start(Padrino.application, options)
      end
      @mtimes  ||= {}

      puts '>> Spawn a new processes with PID: %d' % @pid

      trap :HUP do
        puts ">> Performing restart"
        Process.kill(:INT, @pid)
        @int = true
      end

      %w[INT KILL QUIT TERM].each do |signal|
        trap(signal) do
          if @restart
            @restart = false
          else
            abort '<= Padrino has ended has left the guns (crowd applauds)'
          end
        end
      end

      until @int do
        Dir[Padrino.root("**/*.rb")].sort.each do |file|
          if !@mtimes.has_key?(file)
            logger.debug "Detected a new file: #{file}"
            Process.kill(:HUP, Process.pid)
            @restart = true
          elsif @mtimes[file] < File.mtime(file)
            logger.debug "Detected modified file #{file}"
            Process.kill(:HUP, Process.pid)
            @restart = true
          end unless @first_run
          @mtimes[file] = File.mtime(file)
        end

        @first_run = false
        sleep 0.2
      end

      Process.waitpid(@pid)
    end
  end

  ##
  # This module builds a Padrino server to run the project based on available handlers.
  #
  class Server < Rack::Server
    # Server Handlers
    Handlers = [:thin, :mongrel, :webrick]

    # Starts the application on the available server with specified options.
    def self.start(app, opts={})
      options = {}.merge(opts) # We use a standard hash instead of Thor::CoreExt::HashWithIndifferentAccess
      options.symbolize_keys!
      options[:Host] = options.delete(:host) || '0.0.0.0'
      options[:Port] = options.delete(:port) || 3000
      options[:AccessLog] = []
      if options[:daemonize]
        options[:pid] = options[:pid].blank? ? File.expand_path('tmp/pids/server.pid') : opts[:pid]
        FileUtils.mkdir_p(File.dirname(options[:pid]))
      end
      options[:server] = detect_rack_handler if options[:server].blank?
      new(options, app).start
    end

    def initialize(options, app)
      @options, @app = options, app
    end

    # Starts the application on the available server with specified options.
    def start
      puts "=> Padrino/#{Padrino.version} has taken the stage #{Padrino.env} at http://#{options[:Host]}:#{options[:Port]}"
      [:INT, :TERM].each { |sig| trap(sig) { exit } }
      super
    ensure
      puts "<= Padrino has ended his set (crowd applauds)" unless options[:daemonize]
    end

    # The application the server will run.
    def app
      @app
    end
    alias :wrapped_app :app

    # The options specified to the server.
    def options
      @options
    end

    private
    # Detects the supported handler to use.
    #
    # @example
    #   detect_rack_handler => <ThinHandler>
    #
    def self.detect_rack_handler
      Handlers.each do |handler|
        begin
          return handler if Rack::Handler.get(handler.to_s.downcase)
        rescue LoadError
        rescue NameError
        end
      end
      fail "Server handler (#{Handlers.join(', ')}) not found."
    end
  end # Server
end # Padrino
