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
      server = ::Thin::Server.new(app, host, port)
      server.silent = true
      server.start
    rescue Errno::EADDRINUSE
      puts "=> Someone is already performing on port #{port}!"
    end
  end # Server
end # Padrino