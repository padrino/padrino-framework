PADRINO_ROOT = File.dirname(__FILE__) unless defined? PADRINO_ROOT

class SystemInstanceMethodsDemo < Padrino::Application
  set :reload, true
end

Padrino.load!
