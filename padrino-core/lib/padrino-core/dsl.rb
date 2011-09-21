##
# Act like sinatra, you are be able to
# create dsl apps also with padrino.
#
# @example Create your app
#   require 'rubygems'
#   require 'padrino-core/autorun' # Auto create webserver
#   require 'padrino-core/dsl'
#
#   get :index do
#     'Hello world'
#   end
#
# @example Start your app
#   ruby your_app.rb
#
class DSLApp < Padrino::Application; end
Sinatra::Delegator.target = DSLApp

include Sinatra::Delegator
