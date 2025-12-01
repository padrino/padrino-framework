require_relative '../external/app/app'

module ReloadableApp
  class Main < Padrino::Application
    set :reload, true
    get :index do
      'hey'
    end
  end
end
