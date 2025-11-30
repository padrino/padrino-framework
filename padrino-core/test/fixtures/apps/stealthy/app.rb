PADRINO_ROOT = __dir__ unless defined? PADRINO_ROOT

class SystemStealthyClassDemo < Padrino::Application
  set :reload, true
end

Padrino.load!
