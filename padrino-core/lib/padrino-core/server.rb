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

    class LoadError < RuntimeError; end

    Handlers = %w[thin mongrel webrick] unless const_defined?(:Handlers)

    def self.start(app, options={})
      host    = options[:host] || "localhost"
      port    = options[:port] || 3000
      adapter = options[:adapter]

      handler_name = adapter ? adapter.to_s.capitalize : detect_handler.name.gsub(/.*::/, '')

      begin
        handler = Rack::Handler.get(handler_name.downcase)
      rescue
        raise LoadError, "#{handler_name} not supported yet, available adapters are: #{Handlers.inspect}"
        exit
      end

      puts "=> Padrino/#{Padrino.version} has taken the stage #{Padrino.env} on #{port} with #{handler_name}"

      handler.run(app, :Host => host, :Port => port) do |server|
        server.silent = true if server.respond_to?(:silent)
      end
    rescue RuntimeError => e
      if e.message =~ /no acceptor/
        if port < 1024 && RUBY_PLATFORM !~ /mswin|win|mingw/ && Process.uid != 0
          puts "=> Only root may open a priviledged port #{port}!"
        else
          puts "=> Someone is already performing on port #{port}!"
        end
      else
        raise e
      end
    rescue Errno::EADDRINUSE
      puts "=> Someone is already performing on port #{port}!"
    end

    private
      def self.detect_handler
        Handlers.each do |server_name|
          begin
            return Rack::Handler.get(server_name.downcase)
          rescue Exception
          end
        end
        raise LoadError, "Server handler (#{servers.join(',')}) not found."
      end
  end # Server
end # Padrino