PADRINO_ROOT = File.dirname(__FILE__) unless defined? PADRINO_ROOT

class SystemConcernedClassDemo < Padrino::Application
  set :reload, true
end
