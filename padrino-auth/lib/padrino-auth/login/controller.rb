module Padrino
  module Login
    module Controller
      def self.included(base)
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
