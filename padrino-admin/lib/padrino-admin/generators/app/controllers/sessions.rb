Admin.controllers :sessions do
  
  get :new do
    render "/sessions/new"
  end

  post :create do
    if account = Account.authenticate(params[:email], params[:password])
      set_current_account(account)
      redirect url_for(:index)
    else
      flash[:notice] = "Login or password wrong."
      redirect url_for(:sessions_new)
    end
  end

  get :destroy do
    set_current_account(nil)
    render "/sessions/new"
  end
end