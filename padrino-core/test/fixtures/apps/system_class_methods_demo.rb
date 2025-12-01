PADRINO_ROOT = __dir__ unless defined? PADRINO_ROOT

class SystemClassMethodsDemo < Padrino::Application
  set :reload, true
end

Padrino.load!
