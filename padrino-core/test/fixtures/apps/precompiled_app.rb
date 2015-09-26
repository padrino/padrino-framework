PADRINO_ROOT = File.dirname(__FILE__) unless defined? PADRINO_ROOT

Padrino.configure_apps do
  set :precompile_routes, true
end

module PrecompiledApp
  class App < Padrino::Application
    10.times{|n| get("/#{n}"){} }
  end
  class SubApp < Padrino::Application
    10.times{|n| get("/#{n}"){} }
  end
end

Padrino.mount("PrecompiledApp::SubApp").to("/subapp")
Padrino.mount("PrecompiledApp::App").to("/")

Padrino.load!
