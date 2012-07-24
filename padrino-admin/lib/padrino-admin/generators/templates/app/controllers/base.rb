Admin.controllers :base do

  before do
    settings.breadcrumbs.reset
  end

  get :index, :map => "/" do
    render "base/index"
  end
end
