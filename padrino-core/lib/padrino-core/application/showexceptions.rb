module Padrino
  ##
  # This module extend Sinatra::ShowExceptions adding Padrino as "Framework"
  #
  class ShowExceptions < Sinatra::ShowExceptions

    def call(env)
      @app.call(env)
    rescue Exception => e
      errors, env["rack.errors"] = env["rack.errors"], @@eats_errors

      if respond_to?(:prefers_plain_text?) and prefers_plain_text?(env)
        content_type = "text/plain"
        body = [dump_exception(e)]
      else
        content_type = "text/html"
        body = pretty(env, e)
      end

      env["rack.errors"] = errors

      [500,
       {"Content-Type" => content_type,
        "Content-Length" => Rack::Utils.bytesize(body.join).to_s},
       body]
    end

    private
      def frame_class(frame)
        if frame.filename =~ /lib\/sinatra.*\.rb|lib\/padrino.*\.rb/
          "framework"
        elsif (defined?(Gem) && frame.filename.include?(Gem.dir)) ||
              frame.filename =~ /\/bin\/(\w+)$/ ||
              frame.filename =~ /Ruby\/Gems/
          "system"
        else
          "app"
        end
      end
  end # ShowExceptions
end # Padrino