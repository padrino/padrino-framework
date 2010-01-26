Admin.controllers :uploads do

  get :index, :respond_to => [:js, :json] do
    @store      = Upload.column_store(options.views, "uploads/store")
    @session_id = options.session_id
    case content_type
      when :js    then render 'uploads/grid.js'
      when :json  then @store.store_data(params)
    end
  end

  post :create do
    @upload = Upload.new
    @upload.file = params[:file]
    @upload.save
    render :success => true
  end

  delete :destroy, :respond_to => :json do
    uploads = Upload.all(:conditions => { :id => params[:ids].split(",") })
    errors = uploads.map { |upload| I18n.t("admin.general.cantDelete", :record => upload.id) unless upload.destroy }.compact
    render :success => errors.empty?, :msg => errors.join("<br />")
  end
end