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
