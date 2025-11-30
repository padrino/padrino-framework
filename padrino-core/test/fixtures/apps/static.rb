PADRINO_ROOT = __dir__ unless defined? PADRINO_ROOT

class StaticDemo < Padrino::Application
  disable :reload
  def self.reload!
    raise 'reload! called'
  end
end

Padrino.load!
