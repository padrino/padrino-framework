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
    Server.build(options)
  end

  ##
  # This module build a Padrino server
  #
  module Server

    class LoadError < RuntimeError; end

    Handlers = %w[thin mongrel webrick] unless const_defined?(:Handlers)

    private
      def self.build(options={})
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

        puts "=> Padrino/#{Padrino.version} has taken the stage #{Padrino.env} on #{port}"

        handler.run Padrino.application, :Host => host, :Port => port do |server|
          trap(:INT) do
            # Use thins' hard #stop! if available, otherwise just #stop
            server.respond_to?(:stop!) ? server.stop! : server.stop
            puts "<= Padrino has ended his set (crowd applauds)"
          end
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
