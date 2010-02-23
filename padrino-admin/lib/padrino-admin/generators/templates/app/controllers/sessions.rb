Admin.controllers :sessions do

  get :new do
    render "/sessions/new", nil, :layout => false
  end

  post :create do
    if account = Account.authenticate(params[:email], params[:password])
      set_current_account(account)
      redirect url(:base_index)
    else
      flash[:warning] = "Login or password wrong."
      redirect url(:sessions_new)
    end
  end

  get :destroy do
    set_current_account(nil)
    redirect url(:sessions_new)
  end
end