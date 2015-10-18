PADRINO_ROOT = File.dirname(__FILE__) unless defined? PADRINO_ROOT

class CustomDependencies < Padrino::Application
  set :reload, true
end

CustomDependencies.controllers do
  get "/" do
    "foo"
  end
end
