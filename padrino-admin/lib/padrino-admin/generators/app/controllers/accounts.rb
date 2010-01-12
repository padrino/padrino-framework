Admin.controllers :accounts do

  get :index, :respond_to => [:js, :json] do
    @store = Account.column_store(options.views, "accounts/store")
    case content_type
      when :js    then render 'accounts/grid.js'
      when :json  then @store.store_data(params)
    end
  end

  get :new do
    @account = Account.new
    render 'accounts/new'
  end

  post :create, :respond_to => :js do
    @account = Account.create(params[:account])
    show_messages_for(@account)
  end

  get :edit, :with => :id do
    @account = Account.first(:conditions => { :id => params[:id] })
    render 'accounts/edit'
  end

  put :update, :with => :id, :respond_to => :js do
    @account = Account.first(:conditions => { :id => params[:id] })
    @account.update_attributes(params[:account])
    show_messages_for(@account)
  end

  delete :destroy, :respond_to => :json do
    accounts = Account.all(:conditions => { :id => params[:ids].split(",") })
    errors   = accounts.map { |account| I18n.t("admin.general.cantDelete", :record => account.id) unless account.destroy }.compact
    { :success => errors.empty?, :msg => errors.join("<br />") }.to_json
  end
end