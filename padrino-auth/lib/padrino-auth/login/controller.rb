module Padrino
  module Login
    module Controller
      def self.included(base)
        Padrino.after_load do
          base.set_access(:*, :allow => :*, :with => :login) if base.respond_to?(:set_access)
        end
        base.get :index do
          render :slim, :"new", :layout => "layout", :views => File.dirname(__FILE__)
        end
        base.post :index do
          if authenticate
            restore_location
          else
            params.delete 'password'
            flash.now[:error] = 'Wrong password'
            render :slim, :"new", :layout => "layout", :views => File.dirname(__FILE__)
          end
        end
      end
    end
  end
end
