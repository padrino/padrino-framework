PADRINO_ROOT = __dir__ unless defined? PADRINO_ROOT

class SystemInstanceMethodsDemo < Padrino::Application
  set :reload, true
end

Padrino.load!
