require 'sinatra/base'

##
# Adds to Sinatra +controller+ informations
#
class Sinatra::Request
  attr_accessor :route_obj

  def controller
    route_obj && route_obj.controller
  end
  def action
    route_obj && route_obj.action
  end
end

##
# This patches Sinatra to accept UTF-8 urls on JRuby 1.7.6
#
if RUBY_ENGINE == 'jruby' && defined?(JRUBY_VERSION) && JRUBY_VERSION > '1.7.4'
  class Sinatra::Base
    class << self
      alias_method :old_generate_method, :generate_method
      def generate_method(method_name, &block)
        old_generate_method(method_name.to_sym, &block)
      end
    end
  end
end
