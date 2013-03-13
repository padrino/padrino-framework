module Rack
  module Protection
    class Base
      DEFAULT_OPTIONS[:report_key] = "protection.failed"

      def report(env)
        env[options[:report_key]] = true
      end
    end
  end
end