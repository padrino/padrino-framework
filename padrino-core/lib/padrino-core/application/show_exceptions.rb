module Padrino
  ##
  # This module extend Sinatra::ShowExceptions adding Padrino as "Framework".
  #
  # @private
  class ShowExceptions < Sinatra::ShowExceptions
    if Sinatra::VERSION <= '1.4.5'
      def call(env)
        @app.call(env)
      rescue Exception => e
        errors, env["rack.errors"] = env["rack.errors"], @@eats_errors

        if prefers_plain_text?(env)
          content_type = "text/plain"
          exception_string = dump_exception(e)
        else
          content_type = "text/html"
          exception_string = pretty(env, e)
        end

        env["rack.errors"] = errors

        # Post 893a2c50 in rack/rack, the #pretty method above, implemented in
        # Rack::ShowExceptions, returns a String instead of an array.
        body = Array(exception_string)

        [
          500,
         {"Content-Type" => content_type,
          "Content-Length" => Rack::Utils.bytesize(body.join).to_s},
         body
        ]
      end
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
  end
end
