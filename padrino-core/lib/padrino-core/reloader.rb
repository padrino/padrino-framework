module Padrino
  ##
  # High performant source reloader
  #
  # This class acts as Rack middleware.
  #
  # It is performing a check/reload cycle at the start of every request, but
  # also respects a cool down time, during which nothing will be done.
  # 
  class Reloader

    def initialize(app, cooldown = 1)
      @app = app
      @cooldown = cooldown
      @last = (Time.now - cooldown)
    end

    def call(env)
      if @cooldown and Time.now > @last + @cooldown
        if Thread.list.size > 1
          Thread.exclusive { Padrino.reload! }
        else
          Padrino.reload!
        end

        @last = Time.now
      end

      @app.call(env)
    end
  end # Reloader
end # Padrino

