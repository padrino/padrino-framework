PADRINO_ROOT = File.dirname(__FILE__) unless defined? PADRINO_ROOT

module PrecompiledApp
  class App < Padrino::Application
    set :precompile_routes, true
    10.times{|n| get("/#{n}"){} }
  end
end
