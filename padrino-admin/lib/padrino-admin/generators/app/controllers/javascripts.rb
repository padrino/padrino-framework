Admin.controllers :javascripts do

  get :admin, :respond_to => :js do
    render 'javascripts/admin.js'
  end

  get :locale, :respond_to => :js do
    render 'javascripts/locale.js'
  end
end