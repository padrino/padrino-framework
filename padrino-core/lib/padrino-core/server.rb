module Padrino
  ##
  # Run the Padrino apps as a self-hosted server using:
  # thin, mongrel, webrick in that order.
  #
  # ==== Examples
  #
  #   Padrino.run! # with these defaults => host: "localhost", port: "3000", adapter: the first found
  #   Padrino.run!("localhost", "4000", "mongrel") # use => host: "localhost", port: "3000", adapter: "mongrel"
  #
  def self.run!(options={})
    Padrino.load!
    Server.start(Padrino.application, options)
  end

  ##
  # This module build a Padrino server
  #
  module Server
    def self.start(app, options={})
      host    = options[:host] || "0.0.0.0"
      port    = options[:port] || 3000
      puts "=> Padrino/#{Padrino.version} has taken the stage #{Padrino.env} at #{host}:#{port}"
      handler_name = defined?(::Thin::Server) ? :thin : :webrick
      handler = Rack::Handler.get(handler_name.to_s)
      handler.run(app, :Host => host, :Port => port) do |server|
        [:INT, :TERM].each { |sig| trap(sig) { quit!(server, handler_name) } }
        server.silent = true if server.respond_to?(:silent)
      end
    rescue Errno::EADDRINUSE
      puts "=> Someone is already performing on port #{port}!"
    end

    def self.quit!(server, handler_name)
      # Use thins' hard #stop! if available, otherwise just #stop
      server.respond_to?(:stop!) ? server.stop! : server.stop
      puts "\n== Shutting down #{handler_name} server..." unless handler_name =~/cgi/i
    end
  end # Server
end # Padrino