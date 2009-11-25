module Padrino

  def self.run!(*args)
    Server.build(*args)
  end

  module Server
    Handlers = %w[thin mongrel webrick] unless const_defined?(:Handlers)
  private
    def self.build(host="localhost", port=3000, adapter=nil)
      handler_name = adapter ? adapter.to_s.capitalize : detect_handler.name.gsub(/.*::/, '')

      begin
        handler = Rack::Handler.get(handler_name.downcase)
      rescue
        puts "#{handler_name} not supported yet, available adapters are: #{ADAPTERS.inspect}"
        exit
      end

      handler.run Padrino.application, :Host => host, :Port => port do |server|
        trap(:INT) do
          # Use thins' hard #stop! if available, otherwise just #stop
          server.respond_to?(:stop!) ? server.stop! : server.stop
          puts "<= Padrino has ended his set (crowd applauds)"
        end
      end
    rescue Errno::EADDRINUSE
      puts "=> Someone is already performing on port #{options.port}!"
    end

    def self.detect_handler
      Handlers.each do |server_name|
        begin
          return Rack::Handler.get(server_name.downcase)
        rescue LoadError
        rescue NameError
        end
      end
      fail "Server handler (#{servers.join(',')}) not found."
    end
  end
end