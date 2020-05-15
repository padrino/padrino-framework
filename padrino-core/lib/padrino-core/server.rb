module Padrino
  ##
  # Runs the Padrino apps as a self-hosted server using:
  # thin, mongrel, or WEBrick in that order.
  #
  # @example
  #   Padrino.run! # with these defaults => host: "127.0.0.1", port: "3000", adapter: the first found
  #   Padrino.run!("0.0.0.0", "4000", "mongrel") # use => host: "0.0.0.0", port: "4000", adapter: "mongrel"
  #
  def self.run!(options={})
    Padrino.load!
    Server.start(*detect_application(options))
  end

  private

  #
  #
  def self.detect_application(options)
    default_config_file = 'config.ru'
    if (config_file = options.delete(:config)) || File.file?(default_config_file)
      config_file ||= default_config_file
      fail "Rack config file `#{config_file}` must have `.ru` extension" unless config_file =~ /\.ru$/
      rack_app, rack_options = Rack::Builder.parse_file(config_file)
      [rack_app, rack_options.merge(options)]
    else
      [Padrino.application, options]
    end
  end

  ##
  # This module builds a Padrino server to run the project based on available handlers.
  #
  class Server < Rack::Server
    DEFAULT_ADDRESS = { :Host => '127.0.0.1', :Port => 3000 }

    # Server Handlers
    Handlers = [:thin, :puma, :'spider-gazelle', :mongrel, :trinidad, :webrick]

    # Starts the application on the available server with specified options.
    def self.start(app, options={})
      options = Utils.symbolize_keys(options.to_hash)
      options.update(parse_server_options(options.delete(:options)))
      options.update(detect_address(options))
      options[:pid] = prepare_pid(options[:pid]) if options[:daemonize]
      options[:server] ||= detect_rack_handler
      # disable Webrick AccessLog
      options[:AccessLog] = []
      new(options, app).start
    end

    def initialize(options, app)
      @options, @app = options, app
    end

    # Starts the application on the available server with specified options.
    def start
      puts "=> Padrino/#{Padrino.version} has taken the stage #{Padrino.env} at http://#{options[:Host]}:#{options[:Port]}"
      [:INT, :TERM].each { |sig| trap(sig) { exit } }
      super do |server|
        server.threaded = true if server.respond_to?(:threaded=)
      end
    ensure
      puts "<= Padrino leaves the gun, takes the cannoli" unless options[:daemonize]
    end

    # The application the server will run.
    def app
      @app
    end
    alias :wrapped_app :app

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

    # Prepares a directory for pid file.
    #
    def self.prepare_pid(pid)
      pid ||= 'tmp/pids/server.pid'
      FileUtils.mkdir_p(File.dirname(pid))
      File.expand_path(pid)
    end

    # Parses an array of server options.
    #
    def self.parse_server_options(options)
      parsed_server_options = Array(options).flat_map{ |option| option.split('=', 2) }
      Utils.symbolize_keys(Hash[*parsed_server_options])
    end

    # Detects Host and Port for Rack server.
    #
    def self.detect_address(options)
      address = DEFAULT_ADDRESS.merge options.select{ |key| [:Host, :Port].include?(key) }
      address[:Host] = options[:host] if options[:host]
      address[:Port] = options[:port] if options[:port]
      address
    end
  end
end
