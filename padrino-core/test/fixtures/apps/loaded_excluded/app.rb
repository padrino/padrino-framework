PADRINO_ROOT = __dir__ unless defined? PADRINO_ROOT

class SystemLoadedExcludedDemo < Padrino::Application
  set :reload, true
end

Padrino.load!
