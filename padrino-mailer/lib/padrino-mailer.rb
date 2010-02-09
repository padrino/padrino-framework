require 'tilt'
require 'padrino-core/support_lite'

Dir[File.dirname(__FILE__) + '/padrino-mailer/**/*.rb'].each { |file| require file }

module Padrino
  module Mailer
    ##
    # Used Padrino::Application for register Padrino::Mailer::Base::views_path
    # 
    def self.registered(app)
      Padrino::Mailer::Base::views_path = app.views
    end
  end  
end