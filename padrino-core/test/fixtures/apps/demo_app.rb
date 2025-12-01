PADRINO_ROOT = __dir__ unless defined? PADRINO_ROOT

module Demo
  class App < Padrino::Application
    set :reload, true
  end
end
